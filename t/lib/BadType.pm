package BadType;

use strict;
use warnings;

use InnerBadType;


sub bar
{
    my $iut = InnerBadType->new;

# the #line directive helps us guarantee that we'll always know what line number to expect the error
# on, regardless of how much this test module changes
#line 1133
    $iut->foo('thing');
}


1;
