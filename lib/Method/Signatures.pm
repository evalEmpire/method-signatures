package Method::Signatures;

use strict;
use warnings;

use Devel::Declare ();
use Data::Alias ();
use Scope::Guard;
use Sub::Name;

our $VERSION = '0.06';


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
provide the invocant as $self.  No more C<my $self = shift>.

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


=head3 Aliased references

A signature of C<\@foo> will take an array reference but allow it to
be used as C<@foo> inside the method.

    package Stuff;
    method foo(\@foo, \@bar) {
        print "Foo:  @foo\n";
        print "Bar:  @bar\n";
    }

    Stuff->foo([1,2,3], [4,5,6]);

=head3 Invocant parameter

The method invocant (ie. C<$self>) can be changed as the first
parameter.  Put a colon after it instead of a comma.

    method foo($class:) {
        $class->bar;
    }

    method stuff($class: $arg, $another) {
        $class->things($arg, $another);
    }

=head3 The C<@_> signature

The @_ signature is a special case which only shifts C<$self>.  It
leaves the rest of C<@_> alone.  This way you can get $self but do the
rest of the argument handling manually.

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
        my $inject = '';

        my $invocant = '$self';
        $invocant = $1 if $proto =~ s{^(.*):\s*}{};
        $inject = "my $invocant = shift; ";

        my @protos = split /\s*,\s*/, $proto;
        for my $idx (0..$#protos) {
            my $proto = $protos[$idx];

            next if $proto eq '@_';

            $inject .= $proto =~ s{^\\}{}x ? alias_proto($proto, $idx)
                     : $proto =~ m{^[@%]}  ? "my($proto) = \@_[$idx..\$#_]; "
                     :                       "my($proto) = \$_[$idx]; ";
        }

#        print STDERR "inject: $inject\n";
        return $inject;
    }

    sub alias_proto {
        my($proto, $idx) = @_;

        $proto =~ s{^ (.) }{}x;
        my $sigil = $1;
        return "Data::Alias::alias(my $sigil$proto = ${sigil}{\$_[$idx]}); ";
    }

    sub inject_if_block {
        my $inject = shift;
        skipspace;
        my $linestr = Devel::Declare::get_linestr;
        if (substr($linestr, $Offset, 1) eq '{') {
            substr($linestr, $Offset+1, 0) = $inject;
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

There is no performance penalty for using this module.


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

=head2 Debugging

This totally breaks the debugger.  Will have to wait on Devel::Declare fixes.

=head2 One liners

If you want to write "use Method::Signatures" in a one-liner, do a
C<-MMethod::Signatures> first.  This is due to a bug in
Devel::Declare.

=head2 No source filter

While this module does rely on the hairy black magic of
L<Devel::Declare> and L<Data::Alias> it does not depend on a source
filter.  As such, it doesn't try to parse and rewrite your source code
and there should be no weird side effects.

Devel::Declare only effects compilation.  After that, it's a normal
subroutine.  As such, for all that hairy magic, this module is
surprisnigly stable.

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

=head2 What about anonymous methods?

...what would an anonymous method do?

=head2 How does this relate to Perl's built-in prototypes?

It doesn't.  Perl prototypes are a rather different beastie from
subroutine signatures.


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

L<Sub::Signatures>, L<Perl6::Subs>

Perl 6 subroutine parameters and arguments -  L<http://perlcabal.org/syn/S06.html#Parameters_and_arguments>

=cut


1;
