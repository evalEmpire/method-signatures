#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use Method::Signatures;

func echo($arg) {
    return $arg;
}

is echo(42), 42, "basic func";
