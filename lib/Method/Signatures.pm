package Method::Signatures;

use strict;
use warnings;

use Devel::Declare ();
use Scope::Guard;

our $VERSION = '0.04';


=head1 NAME

Method::Signatures - method declarations with prototypes and no source filter

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
methods.  Also a prototype declaration.  Finally it will automatically
provide the invocant as $self.  No more C<my $self = shift>.

And it does all this with B<no source filters>.


=head2 Prototype syntax

At the moment the prototypes are very simple.

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
prototype.

Future releases will add extensively to the prototype syntax probably
along the lines of Perl 6.


=head3 Aliased references

A prototype of C<\@foo> will take an array reference but allow it to
be used as C<@foo> inside the method.

    package Stuff;
    method foo(\@foo, \@bar) {
        print "Foo:  @foo\n";
        print "Bar:  @bar\n";
    }

    Stuff->foo([1,2,3], [4,5,6]);

Currently, this incurs about a 20% performance penalty vs an empty
subroutine call.  But there is no penalty on using the variables.


=head3 The C<@_> prototype

The @_ prototype is a special case which only shifts C<$self>.  It
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
        my $inject = 'my $self = shift; ';
        if (defined $proto and length $proto and $proto ne '@_') {
            my @protos = split /\s*,\s*/, $proto;
            for my $idx (0..$#protos) {
                my $proto = $protos[$idx];

                $inject .= $proto =~ s{^\\}{}x ? do {
                                                     my $glob;  ($glob = $proto) =~ s{^.}{*};
                                                     "our($proto);  local($proto);  ".
                                                     "$glob = \$_[$idx]; "
                                                 }
                         : $proto =~ m{^[@%]}  ? "my($proto) = \@_[$idx..\$#_]; "
                         :                       "my($proto) = \$_[$idx]; ";
            }
        }

#        print STDERR "inject: $inject\n";
        return $inject;
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
            shadow(sub (&) { no strict 'refs'; *{$name} = shift; });
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



=head1 BUGS, CAVEATS and NOTES

Please report bugs and leave feedback at
E<lt>bug-Method-SignaturesE<gt> at E<lt>rt.cpan.orgE<gt>.  Or use the
web interface at L<http://rt.cpan.org>.  Report early, report often.

=head2 Debugging

This totally breaks the debugger.  Will have to wait on Devel::Declare fixes.


=head2 No source filter

While this module does rely on the hairy black magic of
L<Devel::Declare> it does not depend on a source filter.  As such, it
doesn't try to parse and rewrite your source code and there should be
no weird side effects.

Devel::Declare only effects compilation.  After that, it's a normal
subroutine.  As such, for all that hairy magic, this module is
surprisnigly stable.

=head2 What about regular subroutines?

L<Devel::Declare> cannot yet change the way C<sub> behaves.  It's
being worked on and when it works I'll release another module unifying
method and sub.

=head2 What about class methods?

Right now there's no way to declare method as being a class method, or
change the invocant, so the invocant is always $self.  This is just a
matter of coming up with the appropriate prototype syntax.  I may
simply use the Perl 6 C<($invocant: $arg)> syntax though this doesn't
provde type safety.

=head2 What about types?

I would like to add some sort of types in the future or simply make
the prototype handler pluggable.

=head2 What about the return value?

Currently there is no support for types or declaring the type of the
return value.

=head2 What about anonymous methods?

...what would an anonymous method do?


=head1 THANKS

This is really just sugar on top of Matt Trout's work.


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
