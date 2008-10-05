#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More 'no_plan';

{
    package Stuff;

    use Test::More;
    use Method::Signatures;

    method whatever($this is foo) {
        return $this;
    }

    method andever($this is foo is bar) {
        return $this;
    }

    is( Stuff->whatever(23),  23 );
    is( Stuff->andever(42),    42 );
}
