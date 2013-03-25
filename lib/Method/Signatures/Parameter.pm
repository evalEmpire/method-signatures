package Method::Signatures::Parameter;

use Mouse;
use Carp;

my $IDENTIFIER     = qr{ [^\W\d] \w*                         }x;
my $VARIABLE       = qr{ [\$\@%] $IDENTIFIER                 }x;
my $TYPENAME       = qr{ $IDENTIFIER (?: \:\: $IDENTIFIER )* }ix;

has original_code =>
  is            => 'ro',
  isa           => 'Str',
  required      => 1;

# Note: Have to preparse with regexes up to traits
#       because :, ! and ? in sigs confuse PPI
has ppi_clean_code =>
  is            => 'ro',
  isa           => 'Str',
  required      => 1;

has is_yadayada =>
  is            => 'ro',
  isa           => 'Bool',
  lazy          => 1,
  default       => sub {
      my $self = shift;

      return $self->original_code =~ m{^ \s* \Q...\E \s* $}x;
  };

has type =>
  is            => 'ro',
  isa           => 'Str',
  default       => '';
;

has is_ref_alias =>
  is            => 'ro',
  isa           => 'Bool',
  default       => 0;

has is_named =>
  is            => 'ro',
  isa           => 'Bool',
  required      => 1;

sub is_positional {
    my $self = shift;

    return !$self->is_named;
}

has variable    =>
  is            => 'ro',
  isa           => 'Str',
  default       => '';

has position    =>
  is            => 'ro',
  isa           => 'Maybe[Int]',  # XXX 0 or positive int
  trigger       => sub {
      my($self, $new_position, $old_position) = @_;

      if( $self->is_named ) {
          croak("A named parameter cannot have a position")
            if defined $new_position and length $new_position;
      }
      else {  # positional parameter
          croak("A positional parameter must have a position")
            if !(defined $new_position and length $new_position);
      }
  };

has sigil       =>
  is            => 'ro',
  isa           => 'Str',  # XXX [%$@*]
;

has variable_name =>
  is            => 'ro',
  isa           => 'Str',
;

has where =>
  is            => 'ro',
  isa           => 'HashRef[Int]',
  default       => sub { {} };

has traits =>
  is            => 'ro',
  isa           => 'HashRef[Int]',
  default       => sub { {} };

has default =>
  is            => 'ro',
  isa           => 'Maybe[Str]'
;

has default_when =>
  is            => 'ro',
  isa           => 'Str',
  default       => '';

has is_slurpy =>
  is            => 'ro',
  isa           => 'Bool',
  lazy          => 1,
  default       => sub {
      my $self = shift;

      return 0 if $self->is_ref_alias;

      return $self->sigil =~ m{ ^ [%\@] $ }x;
  };

has is_at_underscore =>
  is            => 'ro',
  isa           => 'Bool',
  lazy          => 1,
  default       => sub {
      my $self = shift;

      return $self->variable eq '@_';
  };

has required_flag =>
  is            => 'ro',
  isa           => 'Str',
  default       => '';

has is_required =>
  is            => 'ro',
  isa           => 'Bool',
;

sub is_optional {
    my $self = shift;

    return !$self->is_required;
}

sub BUILD {
    my $self = shift;

    $self->_preparse_original_code_for_ppi;
    $self->_parse_with_ppi;
    $self->_init_is_required;
    $self->_init_split_variable;

    return;
}


sub _init_is_required {
    my $self = shift;

    $self->is_required( $self->_determine_is_required );
}


sub _determine_is_required {
    my $self = shift;

    return 1 if $self->required_flag eq '!';

    return 0 if $self->required_flag eq '?';
    return 0 if $self->has_default;
    return 0 if $self->is_named;
    return 0 if $self->is_slurpy;

    return 1;
}


sub has_default {
    my $self = shift;

    return defined $self->default;
}

sub _parse_with_ppi {
    my $self = shift;

    # Nothing to parse.
    return if !$self->ppi_clean_code =~ /\S/;

    # Replace parameter var so as not to confuse PPI...
    $self->ppi_clean_code($self->variable. " " .$self->ppi_clean_code);

    # Tokenize...
    my $components = new_ppi_doc(\$self->ppi_clean_code);
    my $statement = $components->find_first("PPI::Statement")
      or sig_parsing_error("Could not understand parameter specification: $param");
    my $tokens = [ $statement->children ];

    # Re-remove parameter var
    shift @$tokens;

    # Extract any 'where' contraints...
    while (extract_leading(qr{^ where $}x, $tokens)) {
        sig_parsing_error("'where' constraint only available under Perl 5.10 or later. Error")
          if $] < 5.010;
        $self->where->{ extract_until(qr{^ (?: where | is | = | //= ) $}x, $tokens) }++;
    }

    # Extract parameter traits...
    while (extract_leading(qr{^ is $}x, $tokens)) {
        $self->traits->{ extract_leading(qr{^ \S+ $}x, $tokens) }++;
    }

    # Extract normal default specifier (if any)...
    if (extract_leading(qr{^ = $}x, $tokens)) {
        $self->default( extract_until(qr{^ when $}x, $tokens) );

        # Extract 'when' modifier (if any)...
        if (extract_leading(qr{^ when $}x, $tokens)) {
            sig_parsing_error("'when' modifier on default only available under Perl 5.10 or later. Error")
              if $] < 5.010;
            $self->default_when( join(q{}, @$tokens) );
            $tokens = [];
        }
    }

    # Otherwise, extract undef-default specifier (if any)...
    elsif (extract_leading(qr{^ //= $}x, $tokens)) {
        sig_parsing_error("'//=' defaults only available under Perl 5.10 or later. Error")
          if $] < 5.010;
        $self->default_when('undef');
        $self->default( join(q{}, @$tokens) );
        $tokens = [];
    }

    # Anything left over is an error...
    elsif (my $trailing = extract_leading(qr{ \S }x, $tokens)) {
        sig_parsing_error("Unexpected extra code after parameter specification: '",
                          $trailing . join(q{}, @$tokens), "'"
                      );
    }

    return;
}

sub _preparse_original_code_for_ppi {
    my $self = shift;

    my $original_code = $self->original_code;

    $self->type($1) if $original_code =~ s{^ ($TYPESPEC) \s+ }{}ox;

    # Extract ref-alias & named-arg markers, param var, and required/optional marker...
    $original_code =~ s{ ^ \s* ([\\:]*) \s* ($VARIABLE) \s* ([!?]?) }{}ox
        or sig_parsing_error("Could not understand parameter specification: $original_code");
    my ($premod, $var, $postmod) = ($1, $2, $3);

    $self->is_ref_alias ($premod =~ m{ \\ }x);
    $self->is_named     ($premod =~ m{ :  }x);
    $self->required_flag($postmod) if $postmod;

    $self->variable($var)             if $var;

    $self->ppi_clean_code($original_code);

    return;
}


sub _init_split_variable {
    my $self = shift;

    $self->variable =~ /^(.) (.*)/x;

    $self->sigil        ($1);
    $self->variable_name($2);

    return;
}

1;
