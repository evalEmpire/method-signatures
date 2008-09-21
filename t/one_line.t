#!/usr/bin/perl -w

use Test::More tests => 1;

{
    package Thing;

    use Method::Signatures;
    method foo {"wibble"}

    ::is( Thing->foo, "wibble" );
}
