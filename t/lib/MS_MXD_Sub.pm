use My::Declare;


# Using Foo2 here just so we can insure we don't get our subclassing test crossed with our
# replacement test (which uses Foo).  Other than that, and the use statement above, note that this
# code is exactly the same as MS_MXD_Replace.pm.

class Foo2
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
class Foo2::Bar extends Foo2
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
