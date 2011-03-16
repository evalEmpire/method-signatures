#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Exception;


{ package Foo::Bar; sub new { bless {}, __PACKAGE__; } }

SKIP:
{
    eval "use Moose ()";
    skip "Moose required for testing Moose roles", 2 if $@;

    require MooseRoleTest;
    use Method::Signatures qw< :TYPES >;

    my $moose = WithMooseRole->new;
    my $foobar = Foo::Bar->new;


    func moosey (MooseRole $foo) {}


    # positive test
    lives_ok { moosey($moose) } 'Moose role passes okay';

    # negative test
    throws_ok { moosey($foobar) } qr/The 'foo' parameter \(.*\) to main::moosey is not of type MooseRole/,
            'Moose role fails when appropriate';
}


done_testing;
