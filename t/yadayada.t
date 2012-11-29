#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Warn;
use Test::Exception;

use Method::Signatures;

plan tests => 4;

subtest 'yada after positional' => sub {
    plan tests => 2;

    func yada_after_positional ($pos1, $pos2, ...) {
        subtest @_ . ' args' => sub {
            is $pos1, 'pos1' => '$pos1 okay';
            is $pos2, 'pos2' => '$pos2 okay';
            done_testing;                                               # for Test::More's before 0.96
        };
        return 1;
    }

    yada_after_positional('pos1', 'pos2', 'pos3', named => 'named');
    yada_after_positional('pos1', 'pos2', 'pos3', named => 'named', other => 'other');
};

subtest 'yada after named' => sub {
    plan tests => 2;

    func yada_after_named (:$named1, :$named2, ...) {
        subtest @_ . ' args' => sub {
            is $named1, 'named1' => '$named1 okay';
            is $named2, 'named2' => '$named2 okay';
            done_testing;                                               # for Test::More's before 0.96
        };
        return 1;
    }

    yada_after_named(named2 => 'named2', named1 => 'named1');
    yada_after_named(named2 => 'named2', named1 => 'named1', other => 'other');
};

subtest 'yada after both' => sub {
    plan tests => 2;

    func yada_after_both ($pos1, $pos2, :$named1, :$named2, ...) {
        subtest @_ . ' args' => sub {
            is $pos1, 'pos1' => '$pos1 okay';
            is $pos2, 'pos2' => '$pos2 okay';
            is $named1, 'named1' => '$named1 okay';
            is $named2, 'named2' => '$named2 okay';
            done_testing;                                               # for Test::More's before 0.96
        };
        return 1;
    }

    yada_after_named('pos1', 'pos2', named2 => 'named2', named1 => 'named1');
    yada_after_named('pos1', 'pos2', named2 => 'named2', named1 => 'named1', other => 'other');
};

subtest 'non-yada' => sub {
    plan tests => 2;

    func non_yada ($pos1, $pos2, :$named1, :$named2) {
        subtest @_ . ' args' => sub {
            is $pos1, 'pos1' => '$pos1 okay';
            is $pos2, 'pos2' => '$pos2 okay';
            is $named1, 'named1' => '$named1 okay';
            is $named2, 'named2' => '$named2 okay';
            done_testing;                                               # for Test::More's before 0.96
        };
        return 1;
    }

    non_yada('pos1', 'pos2', named2 => 'named2', named1 => 'named1');
    ok !eval{ non_yada('pos1', 'pos2', named2 => 'named2', named1 => 'named1', other => 'other') }
        => 'Extra args rejected';
};
