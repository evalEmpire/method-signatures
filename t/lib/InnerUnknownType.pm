package InnerUnknownType;

use strict;
use warnings;

use Method::Signatures qw< :TYPES >;


sub new { bless {}, __PACKAGE__ }

method foo ( Foo::Bar $bar ) {}


1;
