
use strict;
use warnings;

use Test::More;

use Method::Signatures;


ok eval q{ my $a = [ func () {}, 1 ]; 1 }, 'anonymous function in list is okay'
        or diag "eval error: $@";

ok eval q{ my $a = [ method () {}, 1 ]; 1 }, 'anonymous method in list is okay'
        or diag "eval error: $@";


done_testing;
