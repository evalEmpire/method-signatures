package InnerBadType;

use strict;
use warnings;

use Method::Signatures;


sub new { bless {}, __PACKAGE__ }

#line 1133
method foo ( Int $bar ) {}


1;
