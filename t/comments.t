
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


TODO: {
    local $TODO = "closing paren in comment: rt.cpan.org 81364";

    lives_ok
    {
        # When this fails, it produces 'Variable "$bar" is not imported'
        # This is expected to fail, don't bother the user.
        no warnings;
        eval q{
            func special_comment (
                $foo, # )
                $bar
            )
            { 42 }
            1;
        } or die;
    }
    'closing paren in comment';
    is eval q[special_comment("this", "that")], 42;
}

done_testing();
