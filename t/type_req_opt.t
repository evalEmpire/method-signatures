#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;


{
    package TypeCheck::RequiredOptional;

    use strict;
    use warnings;

    use Method::Signatures;

    method new ($class:) { bless {}, $class; }


    method required_named      ( Int :$foo! ) {}
    method optional_named      ( Int :$foo  ) {}
    method required_positional ( Int  $foo  ) {}
    method optional_positional ( Int  $foo? ) {}

}

our $tester = TypeCheck::RequiredOptional->new;


lives_ok { $tester->optional_named() } 'no type error when failing to pass optional named arg';
lives_ok { $tester->optional_positional() } 'no type error when failing to pass optional positional arg';

throws_ok { $tester->required_named() } qr/missing required argument/,
        'proper error when failing to pass required named arg';
throws_ok { $tester->required_positional() } qr/missing required argument/,
        'proper error when failing to pass required positional arg';


done_testing;
