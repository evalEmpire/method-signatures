#!/usr/bin/perl -w

# Test that caller() works

{
    package Foo;

    use Test::More 'no_plan';

    use Method::Signatures;

    sub sub_caller {
        my($self, $level) = @_;
#line 13
        return caller($level);
    }


    sub sub_caller2 {
        my($self, $level) = @_;
#line 20
        return $self->sub_caller($level);
    }


    method method_caller($level) {
#line 13
        return caller($level);
    }


    method method_caller2($level) {
#line 20
        return $self->method_caller($level);
    }

#line 36
    my @expected  = Foo->sub_caller2(0);
    my @expected2 = Foo->sub_caller2(1);

#line 36
    my @have      = Foo->method_caller2(0);
    my @have2     = Foo->method_caller2(1);

    $expected[3]  = 'Foo::method_caller';
    $expected2[3] = 'Foo::method_caller2';

    is_deeply([@have[0..7]],  [@expected[0..7]]);
    is_deeply([@have2[0..7]], [@expected2[0..7]]);

    # hints and bitmask change and are twitchy so I'm just going to
    # check that they're there.
    isnt $have[8],  undef;
    isnt $have2[8], undef;
    isnt $have[9],  undef;
    isnt $have2[9], undef;
}
