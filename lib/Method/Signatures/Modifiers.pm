package Method::Signatures::Modifiers;

use strict;
use warnings;

use Sub::Name;

use base 'Method::Signatures';

our $VERSION = '20120523';


=head1 NAME

Method::Signatures::Modifiers - use Method::Signatures from within MooseX::Declare

=head1 SYNOPSIS

    use MooseX::Declare;
    use Method::Signatures::Modifiers;

    class Foo
    {
        method bar (Int $thing) {
            # this method is declared with Method::Signatures instead of MooseX::Method::Signatures
        }
    }

    # -- OR --

    use MooseX::Declare;

    class My::Declare extends MooseX::Declare
    {
        use Method::Signatures::Modifiers;
    }

    # ... later ...

    use My::Declare;

    class Fizz
    {
        method baz (Int $thing) {
            # this method also declared with Method::Signatures instead of MooseX::Method::Signatures
        }
    }

=head1 DESCRIPTION

Allows you to use L<Method::Signatures> from within
L<MooseX::Declare>, both for the C<method> keyword and also for any
method modifiers (C<before>, C<after>, C<around>, C<override>, and
C<augment>).  Typically method signatures within L<MooseX::Declare>
are provided by L<MooseX::Method::Signatures>.  Using
L<Method::Signatures> instead provides several advantages:

=over 4

=item * L<MooseX::Method::Signatures> has a known bug with Perl 5.12.x
which does not plague L<Method::Signatures>.

=item * L<Method::Signatures> may provide substantially better
performance when calling methods, depending on your circumstances.

=item * L<Method::Signatures> error messages are somewhat easier to
read (and can be overridden more easily).

=back

However, L<Method::Signatures> cannot be considered a drop-in
replacement for L<MooseX::Method::Signatures>.  Specifically, the
following features of L<MooseX::Method::Signatures> are not available
to you (or work differently) if you substitute L<Method::Signatures>:


=head3 Types for Invocants

L<MooseX::Method::Signatures> allows code such as this:

    method foo (ClassName $class: Int $bar) {
    }

L<Method::Signatures> does not allow you to specify a type for the
invocant, so your code would change to:

    method foo ($class: Int $bar) {
    }


=head3 "where" Constraints

L<MooseX::Method::Signatures> allows code like this:

    # only allow even integers
    method foo (Int $bar where { $_ % 2 == 0 }) {
    }

L<Method::Signatures> does not currently allow this, although it is a
planned feature for a future release.


=head3 Parameter Aliasing (Labels)

L<MooseX::Method::Signatures> allows code like this:

    # call this as $obj->foo(bar => $baz)
    method foo (Int :bar($baz)) {
    }

This feature is not currently planned for L<Method::Signatures>.


=head3 Placeholders

L<MooseX::Method::Signatures> allows code like this:

    method foo (Int $bar, $, Int $baz)) {
        # second parameter not available as a variable here
    }

This feature is not currently planned for L<Method::Signatures>.


=head3 Traits

In L<MooseX::Method::Signatures>, C<does> is a synonym for C<is>.
L<Method::Signatures> does not honor this.

L<Method::Signatures> supports several traits that
L<MooseX::Method::Signatures> does not.

L<MooseX::Method::Signatures> supports the C<coerce> trait.
L<Method::Signatures> does not currently support this, although it is
a planned feature for a future release, potentially using the C<does
coerce> syntax.


=cut


sub import
{
    my ($class) = @_;

    # intercept the parse() method that handles the 'method' keyword
    require MooseX::Declare::Syntax::Keyword::Method;
    my $meta = MooseX::Declare::Syntax::Keyword::Method->meta;
    $meta->make_mutable();
    $meta->add_around_method_modifier
    (
        parse => sub
        {
            my ($orig, $self, $ctx) = @_;

            # have to rebless the MooseX::Declare::Context's Devel::Declare::Context::Simple object into our class
            # since we're ultimately descended from DDCS, this should work
            my $ms = bless $ctx->_dd_context, $class;
            # have to sneak the default invocant in there
            $ms->{invocant} = '$self';
            # this sets some things in $ms that were already set, but that's pretty much unavoidable
            $ms->parser($ms->declarator, $ms->offset);
        }
    );
    $meta->make_immutable();

    # intercept the parse() method that handles method modifiers
    require MooseX::Declare::Syntax::Keyword::MethodModifier;
    $meta = MooseX::Declare::Syntax::Keyword::MethodModifier->meta;
    $meta->make_mutable();
    $meta->add_around_method_modifier
    (
        parse => sub
        {
            my ($orig, $self, $ctx) = @_;

            # have to rebless the MooseX::Declare::Context's Devel::Declare::Context::Simple object into our class
            # since we're ultimately descended from DDCS, this should work
            my $ms = bless $ctx->_dd_context, $class;
            # have to sneak the default invocant in there
            $ms->{invocant} = '$self';
            # and have to let code_for() know this is a modifier
            $ms->{is_modifier} = 1;
            # and have to get the $orig in there if it's an around
            $ms->{pre_invocant} = '$orig' if $ms->declarator eq 'around';
            # this sets some things in $ms that were already set, but that's pretty much unavoidable
            $ms->parser($ms->declarator, $ms->offset);
        }
    );
    $meta->make_immutable();
}


# The code_for routine for Method::Signatures just takes the code from
# Devel::Declare::MethodInstaller::Simple (by calling SUPER::code_for) and uses BeginLift to promote
# that to a compile-time call.  However, for modifiers, we can't do that at all:
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
#   *   Checks for basic errors (such as unknown type of modifier).
#
#   *   Adds the modifier.
#
#   *   No BeginLift.
#
#   *   If it's _not_ for a modifier, just fall through to code_for() in Method::Signatures.
#
# And that's all this code does.
sub code_for
{
    my($self, $name) = @_;

    if ($self->{is_modifier})
    {
        die("can't create an aonymous method modifier") unless $name;

        my $class = $self->{outer_package};
        my $modtype = $self->declarator;
        my $add = "add_${modtype}_method_modifier";

        my $code = sub
        {
            my $meta = $class->meta;

                require Carp;
            Carp::confess("cannot create method modifier for $modtype") unless $meta->can($add);

            no strict 'refs';
            my $code = subname "${class}::$name" => shift;
            $meta->$add($name => $code);
        };

        return $code;
    }
    else
    {
        return $self->SUPER::code_for($name);
    }
}


# Generally, the code that calls inject_if_block decides what to put in front of the actual
# subroutine body.  For instance, if it's an anonymous sub, the $before parameter would contain
# "sub ".  In our case, we need the "sub " all the time.
sub inject_if_block
{
    my ($self, $inject, $before) = @_;

    $before = 'sub ' unless $before;

    $self->SUPER::inject_if_block($inject, $before);
}


=head1 BUGS, CAVEATS and NOTES

Note that although this module causes all calls to
L<MooseX::Method::Signatures> from within L<MooseX::Declare> to be
completely I<replaced> by calls to L<Method::Signatures> (or calls to
Method::Signatures::Modifiers), L<MooseX::Method::Signatures> is still
I<loaded> by L<MooseX::Declare>.  It's just never used.

The C<compile_at_BEGIN> flag to L<Method::Signatures> is ignored by
Method::Signatures::Modifiers.  This is because parsing at
compile-time can cause method modifiers to be added before the methods
they are modifying are composed into the Moose classes.  Parsing of
methods at run-time is compatible with L<MooseX::Method::Signatures>.


=head1 THANKS

This code was written by Buddy Burden (barefootcoder).

The import code for replacing L<MooseX::Method::Signatures> is based
on a suggestion from Nick Perez.


=head1 LICENSE

Copyright 2011 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>


=head1 SEE ALSO

L<MooseX::Declare>, L<Method::Signatures>, L<MooseX::Method::Signatures>.


=cut


1;
