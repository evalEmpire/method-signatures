#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

BEGIN {
    eval "use attributes;  1;" or plan skip_all => "Need attributes for this test";

    plan 'no_plan';
}


{
    package Stuff;

    use Test::More;
    use Method::Signatures;

    method echo($arg) : method {
        return $arg;
    }

    is( Stuff->echo(42), 42 );
    is_deeply( [attributes::get \&echo], ['method'] );
}


{
    use attributes;

    my $attrs;
    my $cb_called;

    sub MODIFY_CODE_ATTRIBUTES {
        my ($pkg, $code, @attrs) = @_;
        $cb_called = 1;
        $attrs = \@attrs;
        return ();
    }

    method moo : Bar Baz(fubar) {
    }

    method foo :Bar :Moo(:Ko{oh) : Baz(fu{bar:): { return {} }

    ok($cb_called, 'attribute handler got called');
    is_deeply($attrs, [qw/Bar Moo(:Ko{oh) Baz(fu{bar:)/], '... with the right attributes');
}
