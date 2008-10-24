#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 5;

{
    package Bla;
    use Test::More;
    use Method::Signatures;

    method new ($class:) {
	bless {}, $class;
    }

    method array_param_at_start (@a, $b, $c) {
	return "@a|$b|$c";
    }

    method array_param_in_midst ($a, @b, $c) {
	return "$a|@b|$c";
    }

    method array_param_at_end ($a, $b, @c) {
	return "$a|$b|@c";
    }

    eval q{
         method two_array_params ($a, @b, @c) {}
    };
    like($@, qr{signature can only have one slurpy parameter}, "Two array params");

    eval q{
         method two_slurpy_params ($a, %b, $c, @d, $e) {}
    };
    like($@, qr{signature can only have one slurpy parameter}, "Two slurpy params");
}

{
    local $TODO = "Should probably work";
    is(Bla->new->array_param_at_start(1, 2, 3, 4), "1 2|3|4", "Array parameter at start");
    is(Bla->new->array_param_in_midst(1, 2, 3, 4), "1|2 3|4", "Array parameter in midst");
}
is(Bla->new->array_param_at_end(1, 2, 3, 4), "1|2|3 4", "Array parameter at end");
