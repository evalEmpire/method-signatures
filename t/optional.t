#!/usr/bin/perl -w

# Test the $arg? optional syntax.

use strict;
use warnings;

use Test::More;

{
    package Stuff;

    use Test::More;
    use Test::Exception;
    use Method::Signatures;

    method whatever($this?) {
        return $this;
    }

    is( Stuff->whatever(23),    23 );

    method things($this? = 99) {
        return $this;
    }

    is( Stuff->things(),        99 );

    method some_optional($that, $this?) {
        return $that + ($this || 0);
    }

    is( Stuff->some_optional(18, 22), 18 + 22 );
    is( Stuff->some_optional(18), 18 );


    # are named parameters optional by default?
    method named_params(:$this, :$that) {}

    lives_ok { Stuff->named_params(this => 0) } 'can leave out some named params';
    lives_ok { Stuff->named_params(         ) } 'can leave out all named params';


    # are slurpy parameters optional by default?
    # (throwing in a default just for a little feature interaction test)
    method slurpy_param($this, $that = 0, @other) {}

    my @a = ();
    lives_ok { Stuff->slurpy_param(0, 0, @a) } 'can pass empty array to slurpy param';
    lives_ok { Stuff->slurpy_param(0, 0    ) } 'can omit slurpy param altogether';
    lives_ok { Stuff->slurpy_param(0       ) } 'can omit other optional params as well as slurpy param';
}


done_testing;
