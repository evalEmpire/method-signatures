#!perl

use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Carp ();

eval { require Bad };
like($@, qr/^Failed to find statement at/,
  'Bad syntax generates stack trace');

done_testing();
