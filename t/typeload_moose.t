#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';
use GenErrorRegex qw< badval_error >;

use Test::More;
use Test::Exception;


SKIP:
{
    eval { require Moose } or skip "Moose required for testing Moose types", 1;

    require MooseLoadTest;

    my $foobar = Foo::Bar->new;

    # can't check for type module not being loaded here, because Moose will drag it in


    $foobar->check_int(42);

    # now we should have loaded Moose to do our type checking

    like $INC{'Moose/Util/TypeConstraints.pm'}, qr{Moose/Util/TypeConstraints\.pm$}, 'loaded Moose';


    # tests for ScalarRef[X] have to live here, because they only work with Moose

    my $method = 'check_paramized_sref';
    my $bad_ref = \'thing';
    lives_ok { $foobar->$method(\42) } 'call with good value for paramized_sref passes';
    throws_ok { $foobar->$method($bad_ref) }
            badval_error($foobar, bar => 'ScalarRef[Num]' => $bad_ref, $method),
            'call with bad value for paramized_sref dies';
}


done_testing;
