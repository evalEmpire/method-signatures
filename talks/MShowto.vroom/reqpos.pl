#! /usr/bin/env perl

use 5.12.0;
use warnings;

use Method::Signatures;


func f ($foo, $bar, :$baz)
{
}


f(0);
