#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';
use GenErrorRegex qw< badval_error >;

use Test::More;
use Test::Exception;

plan skip_all => "We dont't use Moose anymore";

{ package Foo::Bar; sub new { bless {}, __PACKAGE__; } }

SKIP:
{
    eval { require Moose } or skip "Moose required for testing Moose roles", 2;

    require MooseRoleTest;
    use Method::Signatures;

    my $moose = WithMooseRole->new;
    my $foobar = Foo::Bar->new;


    func moosey (MooseRole $foo) {}


    # positive test
    lives_ok { moosey($moose) } 'Moose role passes okay';

    # negative test
    throws_ok { moosey($foobar) } badval_error(undef, foo => MooseRole => $foobar, 'moosey'),
            'Moose role fails when appropriate';
}


done_testing;
