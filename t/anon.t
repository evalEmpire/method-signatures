#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More 'no_plan';

{
    package Stuff;

    use Test::More;
    use Method::Signatures;

    method echo($arg) {
        return $arg
    }

    my $method = method ($arg) {
        return $self->echo($arg)
    };

    is( Stuff->$method("foo"), "foo" );
}
