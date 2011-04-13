
use Test::More;
use Test::Exception;

use lib 't/lib';
use GenErrorRegex qw< badval_error badtype_error >;


SKIP:
{
    eval { require MooseX::Declare } or skip "MooseX::Declare required for this test", 1;

    eval "use MS_MXD_Replace";
    is $@, '', 'loaded test module';

    my $foo = Foo->new;
    my $foobar = Foo::Bar->new;

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
