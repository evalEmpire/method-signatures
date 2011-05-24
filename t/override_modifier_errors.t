#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Exception;


SKIP:
{
    eval { require MooseX::Declare } or skip "MooseX::Declare required for this test", 1;

    use_ok("OverrideModifierErrors");


    my $obj = NewErrorSubclass->new;

    throws_ok { $obj->biff( )            } qr/override missing/, 'error okay: modifier / missing / method';
    throws_ok { $obj->bamm( snork => 1 ) } qr/override extra/,   'error okay: modifier / extra / method';
    throws_ok { $obj->boom( .5 )         } qr/override badtype/, 'error okay: modifier / bad type / method';

    throws_ok { $obj->fee( )            } qr/override missing/, 'error okay: modifier / missing / around';
    throws_ok { $obj->fie( snork => 1 ) } qr/override extra/,   'error okay: modifier / extra / around';
    throws_ok { $obj->foe( .5 )         } qr/override badtype/, 'error okay: modifier / bad type / around';
}


done_testing;
