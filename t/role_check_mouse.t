#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';
use GenErrorRegex qw< badval_error >;

use Test::More;
use Test::Exception;

plan skip_all => "We dont't use Mouse anymore";

{ package Foo::Bar; sub new { bless {}, __PACKAGE__; } }

require MouseRoleTest;
use Method::Signatures;

my $mouse = WithMouseRole->new;
my $foobar = Foo::Bar->new;


func mousey (MouseRole $foo) {}


# positive test
lives_ok { mousey($mouse) } 'Mouse role passes okay';

# negative test
throws_ok { mousey($foobar) } badval_error(undef, foo => MouseRole => $foobar, 'mousey'),
        'Mouse role fails when appropriate';


done_testing;
