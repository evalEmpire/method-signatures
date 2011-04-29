
use strict;
use warnings;

use Test::More;
use Test::Exception;

use Method::Signatures;


lives_ok
{
    eval q{
        func foo (
            Int :$foo,              # this is foo
            Int :$bar               # this is bar
        )
        {
        }

        1;
    } or die;
}
'survives comments within the signature itself';

lives_ok
{
    eval q{
        func bar ( Int :$foo, Int :$bar )       # this is a signature
        {
        }

        1;
    } or die;
}
'survives comments between signature and open brace';

SKIP:
{
    eval { require MooseX::Declare } or skip "MooseX::Declare required for this test", 1;

    lives_ok
    {
        eval q{
            use MooseX::Declare;
            use Method::Signatures::Modifiers;

            class Foo
            {
                method bar ( Int :$foo, Int :$bar )     # this is a signature
                {
                }
            }

            1;
        } or die;
    }
    'survives comments between signature and open brace';
}


done_testing();
