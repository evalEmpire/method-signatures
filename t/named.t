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
}
