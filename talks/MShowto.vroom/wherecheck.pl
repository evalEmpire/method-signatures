#! /usr/bin/env perl

use 5.12.0;
use warnings;

use Method::Signatures;


func f (Int $foo where { $_ < 10 })
{
}


f(100);
