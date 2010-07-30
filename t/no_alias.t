#!/usr/bin/perl -w

# Test when Data::Alias is not available.

use strict;
use warnings;

use Test::More 'no_plan';

my $out = `$^X "-Iblib/arch" "-Iblib/lib" "-Ilib" -c t/lib/NoAlias.pm 2>&1`;
is $out, "The alias trait was used on \$arg, but Data::Alias is not installed at NoAlias.pm line 13\n";
