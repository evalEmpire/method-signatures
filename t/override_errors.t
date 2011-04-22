#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Exception;


use OverrideErrors;

func foo  ( $bar) {}
func fizz (:$bar) {}

throws_ok { foo()                } qr/you suck!/,                    'required param missing from overridden errors';
throws_ok { fizz( bmoogle => 1 ) } qr/and your mother is ugly, too/, 'no such named param from overridden errors';


done_testing;
