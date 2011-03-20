#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Exception;


use NoOverrides;

func foo (Int $bar) {}

lives_ok { foo(42) } 'calls succeed for subclass with no overrides';


done_testing;
