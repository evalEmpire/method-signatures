#!/usr/bin/perl -w

use strict;
use warnings;

package Foo;

use Test::More "no_plan";
use Method::Signatures;

method foo(
    $arg
) 
{
    return $arg
}

is( Foo->foo(23), 23 );
