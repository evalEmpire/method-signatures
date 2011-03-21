package InnerBadType;

use strict;
use warnings;

use Method::Signatures;


sub new { bless {}, __PACKAGE__ }

method foo ( Int $bar ) {}


1;
