#!/usr/bin/perl -w

# Test the $arg! required syntax

use strict;
use warnings;

use Test::More 'no_plan';

{
    package Stuff;

    use Test::More;
    use Method::Signatures;

    method whatever($this!) {
        return $this;
    }

    is( Stuff->whatever(23),    23 );

#line 23
    ok !eval { Stuff->whatever(); 1 };
    is $@, "Stuff::whatever() missing required argument \$this at $0 line 23.\n";

    method some_optional($that!, $this = 22) {
        return $that + $this
    }

    is( Stuff->some_optional(18), 18 + 22 );

#line 33
    ok !eval { Stuff->some_optional() };
    is $@, "Stuff::some_optional() missing required argument \$that at $0 line 33.\n";
}
