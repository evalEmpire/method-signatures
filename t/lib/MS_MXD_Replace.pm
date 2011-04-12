use MooseX::Declare;
use Method::Signatures::Modifiers;


class Foo
{
    method foo (Num $num) {}
}

class Foo::Bar extends Foo
{
    around foo (Int $num) {
        $self->$orig($num / 2);
    }
}


1;
