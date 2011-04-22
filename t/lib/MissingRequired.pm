package MissingRequired;

use strict;
use warnings;

use InnerMissingRequired;


sub bar
{
    my $imr = InnerMissingRequired->new;

# the #line directive helps us guarantee that we'll always know what line number to expect the error
# on, regardless of how much this test module changes
#line 1133
    $imr->foo();
}


1;
