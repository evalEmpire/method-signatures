#!/usr/bin/perl -w

# Test the $arg? optional syntax.

use strict;
use warnings;

use Test::More 'no_plan';

{
    package Stuff;

    use Test::More;
    use Method::Signatures;

    method whatever($this?) {
        return $this;
    }

    is( Stuff->whatever(23),    23 );

    method things($this? = 99) {
        return $this;
    }

    is( Stuff->things(),        99 );

    method some_optional($that, $this?) {
        return $that + ($this || 0);
    }

    is( Stuff->some_optional(18, 22), 18 + 22 );
    is( Stuff->some_optional(18), 18 );
}
