#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Method::Signatures;


my %tests =
(
    q{ method foo1 (Str $bar) {} }          => 'type on positional parameter',
    q{ method foo2 (Str :$bar) {} }         => 'type on named parameter',
    q{ method foo3 ($bar, Int $baz) {} }    => 'types on some parameters',
);

my $error = q{Type checking not implemented in base Method::Signatures; try 'use Method::Signatures qw<:TYPES>'};
foreach (keys %tests)
{
    # this ought to work, but it doesn't, somehow ...
    #throws_ok { eval } qr/$error at .*$0/, "correctly dies $tests{$_}";

    eval;
    like $@, qr/$error at \(eval/, "correctly dies for $tests{$_}";
}


done_testing;
