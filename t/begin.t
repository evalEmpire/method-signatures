#!/usr/bin/perl

package Foo;

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Method::Signatures;


our $phase;
BEGIN { $phase = 'compile-time' }
INIT  { $phase = 'run-time'     }


sub method_defined
{
    my ($method) = @_;

    lives_ok { Foo->$method } "method $method is defined at $phase";
}

sub method_undefined
{
    my ($method) = @_;

    throws_ok { Foo->$method } qr/Can't locate object method/, "method $method is undefined at $phase";
}


method top_level_default() {}

#no compile_at_BEGIN;
method top_level_off() {}

#use compile_at_BEGIN;
method top_level_on() {}

{
    #no compile_at_BEGIN;
    method inner_scope_off() {}
}

method outer_scope_on() {}


# at compile-time, some should be defined and others shouldn't be
BEGIN {
    method_defined('top_level_default');
    method_undefined('top_level_off');
    method_defined('top_level_on');
    method_undefined('inner_scope_off');
    method_defined('outer_scope_on');
}

# by run-time, they should _all_ be defined
method_defined('top_level_default');
method_defined('top_level_off');
method_defined('top_level_on');
method_defined('inner_scope_off');
method_defined('outer_scope_on');


done_testing;
