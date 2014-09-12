package Method::Signatures::Utils;

use strict;
use warnings;
use Carp;

use base qw(Exporter);
our @EXPORT = qw(new_ppi_doc sig_parsing_error carp_location_for DEBUG);

sub DEBUG {
    return unless $Method::Signatures::DEBUG;

    require Data::Dumper;
    local $Data::Dumper::Sortkeys = 1;
    print STDERR "DEBUG: ", map { ref $_ ? Data::Dumper::Dumper($_) : $_ } @_;
}


sub new_ppi_doc {
    my $code = shift;

    require PPI;
    my $ppi = PPI::Document->new($code) or
      sig_parsing_error(
          "source '$$code' cannot be parsed by PPI: " . PPI::Document->errstr
      );

    return $ppi;
};


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
    push @CARP_NOT, $class unless $class =~ /^${\__PACKAGE__}(::|$)/;
    push @CARP_NOT, qw< Class::MOP Moose Mouse Devel::Declare >;

    # Skip any package in the @CARP_NOT list or their sub packages.
    my $carp_not_list_re = join '|', @CARP_NOT;
    my $skip = qr/^ $carp_not_list_re (?: :: | $ ) /x;

    my $level = 0;
    my ($pack, $file, $line, $method);
    do {
        ($pack, $file, $line, $method) = caller(++$level);
    } while $method !~ $target and $method =~ /$skip/ or $pack =~ /$skip/;

    return ($file, $line, $method);
}

sub sig_parsing_error {
    my ($file, $line) = carp_location_for(__PACKAGE__, 'Devel::Declare::linestr_callback');
    my $msg = join('', @_, " in declaration at $file line $line.\n");
    die($msg);
}

1;
