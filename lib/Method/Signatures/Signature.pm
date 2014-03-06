package Method::Signatures::Signature;

use Mouse;
use Method::Signatures::Types;

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
  isa           => 'ArrayRef',
  default       => sub { [] };

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
  isa           => 'Str',
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


my $IDENTIFIER     = qr{ [^\W\d] \w* }x;
sub _build_parameter_string {
    my $self = shift;

    my $sig_string = $self->signature_string;
    my $invocant;

    # Extract an invocant, if one is present.
    if ($sig_string =~ s{ ^ (\$ $IDENTIFIER) \s* : \s* }{}x) {
        $self->invocant($1);
    }

    # The siganture, minus the invocant, is just the list of parameters
    return $sig_string;
}


1;
