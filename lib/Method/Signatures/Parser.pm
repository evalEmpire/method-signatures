package Method::Signatures::Parser;

use strict;
use warnings;
use Carp;

use base qw(Exporter);
our @EXPORT = qw(split_proto);


sub split_proto {
    my $proto = shift;
    return unless $proto =~ /\S/;

    require PPI;
    my $ppi = PPI::Document->new(\$proto);
    my $statement = $ppi->find_first("PPI::Statement");
    confess("PPI failed to find statement for '$proto'") unless $statement;
    my $token = $statement->first_token;

    my @proto = ('');
    do {
        if( $token->class eq "PPI::Token::Operator" and $token->content eq ',' ) {
            push @proto, '';
        }
        else {
            $proto[-1] .= $token->content;
        }

        $token = $token->class eq 'PPI::Token::Label' ? $token->next_token : $token->next_sibling;
    } while( $token );

    strip_ws($_) for @proto;
    return @proto;
}


sub strip_ws {
    $_[0] =~ s{^\s+}{};
    $_[0] =~ s{\s+$}{};
}

1;
