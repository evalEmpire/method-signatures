package Method::Signatures::Parser;

use strict;
use warnings;
use Carp;

use base qw(Exporter);
our @EXPORT = qw(split_proto split_parameter extract_invocant sig_parsing_error carp_location_for);


sub split_proto {
    my $proto = shift;
    return unless $proto =~ /\S/;

    local $@ = undef;

    my $ppi = new_ppi_doc(\$proto);
    $ppi->prune('PPI::Token::Comment');

    my $statement = $ppi->find_first("PPI::Statement");
    sig_parsing_error("Could not understand parameter list specification: $proto")
        unless $statement;
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

    # Remove blank entries due to trailing comma.
    @proto = grep { /\S/ } @proto;

    return @proto;
}


# Some regexen useful for parsing signatures...
my $IDENTIFIER     = qr{ [^\W\d] \w*                                                       }x;
my $VARIABLE       = qr{ [\$\@%] $IDENTIFIER                                               }x;
my $TYPENAME       = qr{ $IDENTIFIER (?: \:\: $IDENTIFIER )*                               }ix;
our $PARAMETERIZED;
    $PARAMETERIZED = do{ use re 'eval';
                         qr{ $TYPENAME (?: \[ (??{$PARAMETERIZED}) \] )?                   }x;
                     };
my $TYPESPEC       = qr{ ^ \s* $PARAMETERIZED (?: \s* \| \s* $PARAMETERIZED )* \s* }x;

# Extract an invocant, if one is present...
sub extract_invocant {
    my ($param_ref) = @_;

    if ($$param_ref =~ s{ ^ (\$ $IDENTIFIER) \s* : \s* }{}x) {
        return $1;
    }
    return;
}

# Classify the components of a single parameter spec...
sub split_parameter {
    my ($param, $idx_ref) = @_;

    # Handle yada yada specifier...
    if ($param =~ m{^ \s* \Q...\E \s* $}x) {
        return { yadayada => 1 };
    }

    # Storage for decoded components...
    my %sig = ( proto => $param );

    # Note: Have to preparse with regexes up to traits
    #       because :, ! and ? in sigs confuse PPI

    # Extract type (if any)..
    $sig{type} = $1 if $param =~ s{^ ($TYPESPEC) \s+ }{}ox;

    # Extract ref-alias & named-arg markers, param var, and required/optional marker...
    $param =~ s{ ^ \s* ([\\:]*) \s* ($VARIABLE) \s* ([!?]?) }{}ox
        or sig_parsing_error("Could not understand parameter specification: $param");

    my ($premod, $var, $postmod) = ($1, $2, $3);
    $sig{is_ref_alias} = $premod =~ m{ \\ }x;
    $sig{named}        = $premod =~ m{ :  }x;
    $sig{var}          = $var;
    my $req_flag       = $postmod || '';

    # Analyse parameter variable...
    if (!$sig{named}) {
        $sig{idx} = ${$idx_ref}++;
    }
    @sig{'sigil', 'name'}  = $sig{var} =~ m{^ (.) (.*) }x;
    $sig{is_slurpy}        = !$sig{is_ref_alias} && $sig{sigil} =~ m{ ^ [%\@] $ }x;
    $sig{is_at_underscore} = $sig{var} eq '@_';

    # Extract default specifiers (if any) via PPI...
    if ($param =~ /\S/) {
        # Replace parameter var so as not to confuse PPI...
        $param = "$sig{var} $param";

        # Tokenize...
        my $components = new_ppi_doc(\$param);
        my $statement = $components->find_first("PPI::Statement")
            or sig_parsing_error("Could not understand parameter specification: $param");
        my $tokens = [ $statement->children ];

        # Re-remove parameter var
        shift @$tokens;

        # Extract any 'where' contraints...
        while (extract_leading(qr{^ where $}x, $tokens)) {
            sig_parsing_error("'where' constraint only available under Perl 5.10 or later. Error")
                if $] < 5.010;
            $sig{where}{extract_until(qr{^ (?: where | is | = | //= ) $}x, $tokens)}++;
        }

        # Extract parameter traits...
        while (extract_leading(qr{^ is $}x, $tokens)) {
            $sig{traits}{extract_leading(qr{^ \S+ $}x, $tokens)}++;
        }

        # Extract normal default specifier (if any)...
        if (extract_leading(qr{^ = $}x, $tokens)) {
            $sig{default} = extract_until(qr{^ when $}x, $tokens);

            # Extract 'when' modifier (if any)...
            if (extract_leading(qr{^ when $}x, $tokens)) {
                sig_parsing_error("'when' modifier on default only available under Perl 5.10 or later. Error")
                    if $] < 5.010;
                $sig{default_when} = join(q{}, @$tokens);
                $tokens = [];
            }
        }

        # Otherwise, extract undef-default specifier (if any)...
        elsif (extract_leading(qr{^ //= $}x, $tokens)) {
            sig_parsing_error("'//=' defaults only available under Perl 5.10 or later. Error")
                if $] < 5.010;
            $sig{default_when} = 'undef';
            $sig{default}      = join(q{}, @$tokens);
            $tokens = [];
        }

        # Anything left over is an error...
        elsif (my $trailing = extract_leading(qr{ \S }x, $tokens)) {
            sig_parsing_error("Unexpected extra code after parameter specification: '",
                  $trailing . join(q{}, @$tokens), "'"
            );
        }
    }

    # Resolve optional status...
    $sig{is_optional}
        = $req_flag ne '!'
          && ($req_flag eq '?' || exists $sig{default} || $sig{named} || $sig{is_slurpy});

    # Return complete analysis...
    return \%sig;
}

sub strip_ws {
    $_[0] =~ s{^\s+}{};
    $_[0] =~ s{\s+$}{};
}

# Remove tokens up to (but excluding) the first that matches the delimiter...
sub extract_until {
    my ($delimiter_pat, $tokens) = @_;

    my $extracted = q{};

    while (@$tokens) {
        last if $tokens->[0] =~ $delimiter_pat;
        $extracted .= shift @$tokens;
    }

    return $extracted;
}

# Remove leading whitespace + token, if token matches the specified pattern...
sub extract_leading {
    my ($selector_pat, $tokens) = @_;

    while (@$tokens && $tokens->[0]->class eq 'PPI::Token::Whitespace') {
        shift @$tokens;
    }

    return @$tokens && $tokens->[0] =~ $selector_pat
                ? "" . shift @$tokens
                : undef;
}

# Generate cleaner error messages...
sub carp_location_for {
    my ($class, $target) = @_;
    $target = qr{(?!)} if !$target;

    # using @CARP_NOT here even though we're not using Carp
    # who knows? maybe someday Carp will be capable of doing what we want
    # until then, we're rolling our own, but @CARP_NOT is still serving roughly the same purpose
    our @CARP_NOT;
    local @CARP_NOT;
    push @CARP_NOT, 'Method::Signatures';
    push @CARP_NOT, 'Method::Signatures::Parser';
    push @CARP_NOT, $class unless $class =~ /^${\__PACKAGE__}(::|$)/;
    push @CARP_NOT, qw< Class::MOP Moose Mouse Devel::Declare >;
    my $skip = qr/^(?:${\(join('|', @CARP_NOT))})::/;

    my $level = 0;
    my ($pack, $file, $line, $method);
    do {
        ($pack, $file, $line, $method) = caller(++$level);
    } while $method !~ $target and $method =~ /$skip/ or $pack =~ /$skip/;

    return ($file, $line, $method);
}

sub new_ppi_doc {
    my $source = shift;

    require PPI;
    my $ppi = PPI::Document->new($source) or
      sig_parsing_error("source '$$source' cannot be parsed by PPI: " . PPI::Document->errstr);
    return $ppi;
}

sub sig_parsing_error {
    my ($file, $line) = carp_location_for(__PACKAGE__, 'Devel::Declare::linestr_callback');
    my $msg = join('', @_, " in declaration at $file line $line.\n");
    die($msg);
}

1;
