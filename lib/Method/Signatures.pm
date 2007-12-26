package Method::Signatures;

use Devel::Declare;

our $VERSION = '0.02';


=head1 NAME

Method::Signatures - method declarations with prototypes and without using a source filter

=head1 SYNOPSIS

    package Foo;
    
    use Method::Signatures;
    
    method new (%args) {
        return bless {%args}, $self;
    };
    
    method get ($key) {
        return $self->{$key};
    };
    
    method set ($key, $val) {
        return $self->{$key} = $val;
    };

=head1 DESCRIPTION

This is B<ALPHA SOFTWARE> which relies on B<YET MORE ALPHA SOFTWARE>.  Use at your own risk.  Features may change.

Provides a proper method keyword, like "sub" but specificly for making methods.  Also a prototype declaration.  Finally it will automatically provide the invocant as $self.  No more C<my $self = shift>.

And it does all this with B<no source filters>.


=head2 Prototype syntax

At the moment the prototypes are very simple.  They simply shift $self and assign @_ to the prototypes like so:

    my(...prototype...) = @_;

No checks are made that the arguments being passed in match the prototype.

Future releases will add extensively to the prototype syntax probably along the lines of Perl 6.

=cut

sub import {
    my $class = shift;
    my $caller = caller;

    # Stolen from Devel::Declare's t/sugar.t
    Devel::Declare->install_declarator(
        $caller, 'method', DECLARE_PACKAGE | DECLARE_PROTO,
        sub {
            my ($name, $proto) = @_;

            my $code = 'my $self = shift;';
            $code   .= " my( $proto ) = \@_;"
                if defined $proto and length $proto and $proto ne '@_';

            return $code;
        },
        sub {
            my ($name, $proto, $sub, @rest) = @_;
            if (defined $name && length $name) {
                unless ($name =~ /::/) {
                    $name = $caller .'::'. $name;
                }
                no strict 'refs';
                *{$name} = $sub;
            }
            return wantarray ? ($sub, @rest) : $sub;
        }
    );
}


=head1 BUGS, CAVEATS and NOTES

Please report bugs and leave feedback at E<lt>bug-Method-SignaturesE<gt> at E<lt>rt.cpan.orgE<gt>.  Or use the web interface at L<http://rt.cpan.org>.  Report early, report often.

=head2 No source filter

While this module does rely on the hairy black magic of L<Devel::Declare> it does not depend on a source filter.  As such, it doesn't try to parse and rewrite your source code and there should be no weird side effects.

=head2 Trailing semicolon

Due to the implementation of L<Devel::Declare>, which really does all the work, a trailing semicolon is required.  If/when this gets fixed in Devel::Declare it will be fixed here.

=head2 What about regular subroutines?

L<Devel::Declare> cannot yet change the way C<sub> behaves.  It's being worked on and when it works I'll release another module unifying method and sub.

=head2 What about class methods?

Right now there's no way to declare method as being a class method, or change the invocant, so the invocant is always $self.  This is just a matter of coming up with the appropriate prototype syntax.  I may simply use the Perl 6 C<($invocant: $arg)> syntax though this doesn't provde type safety.

=head2 What about types?

I would like to add some sort of types in the future or simply make the prototype handler pluggable.

=head2 What about the return value?

Currently there is no support for types or declaring the type of the return value.

=head2 What about anonymous methods?

Working on it.

=head2 Debugging

The inserted prototype code cannot be seen in the debugger.  This is good and bad, but makes it feel more like a language feature.


=head1 LICENSE

The original code was taken from Matt Trout's tests for L<Devel::Declare>.

Copyright 2007 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>


=head1 SEE ALSO

L<Sub::Signatures>, L<Perl6::Subs>

Perl 6 subroutine parameters and arguments -  L<http://perlcabal.org/syn/S06.html#Parameters_and_arguments>

=cut


1;
