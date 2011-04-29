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

    $class->signature_error("and yo mama's ugly, too");
}


sub type_error
{
    my ($class, $type, $value, $name) = @_;

    $class->signature_error("she got a wooden leg with a kickstand");
}


1;
