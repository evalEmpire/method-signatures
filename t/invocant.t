#!/usr/bin/perl -w

# Test that you can change the invocant.

use Test::More 'no_plan';

{
    package Stuff;

    use Test::More;
    use Method::Signatures;

    method bar($arg) {
        return $arg;
    }

    method invocant($class:) {
        $class->bar(0);
    }

    method with_arg($class: $arg) {
        $class->bar($arg);
    }

    method without_space($class:$arg) {
        $class->bar($arg);
    }

    is( Stuff->invocant,                0 );
    is( Stuff->with_arg(42),            42 );
    is( Stuff->without_space(42),       42 );
}
