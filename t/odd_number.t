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
    local $TODO = 'Odd number warning should happen at caller';

#line 20
    warning_like {
#        local $TODO;
        is_deeply [Foo->foo(name => 42, value =>)], [42, undef];
    } qr/^Odd number of elements in hash assignment at \Q$0\E line 22.$/;
}
