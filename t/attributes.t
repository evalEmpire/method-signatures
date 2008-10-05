#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

BEGIN {
    eval "use attributes qw(get);  1;" or plan skip_all => "Need attributes for this test";
    eval "use Attribute::Handlers; 1;" or plan skip_all => "Need Attribute::Handlers for this test";

    plan 'no_plan';
}


{
    package Stuff;

    use Test::More;
    use Method::Signatures;

    method echo($arg) : method {
        return $arg;
    }

    is( Stuff->echo(42), 42 );
    is_deeply( [::get \&echo], ['method'] );
}


{
    package Things;

    use Test::More;
    use Method::Signatures;
    use Attribute::Handlers;

    sub Test : ATTR {
        my($package, $symbol, $referent, $attr, $data) = @_;

        is_deeply( $data, { foo => 23 } ) || diag explain $data;
    }

    method echo($arg) : Test({foo => 23}) { return $arg }

    is( Things->echo(42), 42 );
}
