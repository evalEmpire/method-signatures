#!/usr/bin/perl -w

# The method keyword should be evaluated at BEGIN time

package Foo;

use Test::More 'no_plan';

use Method::Signatures;

note "Testing compile at BEGIN time";
is( Foo->a_sub(42), 42,         "sub" );
is( Foo->a_method(42), 42,      "method" );
is( a_func(42), 42,             "func" );

sub a_sub {
    my($self, $arg) = @_;
    return $arg;
}

method a_method($arg) {
    return $arg;
}

func a_func($arg) {
    return $arg;
}
