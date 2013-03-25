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

    # not using a type here, so we won't expect Moose to get loaded
    method foo1 ($bar) {};
}

my $foobar = Foo::Bar->new;

# at this point, Moose should not be loaded

is $INC{'Moose/Util/TypeConstraints.pm'}, undef, 'no type checking module loaded before method call';


$foobar->foo1(42);

# _still_ should have no Moose because we haven't requested any type checking

is $INC{'Moose/Util/TypeConstraints.pm'}, undef, 'no type checking module loaded before method call';


done_testing;
