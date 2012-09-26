#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More 'no_plan';

{
    package Stuff;

    use Test::More;
    use Method::Signatures;

    method add($this = 23 when 0, $that = 42 when 0) {
        no warnings 'uninitialized';
        return $this + $that;
    }

    method minus($this is ro = 23 when 0, $that is ro = 42 when 0x0) {
        return $this - $that;
    }

    is( Stuff->add(),      23 + 42 );
    is( Stuff->add(0),     23 + 42 );
    is( Stuff->add(undef),      42 );
    is( Stuff->add(99),    99 + 42 );
    is( Stuff->add(2,3),   5 );

    is( Stuff->minus(),         23 - 42 );
    is( Stuff->minus(0),       23 - 42 );
    is( Stuff->minus(99),       99 - 42 );
    is( Stuff->minus(2, 3),     2 - 3 );


    # Test again that empty string doesn't override defaults
    method echo($message = "what?" when 0.0) {
        return $message
    }

    is( Stuff->echo(),          "what?" );
    is( Stuff->echo(0),         "what?" );
    is( Stuff->echo(1),         1  );


    # Test that you can reference earlier args in a default
    method copy_cat($this, $that = $this when 0) {
        return $that;
    }

    is( Stuff->copy_cat("wibble"), "wibble" );
    is( Stuff->copy_cat("wibble", ""), "wibble" );
    is( Stuff->copy_cat(23, 42),   42 );
}


{
    package Bar;
    use Test::More;
    use Method::Signatures;

    method hello($msg = "Hello, world!" when 0) {
        return $msg;
    }

    is( Bar->hello,               "Hello, world!" );
    is( Bar->hello(0x0),          "Hello, world!" );
    is( Bar->hello(42),           42              );


    method hi($msg = q,Hi, when 0) {
        return $msg;
    }

    is( Bar->hi,                "Hi" );
    is( Bar->hi(0.0),           "Hi" );
    is( Bar->hi(1),             1    );


    method list(@args = (1,2,3) when ()) {
        return @args;
    }

    is_deeply [Bar->list()],      [1,2,3];


    method code($num, $code = sub { $num + 2 } when 0) {
        return $code->();
    }

    is( Bar->code(42), 44 );
}



