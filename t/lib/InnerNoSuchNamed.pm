package InnerNoSuchNamed;

use strict;
use warnings;

use Method::Signatures;


sub new { bless {}, __PACKAGE__ }

method foo ( :$bar, :$baz ) {}


1;
