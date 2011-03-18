#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Warn;
use Test::Exception;

use Method::Signatures;


{ package Foo::Bar; sub new { bless {}, __PACKAGE__; } }
{ package Foo::Baz; sub new { bless {}, __PACKAGE__; } }

our $foobar = Foo::Bar->new;
our $foobaz = Foo::Baz->new;


# types to check below
# the test name needs to be interpolated into a method name, so it must be a valid identifier
# either good value or bad value can be an array reference:
#   *   if it is, it is taken to be multiple values to try
#   *   if you want to pass an array reference, you have to put it inside another array reference
#   *   so, [ 42, undef ] makes two calls: one with 42, and one with undef
#   *   but [[ 42, undef ]] makes one call, passing [ 42, undef ]
our @TYPES =
(
##  Test Name       =>  Type                =>  Good Value                      =>  Bad Value
    int             =>  'Int'               =>  42                              =>  'foo'                               ,
    bool            =>  'Bool'              =>  0                               =>  'fool'                              ,
    aref            =>  'ArrayRef',         =>  [[ 42, undef ]]                 =>  42                                  ,
    class           =>  'Foo::Bar'          =>  $foobar                         =>  $foobaz                             ,
    maybe_int       =>  'Maybe[Int]'        =>  [ 42, undef ]                   =>  'foo'                               ,
    paramized_aref  =>  'ArrayRef[Num]'     =>  [[ 6.5, 42, 1e23 ]]             =>  [[ 6.5, 42, 'thing' ]]              ,
    paramized_href  =>  'HashRef[Num]'      =>  { a => 6.5, b => 2, c => 1e23 } =>  { a => 6.5, b => 42, c => 'thing' } ,
##  ScalarRef[X] not implemented in Mouse, so this test is moved to typeload_moose.t
##  if Mouse starts supporting it, the test could be restored here
#   paramized_sref  =>  'ScalarRef[Num]'    =>  \42                             =>  \'thing'                            ,
    int_or_aref     =>  'Int|ArrayRef[Int]' =>  [ 42 , [42 ] ]                  =>  'foo'                               ,
);


our $tester;
{
    package TypeCheck::Class;

    use strict;
    use warnings;

    use Test::More;
    use Test::Warn;
    use Test::Exception;

    use Method::Signatures;

    method new ($class:) { bless {}, $class; }

    sub _list { return ref $_[0] eq 'ARRAY' ? @{$_[0]} : ( $_[0] ); }
    sub _badval_error
    {
        my ($self, $varname, $type, $val, $method) = @_;
        my $class = ref $self;
        my $error = quotemeta qq{The '$varname' parameter ("$val") to ${class}::$method is not of type $type};
        return qr/$error/;
    }
    sub _badtype_error
    {
        my ($self, $type, $submsg, $method) = @_;
        my $class = ref $self;
        my $error = quotemeta qq{The type $type is unrecognized ($submsg)};
        return qr/$error/;
    }


    $tester = __PACKAGE__->new;
    while (@TYPES)
    {
        my ($name, $type, $goodval, $badval) = splice @TYPES, 0, 4;
        note "name/type/goodval/badval $name/$type/$goodval/$badval";
        my $method = "check_$name";
        no strict 'refs';

        # make sure the declaration of the method doesn't throw a warning
        warning_is { eval qq{ method $method ($type \$bar) {} } } undef, "no warnings from declaring $name param";

        # positive test--can we call it with a good value?
        my @vals = _list($goodval);
        my $count = 1;
        foreach (@vals)
        {
            my $tag = @vals ? ' (alternative ' . $count++ . ')' : '';
            lives_ok { $tester->$method($_) } "call with good value for $name passes" . $tag;
        }

        # negative test--does calling it with a bad value throw an exception?
        @vals = _list($badval);
        $count = 1;
        foreach (@vals)
        {
            my $tag = @vals ? ' (#' . $count++ . ')' : '';
            throws_ok { $tester->$method($_) } $tester->_badval_error(bar => $type, $_, $method),
                    "call with bad value for $name dies";
        }
    }


    # try some mixed (i.e. some with a type, some without) and multiples

    my $method = 'check_mixed_type_first';
    warning_is { eval qq{ method $method (Int \$bar, \$baz) {} } } undef, 'no warnings (type, notype)';
    lives_ok { $tester->$method(0, 'thing') } 'call with good values (type, notype) passes';
    throws_ok { $tester->$method('thing1', 'thing2') } $tester->_badval_error(bar => Int => thing1 => $method),
            'call with bad values (type, notype) dies';

    $method = 'check_mixed_type_second';
    warning_is { eval qq{ method $method (\$bar, Int \$baz) {} } } undef, 'no warnings (notype, type)';
    lives_ok { $tester->$method('thing', 1) } 'call with good values (notype, type) passes';
    throws_ok { $tester->$method('thing1', 'thing2') } $tester->_badval_error(baz => Int => thing2 => $method),
            'call with bad values (notype, type) dies';

    $method = 'check_multiple_types';
    warning_is { eval qq{ method $method (Int \$bar, Int \$baz) {} } } undef, 'no warnings when type loaded';
    lives_ok { $tester->$method(1, 1) } 'call with good values (type, type) passes';
    # with two types, and bad values for both, they should fail in order of declaration
    throws_ok { $tester->$method('thing1', 'thing2') } $tester->_badval_error(bar => Int => thing1 => $method),
            'call with bad values (type, type) dies';

    # want to try one with undef as well to make sure we don't get an uninitialized warning

    warning_is { eval { $tester->check_int(undef) } } undef, 'no warning for undef value in type checking';
    like $@, qr/The 'bar' parameter \(undef\) to TypeCheck::Class::check_int is not of type Int/,
            'call with undefined Int arg is okay';


    # finally, some types that shouldn't be recognized
    my $type;

    $method = 'unknown_type';
    $type = 'Bmoogle';
    warning_is { eval qq{ method $method ($type \$bar) {} } } undef, 'no warnings when weird type loaded';
    throws_ok { $tester->$method(42) } $tester->_badtype_error($type, "perhaps you forgot to load it?", $method),
            'call with unrecognized type dies';

    # this one is a bit specialer in that it involved an unrecognized parameterization
    $method = 'unknown_paramized_type';
    $type = 'Bmoogle[Int]';
    warning_is { eval qq{ method $method ($type \$bar) {} } } undef, 'no warnings when weird paramized type loaded';
    throws_ok { $tester->$method(42) } $tester->_badtype_error($type, "looks like it doesn't parse correctly", $method),
            'call with unrecognized paramized type dies';

}


done_testing;
