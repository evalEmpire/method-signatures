
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

    throws_ok { $foo->foo('bmoogle') } badval_error($foo, num => Num => 'bmoogle' => 'foo'), 'MXD using MS for method';
    throws_ok { $foobar->foo(.5) } badval_error($foobar, num => Int => .5 => 'foo'), 'MXD using MS for around';

}


done_testing();
