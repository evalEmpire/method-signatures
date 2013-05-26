#! /usr/bin/env perl

use 5.12.0;
use warnings;

use Method::Signatures;


func f (:$foo, :$bar)
{
}


f(foo => 0, baz => 0);
