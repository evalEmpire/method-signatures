#!/usr/bin/perl -w

package Foo;
use Test::More;

BEGIN {
    plan skip_all => "Data::Alias not available" unless eval { require Data::Alias };
    plan 'no_plan';
}

use Method::Signatures;

method strip_ws($str is alias) {
    $str =~ s{^\s+}{};
    $str =~ s{\s+$}{};
    return;
}

my $string = " stuff  ";
Foo->strip_ws($string);
is $string, "stuff";

