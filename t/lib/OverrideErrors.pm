# package for t/override_errors.t

package OverrideErrors;
use base qw< Method::Signatures >;


sub required_arg
{
    my ($class, $var) = @_;

    $class->signature_error("you suck!");
}


sub named_param_error
{
    my ($class, $args) = @_;

    $class->signature_error("and your mother is ugly, too");
}


1;
