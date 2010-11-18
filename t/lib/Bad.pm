package Bad;

use strict;
use warnings;
use Method::Signatures;

## $info->{} should be $info{}
method meth2 ($arg) {
  my %info;
  $info->{xpto} = 1;
}

method meth2 ($arg) {}

1;
