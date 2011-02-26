package Bad;

use strict;
use warnings;
use Method::Signatures;

## $info->{} should be $info{}
method meth1 ($foo) {
  my %info;
  $info->{xpto} = 1;
}

method meth2 ($bar) {}

1;
