#! /usr/bin/env perl

use 5.12.0;
use warnings;

use Method::Signatures;


my %ERRORS =
(
	E100	=>	"The frobnobulator is all grizzed up.",
	E233	=>	"WARNING! Dagrilated toadthwacker down.",
	E666	=>	"Satan.",
	E951	=>	"Please reset your gymnozzle.",
);

func fatal ($msg! where { !/E\d{3}/ } = $ERRORS{$_[0]} when \%ERRORS)
{
	say STDERR $msg;
}


fatal('E100');
fatal("These are stupid error messages.");
fatal('E000');
