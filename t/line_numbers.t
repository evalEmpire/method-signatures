#!/usr/bin/perl -w

# Test that Method::Signatures does not change the line numbers
# in caller and error messages.

use strict;
use Test::More;

use Method::Signatures;

my $DEFAULT_LINES_NOT_WORKING = $^V < 5.12.0;
my $DEFAULT_LINES_NOT_WORKING_REASON = 'Earlier versions of Perl get the line numbers wrong';

note "Basic multi-line signature"; {
#line 13
    func basic_multi_line (
        $arg = "test"
    ) {
        return __LINE__;
    }

    is basic_multi_line(), 16;
}


note "Computed default"; {
    # Using 'sub' to avoid further Method::Signatures interference
    sub return_caller_line {
        return (caller)[2];
    }

#line 30
    func computed_default (
        $static_default   = "test",
        $computed_default = return_caller_line()
    ) {
        return [__LINE__, $computed_default];
    }

    my $have = computed_default();
    is $have->[0], 34, "body line number";
    SKIP: {
        skip $DEFAULT_LINES_NOT_WORKING_REASON, 1 if $DEFAULT_LINES_NOT_WORKING;
        is $have->[1], 32, "computed default line number";
    };
}


note "single line signature"; {
#line 45
    func single_line($a?, $b?, $c?) { return __LINE__ }
    is single_line, 45;
}


# Multi-line defaults are collapsed into one line, so __LINE__
# will be off after the first line of each default.
note "multi-line default"; {
#line 52
    func multi_line_defaults(
        $a = { line => __LINE__
        },
        $b = { line => __LINE__
        }
    ) {
        return [$a->{line}, $b->{line}, __LINE__];
    }

    my $have = multi_line_defaults;
    SKIP: {
        skip $DEFAULT_LINES_NOT_WORKING_REASON, 1 if $DEFAULT_LINES_NOT_WORKING;
        is $have->[0], 53, 'default $a';
        is $have->[1], 55, 'default $b';
    }
    is $have->[2], 58, 'body';
}


done_testing;
