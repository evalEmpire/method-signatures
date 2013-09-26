package Method::Signatures::Parameter;

use Mouse;
use Carp;
use Method::Signatures::Parser;

my $IDENTIFIER     = qr{ [^\W\d] \w*                         }x;
my $VARIABLE       = qr{ [\$\@%] $IDENTIFIER                 }x;
my $TYPENAME       = qr{ $IDENTIFIER (?: \:\: $IDENTIFIER )* }x;
our $PARAMETERIZED;
    $PARAMETERIZED = do{ use re 'eval';
                         qr{ $TYPENAME (?: \[ (??{$PARAMETERIZED}) \] )?                   }x;
                     };
my $TYPESPEC       = qr{ ^ \s* $PARAMETERIZED (?: \s* \| \s* $PARAMETERIZED )* \s* }x;

has original_code =>
  is            => 'ro',
  isa           => 'Str',
  required      => 1;

# Note: Have to preparse with regexes up to traits
#       because :, ! and ? in sigs confuse PPI
has ppi_clean_code =>
  is            => 'rw',
  isa           => 'Str',
;

has is_yadayada =>
  is            => 'ro',
  isa           => 'Bool',
  lazy          => 1,
  default       => sub {
      my $self = shift;

      return $self->original_code =~ m{^ \s* \Q...\E \s* $}x;
  };

has type =>
  is            => 'rw',
  isa           => 'Str',
  default       => '';
;

has is_ref_alias =>
  is            => 'rw',
  isa           => 'Bool',
  default       => 0;

has is_named =>
  is            => 'rw',
  isa           => 'Bool',
;

sub is_positional {
    my $self = shift;

    return !$self->is_named;
}

has variable    =>
  is            => 'rw',
  isa           => 'Str',
  default       => '';

has position    =>
  is            => 'rw',
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
  is            => 'rw',
  isa           => 'Str',  # XXX [%$@*]
;

has variable_name =>
  is            => 'rw',
  isa           => 'Str',
;

has where =>
  is            => 'rw',
  isa           => 'HashRef[Int]',
  default       => sub { {} };

sub has_where {
    my $self = shift;

    return keys %{$self->where} ? 1 : 0;
}

has traits =>
  is            => 'rw',
  isa           => 'HashRef[Int]',
  default       => sub { {} };

sub has_traits {
    my $self = shift;

    return keys %{$self->traits} ? 1 : 0;
}

has default =>
  is            => 'rw',
  isa           => 'Maybe[Str]'
;

has default_when =>
  is            => 'rw',
  isa           => 'Str',

has passed_in =>
  is            => 'rw',
  isa           => 'Str',
;

has check_exists =>
  is            => 'rw',
  isa           => 'Str'
;

has is_slurpy =>
  is            => 'ro',
  isa           => 'Bool',
  lazy          => 1,
  default       => sub {
      my $self = shift;

      return 0 if $self->is_ref_alias;
      return 0 if !$self->sigil;

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
  is            => 'rw',
  isa           => 'Str',
  default       => '';

has is_required =>
  is            => 'rw',
  isa           => 'Bool',
;

sub is_optional {
    my $self = shift;

    return !$self->is_required;
}

sub BUILD {
    my $self = shift;

    return if $self->is_yadayada;

    $self->_preparse_original_code_for_ppi;
    $self->_parse_with_ppi;
    $self->_init_split_variable;
    $self->_init_is_required;

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
    return if $self->ppi_clean_code !~ /\S/;

    # Replace parameter var so as not to confuse PPI...
    $self->ppi_clean_code($self->variable. " " .$self->ppi_clean_code);

    # Tokenize...
    my $components = Method::Signatures::Parser->new_ppi_doc(\($self->ppi_clean_code));
    my $statement = $components->find_first("PPI::Statement")
      or sig_parsing_error("Could not understand parameter specification: @{[$self->ppi_clean_code]}");
    my $tokens = [ $statement->children ];

    # Re-remove parameter var
    shift @$tokens;

    # Extract any 'where' constraints...
    while ($self->_extract_leading(qr{^ where $}x, $tokens)) {
        sig_parsing_error("'where' constraint only available under Perl 5.10 or later. Error")
          if $] < 5.010;
        $self->where->{ $self->_extract_until(qr{^ (?: where | is | = | //= ) $}x, $tokens) }++;
    }

    # Extract parameter traits...
    while ($self->_extract_leading(qr{^ is $}x, $tokens)) {
        $self->traits->{ $self->_extract_leading(qr{^ \S+ $}x, $tokens) }++;
    }

    # Extract normal default specifier (if any)...
    if ($self->_extract_leading(qr{^ = $}x, $tokens)) {
        $self->default( $self->_extract_until(qr{^ when $}x, $tokens) );

        # Extract 'when' modifier (if any)...
        if ($self->_extract_leading(qr{^ when $}x, $tokens)) {
            sig_parsing_error("'when' modifier on default only available under Perl 5.10 or later. Error")
              if $] < 5.010;
            $self->default_when( join(q{}, @$tokens) );
            $tokens = [];
        }
    }

    # Otherwise, extract undef-default specifier (if any)...
    elsif ($self->_extract_leading(qr{^ //= $}x, $tokens)) {
        sig_parsing_error("'//=' defaults only available under Perl 5.10 or later. Error")
          if $] < 5.010;
        $self->default_when('undef');
        $self->default( join(q{}, @$tokens) );
        $tokens = [];
    }

    # Anything left over is an error...
    elsif (my $trailing = $self->_extract_leading(qr{ \S }x, $tokens)) {
        sig_parsing_error("Unexpected extra code after parameter specification: '",
                          $trailing . join(q{}, @$tokens), "'"
                      );
    }

    return;
}


# Remove leading whitespace + token, if token matches the specified pattern...
sub _extract_leading {
    my ($self, $selector_pat, $tokens) = @_;

    while (@$tokens && $tokens->[0]->class eq 'PPI::Token::Whitespace') {
        shift @$tokens;
    }

    return @$tokens && $tokens->[0] =~ $selector_pat
                ? "" . shift @$tokens
                : undef;
}


# Remove tokens up to (but excluding) the first that matches the delimiter...
sub _extract_until {
    my ($self, $delimiter_pat, $tokens) = @_;

    my $extracted = q{};

    while (@$tokens) {
        last if $tokens->[0] =~ $delimiter_pat;
        $extracted .= shift @$tokens;
    }

    return $extracted;
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
