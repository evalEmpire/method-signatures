package NoTypes;

use strict;
use warnings;

use Method::Signatures;                                                 # note lack of :TYPES here


# the #line directive helps us guarantee that we'll always know what line number to expect the error
# on, regardless of how much this test modules changes
#line 1133
func foo ( Int $bar ) {}


1;
