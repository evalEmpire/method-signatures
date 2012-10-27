#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# if we don't load it up here, we get the "Devel::Declare not loaded soon enough" error
use Method::Signatures;


if ($] < 5.010)
{
    eval
    q{
        package Stuff;
        use Method::Signatures;

        method add($this //= 23, $that //= 42) {
            return $this + $that;
        }
    };

    like $@, qr{\Q'//=' defaults only available under Perl 5.10 or later.\E},
            "Perls <5.10 properly error out on //= declaration";
}
else
{
    eval
    q{
        package Stuff;

        use Test::More;
        use Method::Signatures;

        method add($this //= 23, $that //= 42) {
            return $this + $that;
        }

        method minus($this is ro //= 23, $that is ro //= 42) {
            return $this - $that;
        }

        is( Stuff->add(),      23 + 42 );
        is( Stuff->add(undef), 23 + 42 );
        is( Stuff->add(99),    99 + 42 );
        is( Stuff->add(2,3),   5 );

        is( Stuff->minus(),         23 - 42 );
        is( Stuff->minus(undef),     23 - 42 );
        is( Stuff->minus(99),       99 - 42 );
        is( Stuff->minus(2, 3),     2 - 3 );


        # Test again that undef doesn't override defaults
        method echo($message //= "what?") {
            return $message
        }

        is( Stuff->echo(),          "what?" );
        is( Stuff->echo(undef),     "what?" );
        is( Stuff->echo("who?"),    'who?'  );


        # Test that you can reference earlier args in a default
        method copy_cat($this, $that //= $this) {
            return $that;
        }

        is( Stuff->copy_cat("wibble"), "wibble" );
        is( Stuff->copy_cat("wibble", undef), "wibble" );
        is( Stuff->copy_cat(23, 42),   42 );
    };
    fail "can't run tests: $@" if $@;


    eval
    q{
        package Bar;
        use Test::More;
        use Method::Signatures;

        method hello($msg //= "Hello, world!") {
            return $msg;
        }

        is( Bar->hello,               "Hello, world!" );
        is( Bar->hello(undef),        "Hello, world!" );
        is( Bar->hello("Greetings!"), "Greetings!" );


        method hi($msg //= q,Hi,) {
            return $msg;
        }

        is( Bar->hi,                "Hi" );
        is( Bar->hi(undef),         "Hi" );
        is( Bar->hi("Yo"),          "Yo" );


        method list(@args = (1,2,3) when ()) {
            return @args;
        }

        is_deeply [Bar->list()],      [1,2,3];


        method code($num, $code //= sub { $num + 2 }) {
            return $code->();
        }

        is( Bar->code(42), 44 );
    };
    fail "can't run tests: $@" if $@;
}


done_testing;
