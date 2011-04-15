# For use with t/error_interruption.t

package BarfyDie;

use strict;
use warnings;

use Method::Signatures;


# This _should_ produce a simple error like the following:
# Global symbol "$foo" requires explicit package name at t/lib/BarfyDie.pm line 13.
$foo = 'hi!';

# And, without the signature below, it would.
# For that matter, if you compile this by itself, it still does.
# However, when you require this file from inside an eval, Method::Signature's parser() method will
# eat the error unless we localize $@ there.  So this verifies that we're doing that.

method foo (Str $bar)
{
}


1;
