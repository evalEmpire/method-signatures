#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Exception;


# This may not be possible.  I'm not sure that Role::Basic and Mouse are going to play nice
# together, and I'm not even sure it's a viable use case.  That is, if you're using
# Method::Signatures, you're already getting Mouse, and, if you're already getting Mouse, why use
# Role::Basic?  Role::Basic's doco itself says that it's designed for people who don't want Mouse
# (or Moose), and, if you don't want Mouse, you might not want to use Method::Signatures, since that
# brings in Mouse whether you like it or not (assuming you're doing type checking, but then, if
# you're not doing type checking, you wouldn't be caring about Role::Basic interaction).
#
# So if we decide we want to pursue this, it may be possible by working with Ovid and creating a
# Mouse subtype to check Role::Basic roles, but in the meantime, I'm just marking this all TODO.
TODO: {
    local $TODO = "Compatibility with Role::Basic unimplemented";


{ package Foo::Bar; sub new { bless {}, __PACKAGE__; } }

SKIP:
{
    eval "use Role::Basic ()";
    skip "Role::Basic required for testing basic roles", 2 if $@;

    require BasicRoleTest;
    use Method::Signatures qw< :TYPES >;

    my $basic = WithBasicRole->new;
    my $foobar = Foo::Bar->new;


    func basicy (BasicRole $foo) {}


    # positive test
    lives_ok { basicy($basic) } 'Basic role passes okay';

    # negative test
    throws_ok { basicy($foobar) } qr/The 'foo' parameter \(.*\) to main::basicy is not of type BasicRole/,
            'Basic role fails when appropriate';
}

}


done_testing;
