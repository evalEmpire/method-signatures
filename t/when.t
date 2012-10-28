#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# Skip the test before Method::Signatures can try to compile it and blow up.
BEGIN {
    plan skip_all => "Perl 5.10 or higher required to test where constraints" if $] < 5.010;
}

use Method::Signatures;

subtest "when {}" => sub {
    func empty_hash( HashRef[Int] $ref = { foo => 23, bar => 42 } when {} ) {
        return $ref;
    }

    is_deeply empty_hash(),                    { foo => 23, bar => 42 };
    is_deeply empty_hash({}),                  { foo => 23, bar => 42 };
    is_deeply empty_hash({ this => 23 }),      { this => 23 };
};


subtest "when []" => sub {
    func empty_array( ArrayRef[Int] $ref = [1,2,3] when [] ) {
        return $ref;
    }

    is_deeply empty_array(),                    [1,2,3];
    is_deeply empty_array([]),                  [1,2,3];
    is_deeply empty_array([4,5,6]),             [4,5,6];
};

done_testing;
