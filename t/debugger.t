#!/usr/bin/perl -w

use Test::More skip_all => 'none of this works';

is eval {
    local $SIG{ALRM} = sub { die "Alarm!\n"; };

    alarm 5;
    my $ret = `$^X "-Ilib" -le 'package Foo;  use Method::Signatures;  method foo(\$bar) { print \$bar } Foo->foo(42)'`;
    alarm 0;
    $ret;
}, "42\n";
is $@, '';


is eval {
    local $SIG{ALRM} = sub { die "Alarm!\n"; };

    alarm 5;
    my $ret = `$^X "-Ilib" -dle 'package Foo;  use Method::Signatures;  method foo(\$bar) { print \$bar } Foo->foo(42)'`;
    alarm 0;
    $ret;
}, "42\n";
is $@, '';
