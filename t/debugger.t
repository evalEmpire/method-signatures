#!/usr/bin/perl -w

use Test::More 'no_plan';

TODO: {
    todo_skip "This is still totally hosed", 2;

    is eval {
        local $SIG{ALRM} = sub { die "Alarm!\n"; };

        alarm 5;
        my $ret = qx{$^X "-Ilib" -le "package Foo;  use Method::Signatures;  method foo() { 42 } print Foo->foo()"};
        alarm 0;
        $ret;
    }, "42\n", 'one-liner';
    is $@, '';
}


is eval {
    local $SIG{ALRM} = sub { die "Alarm!\n"; };

    alarm 5;
    my $ret = qx{$^X "-Ilib" -MMethod::Signatures -le "package Foo;  use Method::Signatures;  method foo() { 42 } print Foo->foo()"};
    alarm 0;
    $ret;
}, "42\n", 'one liner with -MMethod::Signatures';
is $@, '';


is eval {
    local $SIG{ALRM} = sub { die "Alarm!\n"; };

    local $ENV{PERLDB_OPTS} = 'NonStop';
    alarm 5;
    my $ret = qx{$^X "-Ilib" -dw t/simple.plx};
    alarm 0;
    $ret;
}, "42", 'debugger';
is $@, '';
