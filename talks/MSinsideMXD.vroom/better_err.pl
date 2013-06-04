#! /usr/bin/perl

use strict;
use warnings;

use MSMExample;


foo();


sub foo
{
    my $m = MyCompany::Bar->new;
    $m->adjusted_rate(type => 'sales', discount => 8.5);
}
