#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

plan skip_all => "This only applies to Perls before 5.10" if $] >= 5.010;

use Method::Signatures;

{
    eval
    q{
        func neg_and_odd_and_prime ($x where [0..10]) {
            return 1;
        }
    };

    like $@, qr{\Q'where' constraint only available under Perl 5.10 or later.\E},
             "Perls <5.10 properly error out on where constraints";
}

{
    eval
    q{
        package Stuff;
        use Method::Signatures;

        method add($this //= 23, $that //= 42) {
            return $this + $that;
        }
    };

    like $@, qr{\Q'//=' defaults only available under Perl 5.10 or later.\E},
            "Perls <5.10 properly error out on //= declaration";
}

{
    eval
    q{
        package Stuff;
        use Method::Signatures;
        method add($this = 23 when '', $that = 42 when '') {
            no warnings 'uninitialized';
            return $this + $that;
        }
    };

    like $@, qr{\Q'when' modifier on default only available under Perl 5.10 or later.\E},
            "Perls <5.10 properly error out on 'when' conditions";
}

done_testing;
