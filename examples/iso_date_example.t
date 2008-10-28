#!/usr/bin/perl -lw

package Date;

use Method::Signatures;

method new($class:@_) {
    bless {@_}, $class;
}

method iso_date(
    :$year!,    :$month = 1, :$day = 1,
    :$hour = 0, :$min   = 0, :$sec = 0
)
{
    return sprintf "%04d-%02d-%02d %02d:%02d:%02d", $year, $month, $day, $hour, $min, $sec;
}

my $date = Date->new();
print $date->iso_date( year => 2008 );
