package Method::Signatures::Parser;

use strict;
use warnings;
use Carp ();

use base qw(Exporter);
our @EXPORT = qw(split_proto);


sub split_proto {
    my $proto = shift;
    return unless $proto =~ /\S/;

    require PPI;
    my $ppi = PPI::Document->new(\$proto);
    my $statement = $ppi->find_first("PPI::Statement");
    Carp::confess("Failed to find statement") unless $statement;
    my $token = $statement->first_token;

    my @proto = ('');
    do {
        if( $token->class eq "PPI::Token::Operator" and $token->content eq ',' ) {
            push @proto, '';
        }
        else {
            $proto[-1] .= $token->content;
        }
    } while( $token = $token->next_sibling );

    strip_ws($_) for @proto;
    return @proto;
}


sub strip_ws {
    $_[0] =~ s{^\s+}{};
    $_[0] =~ s{\s+$}{};
}

1;
