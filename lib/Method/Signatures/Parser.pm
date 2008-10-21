package Method::Signatures::Parser;

use strict;
use warnings;

use PPI;
use PPI::Dumper;
use base qw(Exporter);
our @EXPORT = qw(split_proto);


sub split_proto {
    my $proto = shift;
    return unless $proto =~ /\S/;

    my $ppi = PPI::Document->new(\$proto);
    my @tokens = $ppi->tokens;

    my @proto = ('');
    for my $token (@tokens) {
        if( $token->class eq "PPI::Token::Operator" and $token->content eq ',' ) {
            push @proto, '';
        }
        else {
            $proto[-1] .= $token->content;
        }
    }

    strip_ws($_) for @proto;
    return @proto;
}


sub strip_ws {
    $_[0] =~ s{^\s+}{};
    $_[0] =~ s{\s+$}{};
}

1;
