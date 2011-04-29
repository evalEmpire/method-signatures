package ModifierBadType;

use strict;
use warnings;

# reusing this from t/mxd-replace.t
use MS_MXD_Replace;


sub bar
{
    my ($meth) = @_;
    my $foobar = Foo::Bar->new;
    no strict 'refs';

# the #line directive helps us guarantee that we'll always know what line number to expect the error
# on, regardless of how much this test module changes
#line 1133
    $foobar->$meth('thing');
}


1;
