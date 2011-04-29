#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Exception;


use OverrideErrors;

func biff (    $bar) {}
func bamm (   :$bar) {}
func boom (Int $bar) {}

throws_ok { biff( )            } qr/you suck!/,                             'required param missing from overridden errors';
throws_ok { bamm( snork => 1 ) } qr/and yo mama's ugly, too/,               'no such named param from overridden errors';
throws_ok { boom( .5 )         } qr/she got a wooden leg with a kickstand/, 'value of wrong type from overridden errors';

# make sure our subclass is getting skipped properly
throws_ok { biff() } qr/^In call to main::biff.*$0 line/, 'subclassing reports errors from proper place';


done_testing;
