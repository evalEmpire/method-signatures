#!/usr/bin/perl -w

# Test the $arg! required syntax

use strict;
use warnings;

use Test::More;


{
    package Stuff;

    use lib 't/lib';
    use GenErrorRegex qw< required_error >;

    use Test::More;
    use Test::Exception;
    use Method::Signatures;

    method whatever($this!) {
        return $this;
    }

    is( Stuff->whatever(23),    23 );

#line 23
    throws_ok { Stuff->whatever() } required_error('Stuff', '$this', 'whatever', LINE => 23),
            'simple required param error okay';

    method some_optional($that!, $this = 22) {
        return $that + $this
    }

    is( Stuff->some_optional(18), 18 + 22 );

#line 33
    throws_ok { Stuff->some_optional() } required_error('Stuff', '$that', 'some_optional', LINE => 33),
            'some required/some not required param error okay';
}


done_testing();
