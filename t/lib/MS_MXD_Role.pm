# used by t/mxd-role.t

use MooseX::Declare;
use Method::Signatures::Modifiers;


# Unlike classes, roles don't need to actually _have_ to have the methods they're modifying.  This
# particular test file is less about making sure we're properly substituting and more about making
# sure we're not blowing up.  Our original version of MSM::code_for was a bit too agressive in its
# error checking and disallowed some role method modifiers that it shouldn't have.
#
# No need to test 'augment' because that isn't allowed in roles.
role Foo
{
    # attribute with modifiers
    has foo => ( is => 'ro' );

    before foo () {}
    after foo () {}

    # "naked" modifiers

    before test_before () {}

    around test_around () {}

    after test_after () {}

    override test_override () {}
}


1;
