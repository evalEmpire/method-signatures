#!/usr/bin/perl -w

# Test slurpy parameters

use strict;
use warnings;

use Test::More;

{
    package Stuff;
    use Method::Signatures;
    use Test::More;

    func slurpy(@that) { return @that }
    func slurpy_last($this, @that) { return $this, \@that; }

    TODO: {
        local $TODO = "Finish slurpy tests";

        ok !eval q[func slurpy_first(@that, $this) { return $this, \@that; }];
        like $@, qr{slurpy parameter must come at end};

        ok !eval q[func slurpy_middle($this, @that, $other) { return $this, \@that, $other }];
        like $@, qr{slurpy parameter must come at end};
    }

    ok !eval q[func slurpy_two($this, @that, @other) { return $this, \@that, \@other }];
    like $@, qr{can only have one slurpy parameter at \Q$0\E line @{[__LINE__ - 1]}};
}

done_testing;
