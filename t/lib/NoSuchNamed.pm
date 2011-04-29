package NoSuchNamed;

use strict;
use warnings;

use InnerNoSuchNamed;


sub bar
{
    my $insn = InnerNoSuchNamed->new;

# the #line directive helps us guarantee that we'll always know what line number to expect the error
# on, regardless of how much this test module changes
#line 1133
    $insn->foo( bmoogle => 1 );
}


1;
