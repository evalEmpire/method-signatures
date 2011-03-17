#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Exception;


# This test file is all about making sure that errors are reported at the right places.  That is,
# when you make a compile-time mistake, we should report the error at the place where you declare
# the method, and when you make a run-time mistake, we should report it at the place where you
# _call_ the method, not in the method itself, or (even worse) somewhere deep inside
# Method::Signatures.
#
# The errors we're concerned about are:
#
#   *)  The error thrown when you try to pass a type that is unrecognized.
#   *)  The error thrown when you try to pass an argument of the wrong type.
#
# This is mildly tricky, since trapping the error to check it means the error could end up reported
# as being in "eval 27" or somesuch.  So we're going to use a few different layers of files that
# include each other to work around that for the run-time errors.  For the compile-time errors,
# we'll just call require instead of use.
#
# Ready? Here we go.


# unrecognized type (run-time error)
lives_ok { require UnknownType } 'unrecognized type loads correctly';
throws_ok{ UnknownType::bar() } qr{type.*unrecognized.*at .*/UnknownType.pm line 1133$}m,
        'unrecognized type reports correctly';


# incorrect type (run-time error)
lives_ok { require BadType } 'incorrect type loads correctly';
throws_ok{ BadType::bar() } qr{not of type.*at .*/BadType.pm line 1133$}m,
        'incorrect type reports correctly';


done_testing;
