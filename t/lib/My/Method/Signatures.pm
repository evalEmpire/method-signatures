package My::Method::Signatures;

use base 'Method::Signatures';

sub signature_error_handler {
    my ($class, $msg) = @_;
    die bless { message => $msg }, 'My::ExceptionClass';
}

1;
