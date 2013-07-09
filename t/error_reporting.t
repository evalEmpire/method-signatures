#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';
use GenErrorRegex;                                                      # error-generating subs imported below

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
#   *)  The error thrown when you fail to pass a required argument.
#   *)  The error thrown when you pass a named argument that was not declared.
#   *)  The error thrown when you try to pass a type that is unrecognized.
#   *)  The error thrown when you try to pass an argument of the wrong type.
#
# This is mildly tricky, since trapping the error to check it means the error could end up reported
# as being in "eval 27" or somesuch.  So we're going to use a few different layers of files that
# include each other to work around that for the run-time errors.  For the compile-time errors,
# we'll just call require instead of use.
#
# Ready? Here we go.

my %compile_time_errors =
(
    BadParameter        =>  {
                                error_gen   =>  'bad_param_error',
                                error_args  =>  [
                                                    '&$bar',
                                                ],
                                test_name   =>  'illegal param spec reports correctly',
                            },
    TrailingGarbage     =>  {
                                error_gen   =>  'unexpected_after_error',
                                error_args  =>  [
                                                    '&',
                                                ],
                                test_name   =>  'trailing code after param reports correctly',
                            },
    NamedAfterOptPos    =>  {
                                error_gen   =>  'named_after_optpos_error',
                                error_args  =>  [
                                                    '$baz',
                                                    '$bar',
                                                ],
                                test_name   =>  'named param following optional positional reports correctly',
                            },
    PosAfterNamed       =>  {
                                error_gen   =>  'pos_after_named_error',
                                error_args  =>  [
                                                    '$baz',
                                                    '$bar',
                                                ],
                                test_name   =>  'positional param following named reports correctly',
                            },
    MispositionedSlurpy =>  {
                                error_gen   =>  'mispositioned_slurpy_error',
                                error_args  =>  [
                                                    '@bar',
                                                ],
                                test_name   =>  'mispositioned slurpy param reports correctly',
                            },
    MultipleSlurpy =>       {
                                error_gen   =>  'multiple_slurpy_error',
                                error_args  =>  [
                                                ],
                                test_name   =>  'multiple slurpy params reports correctly',
                            },
    NamedSlurpy =>          {
                                error_gen   =>  'named_slurpy_error',
                                error_args  =>  [
                                                    '@bar',
                                                ],
                                test_name   =>  'named slurpy param reports correctly',
                            },
);

my %run_time_errors =
(
    MissingRequired     =>  {
                                method      =>  'bar',
                                error_gen   =>  'required_error',
                                error_args  =>  [
                                                    'MissingRequired',
                                                    '$bar',
                                                    'foo',
                                                ],
                                test_name   =>  'missing required param reports correctly',
                            },
    NoSuchNamed         =>  {
                                method      =>  'bar',
                                error_gen   =>  'named_param_error',
                                error_args  =>  [
                                                    'NoSuchNamed',
                                                    'bmoogle',
                                                    'foo',
                                                ],
                                test_name   =>  'no such named param reports correctly',
                            },
    UnknownType         =>  {
                                method      =>  'bar',
                                error_gen   =>  'badtype_error',
                                error_args  =>  [
                                                    'UnknownType',
                                                    'Foo::Bmoogle',
                                                    "looks like it doesn't parse correctly",
                                                    'foo',
                                                ],
                                test_name   =>  'unrecognized type reports correctly',
                            },
    BadType             =>  {
                                method      =>  'bar',
                                error_gen   =>  'badval_error',
                                error_args  =>  [
                                                    'InnerBadType',
                                                    'bar',
                                                    'Int',
                                                    'thing',
                                                    'foo',
                                                ],
                                test_name   =>  'incorrect type reports correctly',
                            },
);

# this is *much* easier (and less error-prone) than having to update the import list manually up top
GenErrorRegex->import( map { $_->{error_gen} } values %compile_time_errors, values %run_time_errors );


while (my ($testclass, $test) = each %compile_time_errors)
{
    (my $testmod = "$testclass.pm") =~ s{::}{/}g;
    no strict 'refs';

    throws_ok  { require $testmod }
            $test->{error_gen}->(@{$test->{error_args}}, FILE => "t/lib/$testmod", LINE => 1133),
            $test->{test_name};
}

while (my ($testclass, $test) = each %run_time_errors)
{
    (my $testmod = "$testclass.pm") =~ s{::}{/}g;
    no strict 'refs';

    lives_ok  { require $testmod } "$testclass loads correctly";
    throws_ok { &{ $testclass . '::' . $test->{method} }->() }
            $test->{error_gen}->(@{$test->{error_args}}, FILE => "t/lib/" . $test->{error_args}[0] . ".pm", LINE => 1133),
            $test->{test_name};
}


# modifiers bad type value checks (handled a bit differently than those above)
SKIP:
{
    eval { require MooseX::Declare } or skip "MooseX::Declare required for this test", 1;

    # different modifiers will throw different types in their errors
    my %bad_types =
    (
        before      =>  'Int',
        around      =>  'Int',
        after       =>  'Num',
        override    =>  'Int',
        augment     =>  'Num',
    );

    lives_ok { require ModifierBadType } 'incorrect type loads correctly';

    foreach ( qw< before around after override augment > )
    {
        my $test_meth = "test_$_";
        my $error_args = [ 'Foo::Bar', num => $bad_types{$_} => 'thing', $test_meth, ];

        throws_ok{ ModifierBadType::bar($test_meth) }
                badval_error(@$error_args, FILE => 't/lib/ModifierBadType.pm', LINE => 1133),
                "incorrect type for $_ modifier reports correctly";
    }
}


done_testing;
