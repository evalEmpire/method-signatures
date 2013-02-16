#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use My::Method::Signatures { compile_at_BEGIN => 0 };

func no_sig { return @_ }

note "signature_error_handler"; {
    ok !eval { no_sig(42); 1 }, "no args";
    my $exception = $@;
    isa_ok($exception, 'My::ExceptionClass');
    my $msg = $exception->{message};
    like $msg, qr{no_sig\(\).*given too many arguments.*it expects 0};
}

done_testing;
