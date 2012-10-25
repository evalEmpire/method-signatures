#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Warn;
use Test::Exception;

use Method::Signatures;

plan tests => 4;


SKIP:
{
    skip "Perl 5.10 or higher required to test block defaults", 3 if $] < 5.010;

    eval
    q{
        subtest 'where { block() }' => sub {
            plan tests => 3;

            func small_int (Maybe[Int] $x where { $_ < 10 } is copy = 0 when undef) {
                ok defined $x, "small_int($x) has defined value";
                ok $x < 10, "small_int($x) has value in range";
                return 1;
            }

            subtest "small_int()" => sub {
                ok  eval{ small_int();  }, "small_int() called as expected"
                    or note $@;
            };

            subtest "small_int(9)" => sub {
                ok  eval{ small_int(9); }, "small_int(9) called as expected"
                    or note $@;
            };

            subtest "small_int(10)" => sub {
                ok !eval{ small_int(10);}, "small_int(10) not called (as expected)";
                note $@;
            };
        };


        subtest 'where [0..10]' => sub {
            plan tests => 4;

            func range_int (Maybe[Int] $x where [0..9] is copy = 0 when undef) {
                ok defined $x, "range_int($x) has defined value";
                ok 0 <= $x && $x <= 9, "range_int($x) has value in range";
                return 1;
            }

            subtest "range_int()" => sub {
                ok  eval{ range_int();  }, "range_int() called as expected"
                    or note $@;
            };

            subtest "range_int(9)" => sub {
                ok  eval{ range_int(9); }, "range_int(9) called as expected"
                    or note $@;
            };

            subtest "range_int(10)" => sub {
                ok !eval{ range_int(10);}, "range_int(10) not called (as expected)";
                note $@;
            };

            subtest "range_int(-1)" => sub {
                ok !eval{ range_int(-1);}, "range_int(10) not called (as expected)";
                note $@;
            };
        };


        subtest 'where { cat => 1, dog => 2}' => sub {
            plan tests => 4;

            func hash_member (Maybe[Str] $x where { cat => 1, dog => 2 } is copy = 'cat' when undef) {
                ok defined $x, "hash_member($x) has defined value";
                like $x, qr{^(cat|dog)$} , "hash_member($x) has value in range";
                return 1;
            }

            subtest "hash_member()" => sub {
                ok  eval{ hash_member();  }, "hash_member() called as expected"
                    or note $@;
            };

            subtest "hash_member('cat')" => sub {
                ok  eval{ hash_member('cat'); }, "hash_member('cat') called as expected"
                    or note $@;
            };

            subtest "hash_member('dog')" => sub {
                ok  eval{ hash_member('dog'); }, "hash_member('dog') called as expected"
                    or note $@;
            };

            subtest "hash_member('fish')" => sub {
                ok !eval{ hash_member('fish');}, "hash_member('fish') not called (as expected)";
                note $@;
            };
        };
    };
    fail "can't run tests: $@" if $@;
}



if ($] < 5.010)
{
    eval
    q{
        func neg_and_odd_and_prime ($x where [0..10]) {
            return 1;
        }
    };

    like $@, qr{\Q'where' constraint only available under Perl 5.10 or later.\E},
            "Perls <5.10 properly error out on where constraints";
}
else
{
    eval
    q{
        subtest 'where where where' => sub {
            plan tests => 14;

            func is_prime ($x) {
                return $x ~~ [2,3,5,7,11];
            }

            func neg_and_odd_and_prime ($x where [0..10] where { $x % 2 } where \&is_prime ) {
                ok $x ~~ [3,5,7], '$x had acceptable value';
                return 1;
            }

            for my $n (-1..11) {
                subtest "neg_and_odd_and_prime($n)" => sub {
                    local $@;
                    my $result = eval{ neg_and_odd_and_prime($n); };
                    my $error  = $@;

                    if (defined $result) {
                        pass "neg_and_odd_and_prime($n) as expected";
                    }
                    else {
                        like $error, qr{\$x value \("$n"\) does not satisfy constraint:}
                            => "neg_and_odd_and_prime($n) as expected";
                        note $@;
                    }
                };
            }

            # try an undef value
            my $result = eval{ neg_and_odd_and_prime(undef); };
            like $@, qr{\$x value \(undef\) does not satisfy constraint:}, "neg_and_odd_and_prime(undef) as expected";

        };
    };
    fail "can't run tests: $@" if $@;
}
