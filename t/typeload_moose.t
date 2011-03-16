#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Exception;


SKIP:
{
    eval "use Moose ()";
    skip "Moose required for testing Moose types", 1 if $@;

    require MooseLoadTest;

    my $foobar = Foo::Bar->new;

    # can't check for type module not being loaded here, because Moose will drag it in


    $foobar->check_int(42);

    # now we should have loaded Moose, not Mouse, to do our type checking

    is $INC{'Mouse/Util/TypeConstraints.pm'}, undef, "didn't load Mouse";
    like $INC{'Moose/Util/TypeConstraints.pm'}, qr{Moose/Util/TypeConstraints\.pm$}, 'loaded Moose';


    # tests for ScalarRef[X] have to live here, because they only work with Moose

    my $method = 'check_paramized_sref';
    lives_ok { $foobar->$method(\42) } 'call with good value for paramized_sref passes';
    throws_ok { $foobar->check_paramized_sref(\'thing') }
            qr/The 'bar' parameter \("SCALAR\(.*?\)"\) to Foo::Bar::$method is not of type ScalarRef\[Num\]/,
            'call with bad value for paramized_sref dies';
}


done_testing;
