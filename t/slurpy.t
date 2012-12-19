#!/usr/bin/perl -w

# Test slurpy parameters

use strict;
use warnings;

use Test::More;
use Test::Exception;

{
    package Stuff;
    use Method::Signatures;
    use Test::More;

    method slurpy(@that) { return \@that }
    method slurpy_required(@that!) { return \@that }
    method slurpy_last($this, @that) { return $this, \@that; }

    ok !eval q[func slurpy_first(@that, $this) { return $this, \@that; }];
    like $@, qr{Slurpy parameter '\@that' must come at the end};
    TODO: {
        local $TODO = "error message incorrect inside an eval";

        like $@, qr{Stuff::};
        like $@, qr{slurpy_first\(\)};
    }

    ok !eval q[func slurpy_middle($this, @that, $other) { return $this, \@that, $other }];
    like $@, qr{Slurpy parameter '\@that' must come at the end};
    TODO: {
        local $TODO = "error message incorrect inside an eval";

        like $@, qr{Stuff::};
        like $@, qr{slurpy_middle\(\)};
    }

    ok !eval q[func slurpy_positional(:@that) { return \@that; }];
    like $@, qr{slurpy parameter \@that cannot be named, use a reference instead};

    TODO: {
        local $TODO = "error message incorrect inside an eval";

        like $@, qr{Stuff::};
        like $@, qr{slurpy_positional\(\)};
    }

    ok !eval q[func slurpy_two($this, @that, @other) { return $this, \@that, \@other }];
    like $@, qr{can only have one slurpy parameter at \Q$0\E line @{[__LINE__ - 1]}};
}


note "Optional slurpy params accept 0 length list"; {
    is_deeply [Stuff->slurpy()], [[]];
    is_deeply [Stuff->slurpy_last(23)], [23, []];
}

note "Required slurpy params require an argument"; {
    throws_ok { Stuff->slurpy_required() }
      qr{slurpy_required\Q()\E, missing required argument \@that at \Q$0\E line @{[__LINE__ - 1]}};
}


done_testing;
