# package for t/override_modifier_errors.t

package OverrideModifierErrors;
use base qw< Method::Signatures::Modifiers >;


sub required_arg
{
    my ($class, $var) = @_;

    $class->signature_error("override missing");
}


sub named_param_error
{
    my ($class, $args) = @_;

    $class->signature_error("override extra");
}


sub type_error
{
    my ($class, $type, $value, $name) = @_;

    $class->signature_error("override badtype");
}


1;



use MooseX::Declare;
use OverrideModifierErrors;

class NewErrorClass
{
    method fee () {}
    method fie () {}
    method foe () {}

    method biff (    $bar) {}
    method bamm (   :$bar) {}
    method boom (Int $bar) {}
}

class NewErrorSubclass extends NewErrorClass
{
    around fee (    $bar) {}
    around fie (   :$bar) {}
    around foe (Int $bar) {}
}
