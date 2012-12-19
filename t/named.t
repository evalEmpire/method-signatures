#!/usr/bin/perl -w

use strict;
use Test::More;


{
    package Foo;

    use lib 't/lib';
    use GenErrorRegex qw< required_error named_param_error >;

    use Test::More;
    use Test::Exception;
    use Method::Signatures;

    method formalize($text! is ro, :$justify is ro = "left", :$case) {
        my %params;
        $params{text}           = $text;
        $params{justify}        = $justify;
        $params{case}           = $case if defined $case;

        return \%params;
    }

    ::is_deeply( Foo->formalize( "stuff" ), { text => "stuff", justify => "left" } );

#line 24
    throws_ok { Foo->formalize( "stuff", wibble => 23 ) } named_param_error('Foo', wibble => 'formalize', LINE => 24),
            'simple named parameter error okay';

    method foo( :$arg! ) {
        return $arg;
    }

    is( Foo->foo( arg => 42 ), 42 );
#line 30
    throws_ok { foo() } required_error('Foo', '$arg', 'foo', LINE => 30),
            'simple named parameter error okay';


    eval q{
        method wrong( :$named, $pos ) {}
    };
    like $@, qr/positional parameter .* after named param/i;

    eval q{
        method wrong( $foo, :$named, $bar ) {}
    };
    like $@, qr/positional parameter .* after named param/i;

    eval q{
        method wrong( $foo, $bar?, :$named ) {}
    };
    like $@, qr/named parameter .* mixed with optional positional/i;
}


done_testing();
