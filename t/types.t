#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Method::Signatures;

note "types"; {
    my %tests = (
        q[Foo $bar]                         => ["Foo"],
        q[$bar]                             => [undef],
        q[type $bar, Some::Type @this]      => ["type", "Some::Type"],
        q[RFC1234::Foo::bar32 $var]         => ["RFC1234::Foo::bar32"],
    );

    for my $proto (keys %tests) {
        my $want = $tests{$proto};
        my $ms = Method::Signatures->new;

        $ms->parse_func(proto => $proto);

        for my $idx (0..$#{$want}) {
            is $ms->{signature}{positional}[$idx]{type}, $want->[$idx];
        }
    }
}

done_testing;
