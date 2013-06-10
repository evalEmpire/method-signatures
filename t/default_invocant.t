#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

sub do_common_subtests {
    my %opt = @_;
    my $class = $opt{class};
    subtest $opt{desc} => sub {
        is $class->name,        $class,     'works in class method call';
        my $obj = new_ok        $class, [], 'works in constructor';
        isa_ok $obj->self,      $class,     'works in object method call';
        isa_ok $obj->specified, $class,     'invocant specified in signature still works';
        done_testing;
    };
}

# TODO: Should I generate these test classes? They're so very repetitive.
#       Can't think of a simple way without string-eval, though...
{
    package Foo;
    use Test::More;
    use Method::Signatures { invocant => '$foo' };

    method name { return $foo } # call this as a class method.
    method new { return bless {}, $foo }
    method self { return $foo }
    method specified( $fnord: ) { return $fnord }

    main::do_common_subtests(
        class => 'Foo',
        desc  => 'use option to specify different default invocant var',
    );
}

{
    package Bar;
    use Test::More;
    use Method::Signatures { invocant => '$bar' };

    method name { return $bar }
    method new { return bless {}, $bar }
    method self { return $bar }
    method specified( $fnord: ) { return $fnord }

    main::do_common_subtests(
        class => 'Bar',
        desc  => 'diff invocant option in diff class in same program',
    );
}

{
    package Self;
    use Test::More;
    use Method::Signatures;

    method name { return $self }
    method new { return bless {}, $self }
    method self { return $self }
    method specified( $fnord: ) { return $fnord }

    main::do_common_subtests(
        class => 'Self',
        desc  => 'no invocant option in diff class in same program still defaults to "$self"',
    );
}

done_testing;
