#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Method::Signatures;

note "types"; {
    my %tests = (
        q[Foo $bar]                         => [positional => "Foo"],
        q[$bar]                             => [positional => undef],
        q[type $bar, Some::Type @this]      => [positional => "type", "Some::Type"],
        q[RFC1234::Foo::bar32 $var]         => [positional => "RFC1234::Foo::bar32"],
        q[Foo :$var]                        => [named => "Foo"],
        q[Foo::Bar $var]                    => [positional => "Foo::Bar"],
    );

    for my $proto (keys %tests) {
        my $want = $tests{$proto};
        my $ms = Method::Signatures->new;

        $ms->parse_func(proto => $proto);

        my $which = shift @$want;
        for my $idx (0..$#{$want}) {
            is $ms->{signature}{$which}[$idx]{type}, $want->[$idx];
        }
    }
}


note "inject_for_type_check"; {
    {
        package My::MS;
        use base "Method::Signatures";

        sub inject_for_type_check {
            my $self = shift;
            my $sig = shift;
            return "type_check('$sig->{var}');";
        }
    }
    
    my $ms = My::MS->new;
    my $code = $ms->parse_func( proto => 'Foo $this, :$bar, Baz :%baz, Foo::Bar :$foobar' );
    like $code, qr{type_check\('\$this'\)};
    like $code, qr{type_check\('\%baz'\)};
    like $code, qr{type_check\('\$foobar'\)};
}

done_testing;
