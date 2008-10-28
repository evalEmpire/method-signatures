#!/usr/bin/perl -lw

package String;
use Method::Signatures;

method strip_ws($str is alias) {
    $str =~ s{^\s+}{};
    $str =~ s{\s+$}{};
    return;
}

my $string = " stuff  ";
print "String was: '$string'";
String->strip_ws($string);
print "String is:  '$string'";
