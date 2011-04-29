
use Test::More;
use Test::Exception;

use lib 't/lib';
use GenErrorRegex qw< badval_error badtype_error >;


# This time we'll try the method where you subclass MXD and then use MSM inside your subclass.
# Then you can just your subclass instead of MXD.

# Note that this code is nearly identical to t/mxd-replace.t.  However, you can't put them in the
# same file, or else whichever one runs first will replace MXMS for the whole program, which
# invalidates the testing of the second one.  Possibly they could be combined if we shelled out to
# separate Perl instances (Test::Command is good for that sort of thing).  But I'm not sure it's
# worth dragging in the extra testing dependency (and possibly obscuring the test code) at this
# point.  If we add a third method for using MSM, that would probably make it worthwhile to do.


SKIP:
{
    eval { require MooseX::Declare } or skip "MooseX::Declare required for this test", 1;

    # have to require here or else we try to load MXD before we check for it not being there (above)
    require MS_MXD_Sub or die("can't load test module: $@");
    MS_MXD_Sub->import;

    $foo = Foo2->new;
    $foobar = Foo2::Bar->new;

    foreach ( qw< before after around override augment > )
    {
        my $method = "test_$_";
        throws_ok { $foo->$method('bmoogle') } badval_error($foo, num => Num => 'bmoogle' => $method),
                "MXD using MS for method ($_)";
        throws_ok { $foobar->$method(.5) } badval_error($foobar, num => Int => .5 => $method),
                "MXD using MSM for modifier ($_)";
    }

}


done_testing();
