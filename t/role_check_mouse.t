#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Exception;


{ package Foo::Bar; sub new { bless {}, __PACKAGE__; } }

require MouseRoleTest;
use Method::Signatures qw< :TYPES >;

my $mouse = WithMouseRole->new;
my $foobar = Foo::Bar->new;


func mousey (MouseRole $foo) {}


# positive test
lives_ok { mousey($mouse) } 'Mouse role passes okay';

# negative test
throws_ok { mousey($foobar) } qr/The 'foo' parameter \(.*\) to main::mousey is not of type MouseRole/,
        'Mouse role fails when appropriate';


done_testing;
