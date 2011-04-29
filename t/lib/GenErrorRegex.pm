package GenErrorRegex;

use base qw< Exporter >;
our @EXPORT_OK = qw< required_error named_param_error badval_error badtype_error >;


sub _regexify
{
    my ($obj, $method, $msg, %extra) = @_;
    my $class = ref $obj || $obj || 'main';

    my $error = "In call to ${class}::$method(), $msg at ";
    if ($extra{LINE})
    {
        $extra{FILE} ||= $0;
        $error .= "$extra{FILE} line $extra{LINE}.\n";
    }

    $error = quotemeta $error;
    return $extra{LINE} ? qr/\A$error\Z/ : qr/\A$error/;
}


sub required_error
{
    my ($obj, $varname, $method, %extra) = @_;

    return _regexify($obj, $method, "missing required argument $varname", %extra);
}


sub named_param_error
{
    my ($obj, $varname, $method, %extra) = @_;

    return _regexify($obj, $method, "does not take $varname as named argument(s)", %extra);
}


sub badval_error
{
    my ($obj, $varname, $type, $val, $method, %extra) = @_;

    $val = defined $val ? qq{"$val"} : 'undef';
    return _regexify($obj, $method, "the '$varname' parameter ($val) is not of type $type", %extra);
}

sub badtype_error
{
    my ($obj, $type, $submsg, $method, %extra) = @_;

    return _regexify($obj, $method, "the type $type is unrecognized ($submsg)", %extra);
}


1;
