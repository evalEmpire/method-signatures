#!/usr/bin/perl -w

# Test the bare sigil syntax: $, @ and %

use strict;
use warnings;

use Test::More;

use Method::Signatures;

{
    package Placeholder;

    use lib 't/lib';
    use GenErrorRegex qw< required_error required_placeholder_error placeholder_badval_error placeholder_failed_constraint_error >;

    use Test::More;
    use Test::Exception;
    use Method::Signatures;

    method only_placeholder($) {
        return $self;
    }

    is( Placeholder->only_placeholder(23),    'Placeholder' );

#line 28
    throws_ok { Placeholder->only_placeholder() } required_placeholder_error('Placeholder', 0, 'only_placeholder', LINE => 28),
            'simple required placeholder error okay';

    method add_first_and_last($first!, $, $last = 22) {
        return $first + $last
    }

    is( Placeholder->add_first_and_last(18, 19, 20), 18 + 20 );
    is( Placeholder->add_first_and_last(18, 19),     18 + 22 );

#line 39
    throws_ok { Placeholder->add_first_and_last() } required_error('Placeholder', '$first', 'add_first_and_last', LINE => 39),
            'missing required/named param error okay';

#line 43
    throws_ok { Placeholder->add_first_and_last(18) } required_placeholder_error('Placeholder', 1, 'add_first_and_last', LINE => 43),
            'missing required placeholder after required param error okay';

    method constrained_placeholder(Int $ where { $_ < 10 }) {
        return $self;
    }

    is( Placeholder->constrained_placeholder(2), 'Placeholder' );

# line 53
    throws_ok { Placeholder->constrained_placeholder() } required_placeholder_error('Placeholder', 0, 'constrained_placeholder', LINE => 53),
            'missing requierd constrained placeholder';
    throws_ok { Placeholder->constrained_placeholder('foo') } placeholder_badval_error('Placeholder', 0, 'Int' => 'foo', 'constrained_placeholder', LINE => 55),
            'placeholder value wrong type';
    throws_ok { Placeholder->constrained_placeholder(99) } placeholder_failed_constraint_error('Placeholder', 0, 99 => '{$_<10}', 'constrained_placeholder', LINE => 57),
            'placeholder value wrong type';

    method slurpy($foo, @) {
        $foo
    }

    is( Placeholder->slurpy(123), 123, 'slurpy, no extras');
    is( Placeholder->slurpy(123, 456, 789), 123, 'slurpy with extras');

    method slurpy_hash($foo, %) {
        $foo
    }

    is( Placeholder->slurpy_hash(123), 123, 'slurpy_hash, no extras');
    is( Placeholder->slurpy_hash(123, a => 1, b => 2), 123, 'slurpy_hash with extras');
    throws_ok { Placeholder->slurpy_hash(123, 456, a => 1) }
        qr{was given an odd number of arguments for a placeholder hash},
        'slurpy_hash with odd number of extras throws exception';

    method optional_placeholder($foo, $?, $bar?) {
        return [ $foo, $bar ];
    }

    is_deeply( Placeholder->optional_placeholder(1), [ 1, undef ], 'optional_placeholder with 1 arg');
    is_deeply( Placeholder->optional_placeholder(1, 2), [ 1, undef ], 'optional_placeholder with 2 args');
    is_deeply( Placeholder->optional_placeholder(1, 2, 3), [ 1, 3 ], 'optional_placeholder with 3 args');
}

done_testing();
