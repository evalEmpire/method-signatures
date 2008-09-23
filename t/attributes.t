#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More skip_all => "waiting on Devel::Declare fix";

{
    package Stuff;

    use Test::More;
    use Method::Signatures;

    method echo($arg) : Something {
        return $arg;
    }
}
