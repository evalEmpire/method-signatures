#!/usr/bin/perl -w

use strict;
use warnings;

package Foo;

use Method::Signatures;
use Test::More 'no_plan';

method silly(
    $num    = 42,
    $string = q[Hello, world!],
    $hash   = { this => 42, that => 23 },
    $code   = sub { $num + 4 },
    @nums   = (1,2,3)
)
{
    return(
        num     => $num,
        string  => $string,
        hash    => $hash,
        code    => $code->(),
        nums    => \@nums
    );
}

is_deeply {Foo->silly()}, {
    num         => 42,
    string      => 'Hello, world!',
    hash        => { this => 42, that => 23 },
    code        => 46,
    nums        => [1,2,3]
};
