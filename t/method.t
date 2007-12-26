#!/usr/bin/perl -w

use Test::More tests => 4;

{
    package Foo;
    use Method::Signatures;

    method new(%args) {
        return bless {%args}, $self;
    };

    method set($key, $val) {
        return $self->{$key} = $val;
    };

    method get($key) {
        return $self->{$key};
    };
}

my $obj = Foo->new( foo => 42, bar => 23 );
isa_ok $obj, "Foo";
is $obj->get("foo"), 42;
is $obj->get("bar"), 23;

$obj->set(foo => 99);
is $obj->get("foo"), 99;

