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

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    lives_ok { Foo->$method } "method $method is defined at $phase";
}

sub method_undefined
{
    my ($method) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    throws_ok { Foo->$method } qr/Can't locate object method/, "method $method is undefined at $phase";
}


# The default configuration with compile at BEGIN on.
method top_level_default() {}

# Turn it off.
use Method::Signatures { compile_at_BEGIN => 0 };
method top_level_off() {}

# And on again.
use Method::Signatures { compile_at_BEGIN => 1 };
method top_level_on() {}

# Now turn it off inside a lexical scope
{
    use Method::Signatures { compile_at_BEGIN => 0 };
    method inner_scope_off() {}
}

# And it's restored.
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
