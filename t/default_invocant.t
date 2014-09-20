#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# in each class/package constructed in this test script, we want to essentially
# perform the same set of tests, just with slightly different parameters.
sub do_common_subtests {
    my %opt = @_;
    my $class = $opt{class} || scalar caller;
    subtest $opt{desc} => sub {
        is $class->name,        $class,     'works in class method call';
        my $obj = new_ok        $class, [], 'works in constructor';
        isa_ok $obj->self,      $class,     'works in object method call';
        isa_ok $obj->specified, $class,     'invocant specified in signature still works';
        done_testing;
    };
}


# Below are a series of packages that use MS with various, um, variations
# on setting the import parameter. Not only do we want to make sure that using
# the parameter works properly, we also want to ensure it doesn't change
# existing functionality when it's not being used. We also want to be sure that
# invalid values cause an exception, but when that happens it still does not
# break anything for other classes using MS. (hey, it happens)


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
        desc => 'use option to specify different default invocant var',
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
        desc => 'diff invocant option in diff class in same program',
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
        desc => 'no invocant option in diff class in same program still defaults to "$self"',
    );
}


{
    package Bad;
    use Test::More;

    # this seems exhaustive enough for now...
    my @bad_invocants = (
        q{bad},    q{$also bad}, q{$real $bad},  q{thriller was a great album},
        q{%worse}, q{"$worser"}, q{'$wurst'},    q{weiner $chnitzel},
        q{""},     q{''},        q{[]},          q[{}],
        q{},       q{undef},     q{0foo},        q{$0foo},
        q{$},      q{$$},        q{$-},          q{$-foo},
        q{$fo-o},  q{$foo-},     q{$foo-bar},    q{$$foo},
        # and for the hell of it...
        q{q[$urprise]},
    );


    # say *that* ten times fast:
    my $desc = 'invalid invocant options incur exceptions';
    subtest $desc => sub {

        my $use_statement = q{ use Method::Signatures { invocant => q{%HERE} }; };

        # make sure MS always throws an exception when use'd with invocant
        # set to any of the bad values above.
        for my $inv ( @bad_invocants ) {
            (my $use = $use_statement) =~ s/%HERE/$inv/;
            eval $use;
            like $@, qr/Invalid invocant name/, "die when invocant option set to '$inv'";
        }

    };
}

# make sure previously tested classes still work after testing the
# invalid invocants

do_common_subtests(
    class => 'Bar',
    desc  => 'Bar class still works even after testing invalid invocants',
);

do_common_subtests(
    class => 'Self',
    desc  => 'Self class still works even after testing invalid invocants',
);


done_testing;
