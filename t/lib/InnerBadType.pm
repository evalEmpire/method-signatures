package InnerBadType;

use strict;
use warnings;

use Method::Signatures qw< :TYPES >;


sub new { bless {}, __PACKAGE__ }

method foo ( Int $bar ) {}


1;
