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
        method add($this = 23 when '', $that = 42 when '') {
            no warnings 'uninitialized';
            return $this + $that;
        }
    };

    like $@, qr{\Q'when' modifier on default only available under Perl 5.10 or later.\E},
            "Perls <5.10 properly error out on 'when' conditions";
}
else
{
    eval
    q{
        package Stuff;

        use Test::More;
        use Method::Signatures;

        method add($this = 23 when '', $that = 42 when '') {
            no warnings 'uninitialized';
            return $this + $that;
        }

        method minus($this is ro = 23 when '', $that is ro = 42 when "") {
            return $this - $that;
        }

        is( Stuff->add(),      23 + 42 );
        is( Stuff->add(''),    23 + 42 );
        is( Stuff->add(undef),      42 );
        is( Stuff->add(99),    99 + 42 );
        is( Stuff->add(2,3),   5 );

        is( Stuff->minus(),         23 - 42 );
        is( Stuff->minus(''),       23 - 42 );
        is( Stuff->minus(99),       99 - 42 );
        is( Stuff->minus(2, 3),     2 - 3 );


        # Test again that empty string doesn't override defaults
        method echo($message = "what?" when q{}) {
            return $message
        }

        is( Stuff->echo(),          "what?" );
        is( Stuff->echo(''),        "what?" );
        is( Stuff->echo("who?"),    'who?'  );


        # Test that you can reference earlier args in a default
        method copy_cat($this, $that = $this when '') {
            return $that;
        }

        is( Stuff->copy_cat("wibble"), "wibble" );
        is( Stuff->copy_cat("wibble", ""), "wibble" );
        is( Stuff->copy_cat(23, 42),   42 );
    };
    fail "can't run tests: $@" if $@;


    eval
    q{
        package Bar;
        use Test::More;
        use Method::Signatures;

        method hello($msg = "Hello, world!" when '') {
            return $msg;
        }

        is( Bar->hello,               "Hello, world!" );
        is( Bar->hello(q{}),        "Hello, world!" );
        is( Bar->hello("Greetings!"), "Greetings!" );


        method hi($msg = q,Hi, when '') {
            return $msg;
        }

        is( Bar->hi,                "Hi" );
        is( Bar->hi(q{}),         "Hi" );
        is( Bar->hi("Yo"),          "Yo" );


        method list(@args = (1,2,3) when ()) {
            return @args;
        }

        is_deeply [Bar->list()],      [1,2,3];


        method code($num, $code = sub { $num + 2 } when '') {
            return $code->();
        }

        is( Bar->code(42), 44 );
    };
    fail "can't run tests: $@" if $@;
}


done_testing;
