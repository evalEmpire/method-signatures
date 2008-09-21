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

    is_deeply([@have[0..2]], [@expected[0..2]]);
    is_deeply([@have[4..9]], [@expected[4..9]]);

    is_deeply([@have2[0..2]], [@expected2[0..2]]);
    is_deeply([@have2[4..9]], [@expected2[4..9]]);

    TODO: {
        local $TODO = 'caller() does not get method names';

        is $have[3],  $expected[3];
        is $have2[3], $expected2[3];
    }
}
