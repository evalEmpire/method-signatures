#! /usr/bin/env perl

use 5.12.0;
use warnings;

use Method::Signatures;


my %ERR_MESSAGES =
(
	E100	=>	"The frobnobulator is all grizzed up.",
	E233	=>	"WARNING! Dagrilated toadthwacker down.",
	E666	=>	"Satan.",
	E951	=>	"Please reset your gymnozzle.",
);

func error_handler ($msg = $ERR_MESSAGES{$_[0]} when \%ERR_MESSAGES)
{
	say STDERR $msg;
}


error_handler('E100');
error_handler("These are stupid error messages.");
