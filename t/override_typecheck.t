#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Warn;


use OverrideTypeCheck;

func foo (Int $bar) {}

warning_is{ foo(42) } 'in overridden type_check';


done_testing;
