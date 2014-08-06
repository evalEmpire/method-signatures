package Method::Signatures::Signature;

use Mouse;
use Method::Signatures::Types;
use Method::Signatures::Parameter;
use Method::Signatures::Utils qw(new_ppi_doc sig_parsing_error DEBUG);

my $INF = ( 0 + "inf" ) == 0 ? 9e9999 : "inf";

# The unmodified, uncleaned up original signature for reference
has signature_string =>
  is            => 'ro',
  isa           => 'Str',
  required      => 1;

# Just the parameter part of the signature, no invocant
has parameter_string =>
  is            => 'ro',
  isa           => 'Str',
  lazy          => 1,
  builder       => '_build_parameter_string';

# A list of strings for each parameter tokenized from parameter_string
has parameter_strings =>
  is            => 'ro',
  isa           => 'ArrayRef[Str]',
  lazy          => 1,
  builder       => '_build_parameter_strings';

# The parsed Method::Signature::Parameter objects
has parameters =>
  is            => 'ro',
  isa           => 'ArrayRef[Method::Signatures::Parameter]',
  default       => sub { [] };

has named_parameters =>
  is            => 'ro',
  isa           => 'ArrayRef[Method::Signatures::Parameter]',
  default       => sub { [] };

has positional_parameters =>
  is            => 'ro',
  isa           => 'ArrayRef[Method::Signatures::Parameter]',
  default       => sub { [] };

has optional_parameters =>
  is            => 'ro',
  isa           => 'ArrayRef[Method::Signatures::Parameter]',
  default       => sub { [] };

has optional_positional_parameters =>
  is            => 'ro',
  isa           => 'ArrayRef[Method::Signatures::Parameter]',
  default       => sub { [] };

has slurpy_parameters =>
  is            => 'ro',
  isa           => 'ArrayRef[Method::Signatures::Parameter]',
  default       => sub { [] };

has yadayada_parameters =>
  is            => 'ro',
  isa           => 'ArrayRef[Method::Signatures::Parameter]',
  default       => sub { [] };


sub num_named {
    return scalar @{$_[0]->named_parameters};
}

sub num_positional {
    return scalar @{$_[0]->positional_parameters};
}

sub num_optional {
    return scalar @{$_[0]->optional_parameters};
}

sub num_optional_positional {
    return scalar @{$_[0]->optional_positional_parameters};
}

sub num_slurpy {
    return scalar @{$_[0]->slurpy_parameters};
}

sub num_yadayada {
    return scalar @{$_[0]->yadayada_parameters};
}

# Anything we need to pull out before the invocant.
# Primary example would be the $orig for around modifiers in Moose/Mouse
has pre_invocant =>
  is            => 'rw',
  isa           => 'Maybe[Str]',
  default       => '';

has invocant =>
  is            => 'rw',
  isa           => 'Maybe[Str]',
  default       => '';

sub has_invocant {
    return $_[0]->invocant ? 1 : 0;
}

# How big can @_ be?
has max_argv_size =>
  is            => 'rw',
  isa           => 'Int|Inf';

# The maximum logical arguments (name => value counts as one argument)
has max_args    =>
  is            => 'rw',
  isa           => 'Int|Inf';

# A PPI::Document representing the list of parameters
has ppi_doc     =>
  is            => 'ro',
  isa           => 'PPI::Document',
  lazy          => 1,
  default       => sub {
      my $code = $_[0]->parameter_string;
      return new_ppi_doc(\$code);
  };

# If set, no checks will be done on the signature or parameters
has no_checks   =>
  is            => 'rw',
  isa           => 'Bool',
  default       => 0;


sub BUILD {
    my $self = shift;

    my $idx = 0;
    for my $proto (@{$self->parameter_strings}) {
        DEBUG( "proto: $proto\n" );

        my $sig = Method::Signatures::Parameter->new(
            original_code => $proto,
            position      => $idx,
        );
        $idx++ if $sig->is_positional;

        push @{$self->parameters}, $sig;

        # Handle "don't care" specifier
        if ($sig->is_yadayada) {
            push @{$self->slurpy_parameters}, $sig;
            push @{$self->yadayada_parameters}, $sig;
            next;
        }

        $sig->check($self) unless $self->no_checks;

        push @{$self->named_parameters}, $sig      if $sig->is_named;
        push @{$self->positional_parameters}, $sig if $sig->is_positional;
        push @{$self->optional_parameters}, $sig   if $sig->is_optional;
        push @{$self->optional_positional_parameters}, $sig
          if $sig->is_optional and $sig->is_positional;
        push @{$self->slurpy_parameters}, $sig     if $sig->is_slurpy;

        DEBUG( "sig: ", $sig );
    }

    $self->_calculate_max_args;
    $self->check unless $self->no_checks;

    return;
}


sub _calculate_max_args {
    my $self = shift;

    # If there's a slurpy argument, the max is infinity.
    if( $self->num_slurpy ) {
        $self->max_argv_size($INF);
        $self->max_args($INF);

        return;
    }

    $self->max_argv_size( ($self->num_named * 2) + $self->num_positional );
    $self->max_args( $self->num_named + $self->num_positional );

    return;
}


# Check the integrity of the signature as a whole
sub check {
    my $self = shift;

    # Check that slurpy arguments come at the end
    if(
        $self->num_slurpy                  &&
        !($self->num_yadayada || $self->positional_parameters->[-1]->is_slurpy)
    )
    {
        my $slurpy_param = $self->slurpy_parameters->[0];
        sig_parsing_error("Slurpy parameter '@{[$slurpy_param->variable]}' must come at the end");
    }

    return 1;
}


sub _strip_ws {
    $_[1] =~ s/^\s+//;
    $_[1] =~ s/\s+$//;
}


my $IDENTIFIER     = qr{ [^\W\d] \w* }x;
sub _build_parameter_string {
    my $self = shift;

    my $sig_string = $self->signature_string;
    my $invocant;

    # Extract an invocant, if one is present.
    if ($sig_string =~ s{ ^ \s* (\$ $IDENTIFIER) \s* : \s* }{}x) {
        $self->invocant($1);
    }

    # The siganture, minus the invocant, is just the list of parameters
    return $sig_string;
}


sub _build_parameter_strings {
    my $self = shift;

    my $param_string = $self->parameter_string;
    return [] unless $param_string =~ /\S/;

    local $@ = undef;

    my $ppi = $self->ppi_doc;
    $ppi->prune('PPI::Token::Comment');

    my $statement = $ppi->find_first("PPI::Statement");
    sig_parsing_error("Could not understand parameter list specification: $param_string")
        unless $statement;
    my $token = $statement->first_token;

    # Split the signature into a list of parameters.
    my @params = ('');
    do {
        if( $token->class eq "PPI::Token::Operator" and $token->content eq ',' ) {
            push @params, '';
        }
        else {
            $params[-1] .= $token->content;
        }

        # "Type: $arg" is interpreted by PPI as a label, which is lucky for us.
        $token = $token->class eq 'PPI::Token::Label'
                   ? $token->next_token : $token->next_sibling;
    } while( $token );


    $self->_strip_ws($_) for @params;

    # Remove blank entries due to trailing comma.
    @params = grep { /\S/ } @params;

    return \@params;
}


1;
