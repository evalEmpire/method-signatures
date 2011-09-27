
use Test::More;
use Test::Exception;

use lib 't/lib';
use GenErrorRegex qw< badval_error badtype_error >;


# Final test: make sure we can load up our role file which adds method modifiers for methods that
# don't exist.  That's okay for roles, so we need to make sure we're allowing it.
#
# In this case, as long as the module loads okay, we're good.


SKIP:
{
    eval { require MooseX::Declare } or skip "MooseX::Declare required for this test", 1;

    # have to require here or else we try to load MXD before we check for it not being there (above)
    lives_ok { require MS_MXD_Role } "role method modifiers load okay";

}


done_testing();
