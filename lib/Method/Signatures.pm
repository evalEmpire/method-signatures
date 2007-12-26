package Method::Signatures;

use Devel::Declare;

our $VERSION = '0.01';

sub import {
    my $class = shift;
    my $caller = caller;

    # Stolen from Devel::Declare's t/sugar.t
    Devel::Declare->install_declarator(
        $caller, 'method', DECLARE_PACKAGE | DECLARE_PROTO,
        sub {
            my ($name, $proto) = @_;
            return 'my $self = shift;' unless defined $proto && $proto ne '@_';
            return 'my ($self'.(length $proto ? ", ${proto}" : "").') = @_;';
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

1;
