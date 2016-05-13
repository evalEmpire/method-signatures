#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More 'no_plan';

use attributes;

{
    package Stuff;

    use Test::More;
    use Method::Signatures;

    method echo : method ($arg) {
        return $arg;
    }

    is( Stuff->echo(42), 42 );
    is_deeply( [attributes::get \&echo], ['method'] );
}


{
    package Foo;

    use Test::More;
    use Method::Signatures;

    my $code = func : method () {};
    is_deeply( [attributes::get $code], ['method'] );
}


{
    package Things;

    use attributes;
    use Method::Signatures;

    my $attrs;
    my $cb_called;

    sub MODIFY_CODE_ATTRIBUTES {
        my ($pkg, $code, @attrs) = @_;
        $cb_called = 1;
        $attrs = \@attrs;
        return ();
    }

    method moo : Bar Baz(fubar) ($foo, $bar) {
    }

    # Torture test for the attribute handling.
    method foo
    :
    Bar
    :Moo(:Ko{oh)
    : Baz(fu{bar:): ($foo, $bar) { return {} }

    ::ok($cb_called, 'attribute handler got called');
    ::is_deeply($attrs, [qw/Bar Moo(:Ko{oh) Baz(fu{bar:)/], '... with the right attributes');
}
