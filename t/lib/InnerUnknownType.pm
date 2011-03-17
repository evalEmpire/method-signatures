package InnerUnknownType;

use strict;
use warnings;

use Method::Signatures;


sub new { bless {}, __PACKAGE__ }

method foo ( Foo::Bar $bar ) {}


1;
