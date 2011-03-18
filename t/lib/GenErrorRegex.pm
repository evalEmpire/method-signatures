package GenErrorRegex;

use base qw< Exporter >;
our @EXPORT_OK = qw< badval_error badtype_error >;


sub _regexify
{
    my ($obj, $method, $msg) = @_;
    my $class = ref $obj || $obj || 'main';

    my $error = quotemeta "In call to ${class}::$method : $msg";
    return qr/$error/;
}


sub badval_error
{
    my ($obj, $varname, $type, $val, $method) = @_;

    $val = defined $val ? qq{"$val"} : 'undef';
    return _regexify($obj, $method, "the '$varname' parameter ($val) is not of type $type");
}

sub badtype_error
{
    my ($obj, $type, $submsg, $method) = @_;

    return _regexify($obj, $method, "the type $type is unrecognized ($submsg)");
}


1;
