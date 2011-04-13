use MooseX::Declare;
use Method::Signatures::Modifiers;


class Foo
{
    method test_before   (Num $num) {}
    method test_around   (Num $num) {}
    method test_after    (Num $num) {}
    method test_override (Num $num) {}
    method test_augment  (Num $num) { inner($num); }
}

# Obviously, it's not a very good idea to change the parameter types for before, after, or augment
# modifiers.  (Changing the parameter type for around is okay, and changing it for override is more
# of an academic/philosophical point.)  However, doing this allows us to test that MXMS is being
# replaced by MSM by looking at the error messages.
class Foo::Bar extends Foo
{
    before test_before (Int $num) {}

    around test_around (Int $num)
    {
        $self->$orig($num / 2);
    }

    after test_after (Int $num) {}

    after test_override (Int $num)
    {
        return super;
    }

    augment test_augment (Int $num) {}
}


1;
