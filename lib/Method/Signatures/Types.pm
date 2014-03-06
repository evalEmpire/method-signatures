package Method::Signatures::Types;

use Mouse::Util::TypeConstraints;

subtype 'Inf',
  as 'Str',
  where { $_ eq 'inf' };

1;
