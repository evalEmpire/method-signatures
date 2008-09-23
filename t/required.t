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

    method some_optional($that!, $this = 22) {
        return $that + $this
    }

    is( Stuff->some_optional(18), 18 + 22 );
}
