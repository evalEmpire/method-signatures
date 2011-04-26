#!/usr/bin/perl -w

package Foo;

use Test::More;
use Test::Exception;

use lib 't/lib';
use GenErrorRegex qw< required_error >;

use Method::Signatures;

method new($class:@_) {
    bless {@_}, $class;
}

method iso_date(
    :$year!,    :$month = 1, :$day = 1,
    :$hour = 0, :$min   = 0, :$sec = 0
)
{
    return "$year-$month-$day $hour:$min:$sec";
}

$obj = Foo->new;

is( $obj->iso_date(year => 2008), "2008-1-1 0:0:0" );
#line 25
throws_ok { $obj->iso_date() } required_error($obj, '$year', 'iso_date', LINE => 25);


done_testing();
