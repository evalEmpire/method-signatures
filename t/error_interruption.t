
use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Exception;


TODO: {
    local $TODO;
    $TODO = 'Older Perls have trouble with this' if $] < 5.010001;

    throws_ok { require BarfyDie }
      qr/requires explicit package name/,
      "MS doesn't interrupt real compilation error";
}


done_testing();
