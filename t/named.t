#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';

{
    package Foo;

    use Method::Signatures;
    use Test::More;

    method formalize($text is ro, :$justify = "left" is ro, :$case) {
        my %params;
        $params{text}           = $text;
        $params{justify}        = $justify;
        $params{case}           = $case if defined $case;

        return \%params;
    }

    ::is_deeply( Foo->formalize( "stuff" ), { text => "stuff", justify => "left" } );

#line 25
    method foo( :$arg! ) {
        return $arg;
    }

    ::is( Foo->foo( arg => 42 ), 42 );
    ::ok !eval { foo() };
    ::is $@, "Foo::foo() missing required argument \$arg at $0 line 30.\n";


    # Compile time errors need internal refactoring before I can get file, line and method
    # information.
    eval q{
        method wrong( :$named, $pos ) {}
    };
    like $@, qr/positional parameter \$pos after named param \$named/;

    eval q{
        method wrong( $foo, :$named, $bar ) {}
    };
    like $@, qr/positional parameter \$bar after named param \$named/;

    eval q{
        method wrong( $foo, $bar?, :$named ) {}
    };
    like $@, qr/named parameter \$named mixed with optional positional \$bar/;
}
