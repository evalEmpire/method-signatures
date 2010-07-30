#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => "Data::Alias not available" unless eval { require Data::Alias };
    plan 'no_plan';
}

{
    package Stuff;

    use Test::More;
    use Method::Signatures;

    method add_meaning($arg is alias) {
        $arg += 42;
    }

    my $life = 23;
    Stuff->add_meaning($life);
    is $life, 23 + 42;
}
