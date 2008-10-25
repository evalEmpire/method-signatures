#!/usr/bin/perl -w

# The method keyword should be evaluated at BEGIN time

package Foo;

use Test::More 'no_plan';

use Method::Signatures;

is( Foo->bar(42), 42 );

TODO: {
    local $TODO = 'method not done at compile time';

    ok eval { is( Foo->foo(42), 42 ) };
    is $@, '';
}

sub bar {
    my($self, $arg) = @_;
    return $arg;
}

method foo($arg) {
    return $arg;
}

