package MultipleSlurpy;

use strict;
use warnings;

use Method::Signatures;


# the #line directive helps us guarantee that we'll always know what line number to expect the error
# on, regardless of how much this test module changes
#line 1133
func foo ( @bar, @baz ) {}


1;
