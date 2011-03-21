#!perl

use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Carp ();

ok !eval { require Bad };
TODO: {
    local $TODO = "The user should see the actual syntax error";
    like $@, qr{^Global symbol "\$info" requires explicit package name}ms;

    like($@, qr{^PPI failed to find statement for '\$bar'}ms,
         'Bad syntax generates stack trace');
}

done_testing();
