#!/usr/bin/perl -w

package Foo;

use strict;
use Test::Warn;
use Test::More 'no_plan';

use Method::Signatures;

method foo(:$name, :$value) {
    return $name, $value;
}


TODO: {
    # Test::Warn is having issues with $TODO.
    Test::More->builder->todo_start("Odd number of elements should happen at the caller");

#line 20
    my @result;
    warning_like {
        @result = Foo->foo(name => 42, value =>);
    } qr/^Odd number of elements in hash assignment at \Q$0\E line 22.$/;

    Test::More->builder->todo_end;

    # Or should it be an error?
    is_deeply \@result, [42, undef];
}
