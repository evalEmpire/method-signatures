package Method::Signatures::Modifiers;

use strict;
use warnings;

use constant BASE => 'Method::Signatures';
use base BASE;

use MooseX::Declare ();


sub import
{
    my $meta = MooseX::Declare::Syntax::Keyword::Method->meta;
    $meta->make_mutable();
    $meta->add_around_method_modifier
    (
        parse => sub
        {
            my ($orig, $self, $ctx) = @_;

            my $ms = bless $ctx->_dd_context, BASE;
            # have to sneak the default invocant in there
            $ms->{invocant} = '$self';
            $ms->parser($ms->declarator, $ms->offset);
        }
    );
    $meta->make_immutable();

    $meta = MooseX::Declare::Syntax::Keyword::MethodModifier->meta;
    $meta->make_mutable();
    $meta->add_around_method_modifier
    (
        parse => sub
        {
            my ($orig, $self, $ctx) = @_;

            my $ms = bless $ctx->_dd_context, __PACKAGE__;
            # have to note that this is a method modifier
            $ms->{method_modifier} = 1;
            # have to sneak the default invocant in there
            $ms->{invocant} = '$self';
            # and have to get the $orig in there if it's an around
            $ms->{pre_invocant} = '$orig' if $ms->declarator eq 'around';
            $ms->parser($ms->declarator, $ms->offset);
        }
    );
    $meta->make_immutable();
}


# Generally, the code that calls inject_if_block decides what to put in front of the actual
# subroutine body.  For instance, if it's an anonymous sub, the $before parameter would contain
# "sub ".
sub inject_if_block
{
    my ($self, $inject, $before) = @_;

    $before = 'sub ' unless $before;

    $self->SUPER::inject_if_block($inject, $before);
}


# The code_for routine for Method::Signatures just takes the code from
# Devel::Declare::MethodInstaller::Simple (by calling SUPER::code_for) and uses BeginLift to promote
# that to a compile-time call.  However, we can't do that at all:
#
#   *   The code from DDMIS::code_for creates a sub, which is entirely different from creating a
#       method modifier.  We need all different code.
#
#   *   We can't use BeginLift here, because what it does is cause the method modifier to be created
#       first, before things like "extends" and "with" have had a chance to run.  That means that
#       the method you're trying to create a modifier for might not even exist yet, because it comes
#       from a superclass or role (in fact, that's the most likely case; you don't typically need a
#       modifier on a method in your own class).
#
# So we need a whole different code_for.  We'll need to return a sub which does the following
# things:
#
#   *   Figures out the metaclass of the class we're processing.
#
#   *   Figures out which modifier we're adding (e.g., before, after, around, etc) and then figures
#       out which method to call to add that modifier.
#
#   *   Checks for a few basic errors (unknown type of modifier, modifier to an unknown method).
#
#   *   Adds the modifier.
#
#   *   No BeginLift.
#
# And that's all this code does.
sub code_for
{
    my($self, $name) = @_;
    die("can't create an aonymous method modifier") unless $name;

    my $class = $self->{outer_package};
    my $modtype = $self->declarator;
    my $add = "add_${modtype}_method_modifier";

    my $code = sub
    {
        my $meta = $class->meta;

        require Carp;
        Carp::confess("cannot create method modifier for $modtype") unless $meta->can($add);
        Carp::confess("cannot create $modtype modifier in package $class for non-existent method $name")
                unless $class->can($name);

        no strict 'refs';
        $meta->$add($name => shift);
    };

    return $code;
}


1;
