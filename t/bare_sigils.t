#!/usr/bin/perl -w

# Test the bare sigil syntax: $, @ and %

use strict;
use warnings;

use Test::More;

use Method::Signatures;

{
    package Placeholder;

    use lib 't/lib';
    use GenErrorRegex qw< required_error required_placeholder_error >;

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
}

done_testing();
