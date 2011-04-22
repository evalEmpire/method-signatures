# package for t/override_typecheck.t

package OverrideTypeCheck;
use base qw< Method::Signatures >;


sub type_check
{
    warn "in overridden type_check";
}


1;
