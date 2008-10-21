#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More 'no_plan';

use Method::Signatures::Parser;

my %tests = (
    '$foo'              => ['$foo'],
    '$foo, $bar'        => ['$foo', '$bar'],
    ':$foo, $bar?'      => [':$foo', '$bar?'],
    ''                  => [],
    '$foo = "Hello, world!"'    => ['$foo = "Hello, world!"'],
);

while(my($args, $expect) = each %tests) {
    is_deeply [split_proto($args)], $expect, "split_proto($args)";
}
