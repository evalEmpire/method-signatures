#!/usr/bin/perl -w

use strict;
use warnings;

use lib 't/lib';
use Dev::Null;

use Test::More;

BEGIN {
    plan skip_all => "Data::Alias not available" unless eval { require Data::Alias };
    plan 'no_plan';
}

# Test a basic alias.
{
    package Foo;

    use Test::More;

    use Method::Signatures;

    method add_one_to_each(\:@args) {
        $_++ for @args;
        return @args;
    }

    my @input = (1,2,3);
    is_deeply [Foo->add_one_to_each(args=>\@input)], [2,3,4];
    is_deeply \@input, [2,3,4];

    tie *STDERR, "Dev::Null";
    ok !eval q[@args; 1;], '\@args does not leak out of subroutine';
    untie *STDERR;
}


# Try to break the aliasing prototype
{
    package Bar;

    use Test::More;

    use Method::Signatures;

    method break_args($foo, \:@bar, \:%baz, :$num, \:$biff, ...) {
        return {
            foo         => $foo,
            bar         => \@bar,
            baz         => \%baz,
            num         => $num,
            biff        => $biff,
        }
    }

    is_deeply(
      Bar->break_args(1, bar=>[2,3], baz=>{4 => 5}, num=>6, biff=>\7, (8,9)),
      { foo => 1, bar => [2,3], baz => {4 => 5}, num => 6, biff => 7 }
    );
}


# What about closures?
{
    package Stuff;

    use Method::Signatures;

    method make_closure(\:@nums) {
        return sub {
            return @nums;
        };
    }

    my $closure1 = Stuff->make_closure(nums=>[1,2,3]);
    my $closure2 = Stuff->make_closure(nums=>[4,5,6]);

    ::is_deeply [$closure1->()], [1,2,3];
    ::is_deeply [$closure2->()], [4,5,6];
}


