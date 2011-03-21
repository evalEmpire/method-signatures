package UnknownType;

use strict;
use warnings;

use InnerUnknownType;


sub bar
{
    my $iut = InnerUnknownType->new;

# the #line directive helps us guarantee that we'll always know what line number to expect the error
# on, regardless of how much this test modules changes
#line 1133
    $iut->foo(42);
}


1;
