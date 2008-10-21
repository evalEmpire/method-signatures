#!/usr/bin/perl -w

package Foo;

use strict;
use warnings;

use Method::Signatures;
use Test::More 'no_plan';

# The problem goes away inside an eval STRING.
method foo(
    $arg
)
{
    return $arg;
}
is $@, '';
is( Foo->foo(42), 42 );
