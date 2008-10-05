#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More 'no_plan';

{
    package Stuff;

    use Test::More;
    use Method::Signatures;

    method echo($arg is ro) {
        return $arg;
    }

#line 19
    method naughty($arg is ro) {
        $arg++
    }

    is( Stuff->echo(42), 42 );
    ok !eval { Stuff->naughty(23) };
    like $@, qr/^Modification of a read-only value attempted at \Q$0\E line 20/;
}
