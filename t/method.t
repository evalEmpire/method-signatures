#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';

{
    package Foo;
    use Method::Signatures;

    method new (%args) {
        return bless {%args}, $self;
    }

    method set ($key, $val) {
        return $self->{$key} = $val;
    }

    method get ($key) {
        return $self->{$key};
    }
    
    method no_proto {
        return $self, @_;
    }
    
    method empty_proto() {
        return $self, @_;
    }
    
    method echo(@_) {
        return $self, @_;
    }
    
    method caller($foo, $bar) {
        return CORE::caller;
    }

#line 39
    method warn($foo, $bar) {
        my $warning = '';
        local $SIG{__WARN__} = sub { $warning = join '', @_; };
        CORE::warn "Testing warn";
        
        return $warning;
    }

    # Method with the same name as a loaded class.
    method strict () {
        42 
    }
}

my $obj = Foo->new( foo => 42, bar => 23 );
isa_ok $obj, "Foo";
is $obj->get("foo"), 42;
is $obj->get("bar"), 23;

$obj->set(foo => 99);
is $obj->get("foo"), 99;

for my $method (qw(no_proto empty_proto echo)) {
    is_deeply [$obj->$method(1,2,3)], [$obj,1,2,3];
}

is_deeply [$obj->caller], [__PACKAGE__, $0, __LINE__], 'caller works';

is $obj->warn, "Testing warn at $0 line 42.\n";

is eval { $obj->strict }, 42;
