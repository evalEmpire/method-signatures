
package OverrideErrors;
use base qw< Method::Signatures::Modifiers >;


sub type_error
{
    my ($class, $type, $value, $name) = @_;

    $class->signature_error("you really suck, you know that?");
}


1;
