# package for t/override.t

package MSOverride;
use base qw< Method::Signatures >;


sub type_check
{
    warn "in overridden type_check";
}


1;
