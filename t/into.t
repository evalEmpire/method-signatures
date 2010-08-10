#!/usr/bin/perl -w

# It should be possible to import into another package.

package Foo;

use Test::More 'no_plan';

{ package Bar;
  use Method::Signatures { into => 'Foo' };
}

is( Foo->foo(42), 42 );

method foo ($arg) {
    return $arg;
}
