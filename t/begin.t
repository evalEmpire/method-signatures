#!/usr/bin/perl -w

package Foo;

# The method keyword should be evaluated at BEGIN time

use Test::More 'no_plan';

use Method::Signatures;

is( Foo->bar(42), 42 );

TODO: {
    local $TODO = 'method not done at compile time';

    ok eval { is( Foo->foo(42), 42 ) };
}

sub bar {
    my($self, $arg) = @_;
    return $arg;
}

method foo($arg) {
    return $arg;
}

