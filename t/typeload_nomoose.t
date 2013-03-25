#!/usr/bin/perl

use strict;
use warnings;

use Test::More;


{
    package Foo::Bar;

    use strict;
    use warnings;

    use Method::Signatures;

    method new ($class:) { bless {}, $class; }

    method foo1 (Int $bar) {};
}

my $foobar = Foo::Bar->new;

# at this point, Moose should not be loaded (yet)

is $INC{'Moose/Util/TypeConstraints.pm'}, undef, 'no type checking module loaded before method call';


$foobar->foo1(42);

# now we should have loaded Mouse to do our type checking

is $INC{'Moose/Util/TypeConstraints.pm'}, undef, "didn't load Moose";


done_testing;
