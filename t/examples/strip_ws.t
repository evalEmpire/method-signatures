#!/usr/bin/perl -w

package Foo;
use Test::More 'no_plan';
use Method::Signatures;

method strip_ws($str is alias) {
    $str =~ s{^\s+}{};
    $str =~ s{\s+$}{};
    return;
}

my $string = " stuff  ";
Foo->strip_ws($string);
is $string, "stuff";

