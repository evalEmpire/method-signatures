package Method::Signatures;

use strict;
use warnings;

use Devel::Declare ();
use Data::Alias ();
use Scope::Guard;
use Sub::Name;

our $VERSION = '0.12';


=head1 NAME

Method::Signatures - method declarations with signatures and no source filter

=head1 SYNOPSIS

    package Foo;
    
    use Method::Signatures;
    
    method new (%args) {
        return bless {%args}, $self;
    }
    
    method get ($key) {
        return $self->{$key};
    }
    
    method set ($key, $val) {
        return $self->{$key} = $val;
    }

=head1 DESCRIPTION

This is B<ALPHA SOFTWARE> which relies on B<YET MORE ALPHA SOFTWARE>.
Use at your own risk.  Features may change.

Provides a proper method keyword, like "sub" but specificly for making
methods.  Also allows signatures.  Finally it will automatically
provide the invocant as C<$self>.  No more C<my $self = shift>.

And it does all this with B<no source filters>.


=head2 Signature syntax

At the moment the signatures are very simple.

    method foo($bar, $baz) {
        $self->wibble($bar, $baz);
    }

is equivalent to:

    sub foo {
        my $self = shift;
        my($bar, $baz) = @_;
        $self->wibble($bar, $baz);
    }

except the original line numbering is preserved.

No checks are made that the arguments being passed in match the
signature.

Future releases will add extensively to the signature syntax probably
along the lines of Perl 6.

=head3 C<@_>

Other than removing C<$self>, C<@_> is left intact.  You are free to
use C<@_> alongside the arguments provided by Method::Signatures.


=head3 Aliased references

A signature of C<\@arg> will take an array reference but allow it to
be used as C<@arg> inside the method.  C<@arg> is an alias to the
original reference.  Any changes to C<@arg> will effect the original
reference.

    package Stuff;
    method add_one(\@foo) {
        $_++ for @foo;
    }

    my @bar = (1,2,3);
    Stuff->add_one(\@bar);  # @bar is now (2,3,4)


=head3 Invocant parameter

The method invocant (ie. C<$self>) can be changed as the first
parameter.  Put a colon after it instead of a comma.

    method foo($class:) {
        $class->bar;
    }

    method stuff($class: $arg, $another) {
        $class->things($arg, $another);
    }

Signatures have an implied default of C<$self:>.


=head3 Defaults

Each parameter can be given a default with the C<$arg = EXPR> syntax.
For example,

    method add($this = 23, $that = 42) {
        return $this + $that;
    }

Defaults will only be used if the argument is not passed in at all.
Passing in C<undef> will override the default.  That means...

    Class->add();            # $this = 23, $that = 42
    Class->add(99);          # $this = 99, $that = 42
    Class->add(99, undef);   # $this = 99, $that = undef

Earlier parameters may be used in later defaults.

    method copy_cat($this, $that = $this) {
        return $that;
    }

All variables with defaults are considered optional.


=head3 Parameter traits

Each parameter can be assigned a trait with the C<$arg is TRAIT> syntax.

    method stuff($this is ro) {
        ...
    }

Any unknown trait is ignored.

Currently there are no traits.  It's for forward compatibility.


=head3 Traits and defaults

To have a parameter which has both a trait and a default, set the
trait first and the default second.

    method echo($message is ro = "what?") {
        return $message
    }

Think of it as C<$message is ro> being the left-hand side of the assignment.


=head3 Optional parameters

To declare a parameter optional, use the C<$arg?> syntax.

Currently nothing is done with this.  It's for forward compatibility.


=head3 Required parameters

To declare a parameter as required, use the C<$arg!> syntax.

All parameters without defaults are required by default.


=head3 The C<@_> signature

The @_ signature is a special case which only shifts C<$self>.  It
leaves the rest of C<@_> alone.  This way you can get $self but do the
rest of the argument handling manually.


=head2 Anonymous Methods

An anonymous method can be declared just like an anonymous sub.

    my $method = method ($arg) {
        return $self->foo($arg);
    };

    $obj->$method(42);


=cut

sub import {
    my $class = shift;
    my $caller = caller;

    Devel::Declare->setup_for(
        $caller,
        { method => { const => \&parser } }
    );

    # I don't really understand why we need to declare method
    # in the caller's namespace.
    no strict 'refs';
    *{$caller.'::method'} = sub (&) {};
}


# Stolen from Devel::Declare's t/method-no-semi.t
{
    our ($Declarator, $Offset);

    sub skip_declarator {
        $Offset += Devel::Declare::toke_move_past_token($Offset);
    }

    sub skipspace {
        $Offset += Devel::Declare::toke_skipspace($Offset);
    }

    sub strip_name {
        skipspace;
        if (my $len = Devel::Declare::toke_scan_word($Offset, 1)) {
            my $linestr = Devel::Declare::get_linestr();
            my $name = substr($linestr, $Offset, $len);
            substr($linestr, $Offset, $len) = '';
            Devel::Declare::set_linestr($linestr);
            return $name;
        }
        return;
    }

    sub strip_proto {
        skipspace;
    
        my $linestr = Devel::Declare::get_linestr();
        if (substr($linestr, $Offset, 1) eq '(') {
            my $length = Devel::Declare::toke_scan_str($Offset);
            my $proto = Devel::Declare::get_lex_stuff();
            Devel::Declare::clear_lex_stuff();
            $linestr = Devel::Declare::get_linestr();
            substr($linestr, $Offset, $length) = '';
            Devel::Declare::set_linestr($linestr);
            return $proto;
        }
        return;
    }

    sub shadow {
        my $pack = Devel::Declare::get_curstash_name;
        Devel::Declare::shadow_sub("${pack}::${Declarator}", $_[0]);
    }

    sub make_proto_unwrap {
        my ($proto) = @_;
        $proto ||= '';

        # Do all the signature parsing here
        my %signature;
        $signature{invocant} = '$self';
        $signature{invocant} = $1 if $proto =~ s{^(.*):\s*}{};

        my @protos = split /\s*,\s*/, $proto;
        for my $idx (0..$#protos) {
            my $sig = $signature{$idx} = {};
            my $proto = $protos[$idx];

#            print STDERR "proto: $proto\n";

            $sig->{proto}               = $proto;
            $sig->{idx}                 = $idx;
            $sig->{is_at_underscore}    = $proto eq '@_';
            $sig->{is_ref_alias}        = $proto =~ s{^\\}{}x;

            $sig->{trait}   = $1 if $proto =~ s{ \s+ is \s+ (\S+) \s* }{}x;
            $sig->{default} = $1 if $proto =~ s{ \s* = \s* (.*) }{}x;

            my($sigil, $name) = $proto =~ m{^ (.)(.*) }x;
            $sig->{is_optional} = ($name =~ s{\?$}{} or $sig->{default});
            $sig->{is_required} = ($name =~ s{\!$}{} or !$sig->{is_optional});
            $sig->{sigil}       = $sigil;
            $sig->{name}        = $name;
        }

        # XXX At this point we could do sanity checks

        # Then turn it into Perl code
        my $inject = inject_from_signature(\%signature);
#        print STDERR "inject: $inject\n";

        return $inject;
    }

    # Turn the parsed signature into Perl code
    sub inject_from_signature {
        my $signature = shift;

        my @code;
        push @code, "my $signature->{invocant} = shift;";
        
        for( my $idx = 0; my $sig = $signature->{$idx}; $idx++ ) {
            next if $sig->{is_at_underscore};

            my $sigil = $sig->{sigil};
            my $name  = $sig->{name};

            # These are the defaults.
            my $lhs = "my ${sigil}${name}";
            my $rhs = (!$sig->{is_ref_alias} and $sig->{sigil} =~ /^[@%]$/) ? "\@_[$idx..\$#_]" : "\$_[$idx]";

            # Handle a default value
            $rhs = "(\@_ > $idx) ? ($rhs) : ($sig->{default})" if defined $sig->{default};

            # XXX We don't do anything with traits right now

            # XXX is_optional is ignored

            # Handle \@foo
            if( $sig->{is_ref_alias} ) {
                push @code, sprintf 'Data::Alias::alias(%s = %s);', $lhs, $sigil."{$rhs}";
            }
            else {
                push @code, "$lhs = $rhs;";
            }
        }

        # All on one line.
        return join ' ', @code;
    }

    sub inject_if_block {
        my $inject = shift;
        skipspace;
        my $linestr = Devel::Declare::get_linestr;

        my $attrs   = '';

        if (substr($linestr, $Offset, 1) eq ':') {
            while (substr($linestr, $Offset, 1) ne '{') {
                if (substr($linestr, $Offset, 1) eq ':') {
                    substr($linestr, $Offset, 1) = '';
                    Devel::Declare::set_linestr($linestr);

                    $attrs .= ' :';
                }

                skipspace;
                $linestr = Devel::Declare::get_linestr();

                if (my $len = Devel::Declare::toke_scan_word($Offset, 0)) {
                    my $name = substr($linestr, $Offset, $len);
                    substr($linestr, $Offset, $len) = '';
                    Devel::Declare::set_linestr($linestr);

                    $attrs .= " ${name}";

                    if (substr($linestr, $Offset, 1) eq '(') {
                        my $length = Devel::Declare::toke_scan_str($Offset);
                        my $arg    = Devel::Declare::get_lex_stuff();
                        Devel::Declare::clear_lex_stuff();
                        $linestr = Devel::Declare::get_linestr();
                        substr($linestr, $Offset, $length) = '';
                        Devel::Declare::set_linestr($linestr);

                        $attrs .= "(${arg})";
                    }
                }
            }

            $linestr = Devel::Declare::get_linestr();
        }

        if (substr($linestr, $Offset, 1) eq '{') {
            substr($linestr, $Offset + 1, 0) = $inject;
            substr($linestr, $Offset, 0) = "sub ${attrs}";
            Devel::Declare::set_linestr($linestr);
        }

    }

    sub scope_injector_call {
        return ' BEGIN { Method::Signatures::inject_scope }; ';
    }

    sub parser {
        local ($Declarator, $Offset) = @_;
        skip_declarator;
        my $name = strip_name;
        my $proto = strip_proto;
        my $inject = make_proto_unwrap($proto);
        if (defined $name) {
            $inject = scope_injector_call().$inject;
        }
        inject_if_block($inject);
        if (defined $name) {
            $name = join('::', Devel::Declare::get_curstash_name(), $name)
              unless ($name =~ /::/);
            shadow(sub (&) {
                no strict 'refs';
                # So caller() gets the subroutine name
                *{$name} = subname $name => shift;
            });
        } else {
            shadow(sub (&) { shift });
        }
    }

    sub inject_scope {
        $^H |= 0x120000;
        $^H{DD_METHODHANDLERS} = Scope::Guard->new(sub {
            my $linestr = Devel::Declare::get_linestr;
            my $offset = Devel::Declare::get_linestr_offset;
            substr($linestr, $offset, 0) = ';';
            Devel::Declare::set_linestr($linestr);
        });
    }
}


=head1 PERFORMANCE

There is no run-time performance penalty for using this module.


=head1 EXPERIMENTING

If you want to experiment with the prototype syntax, replace
C<Method::Signatures::make_proto_unwrap>.  It takes a method prototype
and returns a string of Perl 5 code which will be placed at the
beginning of that method.

This interface is experimental, unstable and will change between
versions.


=head1 BUGS, CAVEATS and NOTES

Please report bugs and leave feedback at
E<lt>bug-Method-SignaturesE<gt> at E<lt>rt.cpan.orgE<gt>.  Or use the
web interface at L<http://rt.cpan.org>.  Report early, report often.

=head2 C<method> is not declared at compile time.

Unlike declaring a C<sub>, C<method> currently does not happen at
compile time.  This usually isn't a problem.  It may change, but it
may be a good thing.

=head2 Debugging

This totally breaks the debugger.  Will have to wait on Devel::Declare fixes.

=head2 One liners

If you want to write "use Method::Signatures" in a one-liner, do a
C<-MMethod::Signatures> first.  This is due to a bug/limitation in
Devel::Declare.

=head2 No source filter

While this module does rely on the hairy black magic of
L<Devel::Declare> and L<Data::Alias> it does not depend on a source
filter.  As such, it doesn't try to parse and rewrite your source code
and there should be no weird side effects.

Devel::Declare only effects compilation.  After that, it's a normal
subroutine.  As such, for all that hairy magic, this module is
surprisingly stable.

=head2 What about regular subroutines?

L<Devel::Declare> cannot yet change the way C<sub> behaves.  It's
being worked on and when it works I'll release another module unifying
method and sub.

=head2 What about class methods?

Right now there's nothing special about class methods.  Just use
C<$class> as your invocant like the normal Perl 5 convention.

There may be special syntax to separate class from object methods in
the future.

=head2 What about types?

I would like to add some sort of types in the future or simply make
the signature handler pluggable.

=head2 What about the return value?

Currently there is no support for types or declaring the type of the
return value.

=head2 How does this relate to Perl's built-in prototypes?

It doesn't.  Perl prototypes are a rather different beastie from
subroutine signatures.

=head2 What about...

Named parameters are in the pondering stage.

Read-only parameters and aliasing will probably be supported with
C<$arg is ro> and C<$arg is alias> respectively, mirroring Perl 6.

Method traits are in the pondering stage.

An API to query a method's signature is in the pondering stage.

Now that we have method signatures, multi-methods are a distinct possibility.


=head1 THANKS

This is really just sugar on top of Matt Trout's L<Devel::Declare> work.

Also thanks to Matthijs van Duin for his awesome L<Data::Alias> which
makes the C<\@foo> signature work perfectly and L<Sub::Name> which
makes the subroutine names come out right in caller().


=head1 LICENSE

The original code was taken from Matt S. Trout's tests for L<Devel::Declare>.

Copyright 2007-2008 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>


=head1 SEE ALSO

L<MooseX::Method::Signatures>, L<Perl6::Signature>, L<Sub::Signatures>, L<Perl6::Subs>

Perl 6 subroutine parameters and arguments -  L<http://perlcabal.org/syn/S06.html#Parameters_and_arguments>

=cut


1;
