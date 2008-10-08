#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';

{
    package Foo;

    use Method::Signatures;

    method formalize($text, :$justify = "left", :$case) {
        my %params;
        $params{text}           = $text;
        $params{justify}        = $justify;
        $params{case}           = $case if defined $case;

        return \%params;
    }

    ::is_deeply( Foo->formalize( "stuff" ), { text => "stuff", justify => "left" } );

#line 23
    method foo( :$arg! ) {
        return $arg;
    }

    ::is( Foo->foo( arg => 42 ), 42 );
    ::ok !eval { foo() };
    ::is $@, "Foo::foo() missing required argument \$arg at $0 line 28.\n";
}
