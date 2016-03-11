package Method::Signatures::Types;

use strict;
use warnings;

use Mouse::Util::TypeConstraints;

subtype 'Inf',
  as 'Str',
  where { $_ eq 'inf' };

1;
