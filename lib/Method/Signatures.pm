package Method::Signatures;

use Devel::Declare;

our $VERSION = '0.01';


=head1 NAME

Method::Signatures - a "method" keyword with proper signatures

=head1 SYNOPSIS

    package Foo;
    
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

=head2 Trailing semicolon

Due to the implementation of L<Devel::Declare>, which really does all the work, a trailing semicolon is required.  If/when this gets fixed in Devel::Declare it will be fixed here.

=head2 What about regular subroutines?

L<Devel::Declare> cannot yet change the way C<sub> behaves.  It's being worked on and when it works I'll release another module unifying method and sub.

=head2 Prototype Syntax

At the moment the prototypes are very simple.  They simply shift $self and assign @_ to the prototypes like so:

    my(...prototype...) = @_;

No checks are made that the arguments being passed in match the prototype.

Future releases will add extensively to the prototype syntax probably along the lines of Perl 6.

=head2 Debugging

The inserted prototype code cannot be seen in the debugger.  This is good and bad, but makes it feel more like a language feature.

=cut


1;
