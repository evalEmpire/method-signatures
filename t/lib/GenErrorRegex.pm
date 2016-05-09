package GenErrorRegex;

use strict;
use warnings;

use base qw< Exporter >;
our @EXPORT_OK =
(
    qw< bad_param_error unexpected_after_error named_after_optpos_error pos_after_named_error required_after_optional_error >,    # compile-time
    qw< mispositioned_slurpy_error multiple_slurpy_error named_slurpy_error >,                      # compile-time
    qw< required_error required_placeholder_error named_param_error badval_error badtype_error >,   # run-time
);


sub _regexify
{
    my ($compile_time, $class, $obj, $method, $msg, %extra);
    $compile_time = ($_[0] || '') eq 'COMPILE_TIME';                    # really should be // there, but this works
    if ($compile_time)
    {
        (undef, $msg, %extra) = @_;
    }
    else
    {
        ($obj, $method, $msg, %extra) = @_;
        $class = ref $obj || $obj || 'main';
    }

    my $error = $compile_time ? "$msg in declaration at " : "In call to ${class}::$method(), $msg at ";
    if ($extra{LINE})
    {
        $extra{FILE} ||= $0;
        $error .= "$extra{FILE} line $extra{LINE}.\n";
    }
    if ($compile_time)
    {
        $error .= "Compilation failed";
    }

    $error = quotemeta $error;
    return $extra{LINE} && !$compile_time ? qr/\A$error\Z/ : qr/\A$error/;
}


####################################################################################################
# COMPILE-TIME ERRORS
# These don't know what package or method they're dealing with, so they require fewer parameters,
# and they'll call _regexify() with an initial argument of 'COMPILE_TIME'.
####################################################################################################


sub bad_param_error
{
    my ($param, %extra) = @_;

    return _regexify(COMPILE_TIME => "Could not understand parameter specification: $param", %extra);
}


sub unexpected_after_error
{
    my ($trailing, %extra) = @_;

    return _regexify(COMPILE_TIME => "Unexpected extra code after parameter specification: '$trailing'", %extra);
}


sub named_after_optpos_error
{
    my ($named, $optpos, %extra) = @_;

    return _regexify(COMPILE_TIME => "Named parameter '$named' mixed with optional positional '$optpos'", %extra);
}


sub required_after_optional_error
{
    my ($required, $optional, %extra) = @_;

    return _regexify(COMPILE_TIME => "Required positional parameter '$required' cannot follow an optional positional parameter '$optional'", %extra);
}


sub pos_after_named_error
{
    my ($pos, $named, %extra) = @_;

    return _regexify(COMPILE_TIME => "Positional parameter '$pos' after named param '$named'", %extra);
}


sub mispositioned_slurpy_error
{
    my ($param, %extra) = @_;

    return _regexify(COMPILE_TIME => "Slurpy parameter '$param' must come at the end", %extra);
}


sub multiple_slurpy_error
{
    my (%extra) = @_;

    return _regexify(COMPILE_TIME => "Signature can only have one slurpy parameter", %extra);
}


sub named_slurpy_error
{
    my ($param, %extra) = @_;

    return _regexify(COMPILE_TIME => "Slurpy parameter '$param' cannot be named; use a reference instead", %extra);
}


####################################################################################################
# RUN-TIME ERRORS
# These should know what package and method they're dealing with, so they will all take an $obj
# parameter and a $method parameter, with possibly some other parameters in between.  The $obj
# parameter can either be an instance of the package in question, or the name of it, or undef (which
# will indicate the 'main' package.  _regexify() handles all of that for you.  Of course, because of
# the way the compile-time errors are identified, it wouldn't work if you had a package named
# COMPILE_TIME.  That seems pretty unlikely though.
####################################################################################################


sub required_error
{
    my ($obj, $varname, $method, %extra) = @_;

    return _regexify($obj, $method, "missing required argument $varname", %extra);
}


sub required_placeholder_error
{
    my($obj, $n, $method, %extra) = @_;

    return _regexify($obj, $method, "missing required placeholder argument at position $n", %extra);
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
