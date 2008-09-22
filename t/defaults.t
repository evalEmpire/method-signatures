#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More 'no_plan';

{
    package Stuff;

    use Test::More;
    use Method::Signatures;

    method add($this = 23, $that = 42) {
        return $this + $that;
    }

    method minus($this is ro = 23, $that is ro = 42) {
        return $this - $that;
    }

    method echo($message = "what?") {
        return $message
    }

    is( Stuff->add(),    23 + 42 );
    is( Stuff->add(99),  99 + 42 );
    is( Stuff->add(2,3), 5 );

    is( Stuff->minus(),         23 - 42 );
    is( Stuff->minus(99),       99 - 42 );
    is( Stuff->minus(2, 3),     2 - 3 );

    is( Stuff->echo(),          "what?" );
    is( Stuff->echo(undef),     undef   );
    is( Stuff->echo("who?"),    'who?'  );
}
