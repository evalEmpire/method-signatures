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

    is( Stuff->add(),    23 + 42 );
    is( Stuff->add(99),  99 + 42 );
    is( Stuff->add(2,3), 5 );

    is( Stuff->minus(),         23 - 42 );
    is( Stuff->minus(99),       99 - 42 );
    is( Stuff->minus(2, 3),     2 - 3 );


    # Test that undef overrides defaults
    method echo($message = "what?") {
        return $message
    }

    is( Stuff->echo(),          "what?" );
    is( Stuff->echo(undef),     undef   );
    is( Stuff->echo("who?"),    'who?'  );


    # Test that you can reference earlier args in a default
    method copy_cat($this, $that = $this) {
        return $that;
    }

    is( Stuff->copy_cat("wibble"), "wibble" );
    is( Stuff->copy_cat(23, 42),   42 );
}


{
    package Bar;
    use Test::More;
    use Method::Signatures;

    method hello($msg = "Hello, world!") {
        return $msg;
    }

    is( Bar->hello,               "Hello, world!" );
    is( Bar->hello("Greetings!"), "Greetings!" );


    method hi($msg = q,Hi,) {
        return $msg;
    }

    is( Bar->hi,                "Hi" );
    is( Bar->hi("Yo"),          "Yo" );


    method list(@args = (1,2,3)) {
        return @args;
    }

    is_deeply [Bar->list()], [1,2,3];


    method code($num, $code = sub { $num + 2 }) {
        return $code->();
    }

    is( Bar->code(42), 44 );
}


note "Defaults are applied before type check"; {
    package Baz;
    use Test::More;
    use Method::Signatures;

    func hi(
        Str $place = "World" when undef
    ) {
        return "Hi, $place!\n";
    }

    is hi(),      "Hi, World!\n";
    is hi(undef), "Hi, World!\n";
}


note "Defaults are type checked"; {
    package Biff;
    use Test::More;
    use Method::Signatures;

    func hi(
        Object $place = "World" when undef
    ) {
        return "Hi, $place!\n";
    }

    ok !eval { hi() };
    like $@, qr/the 'place' parameter \("World"\) is not of type Object/;
}
