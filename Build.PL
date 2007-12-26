#!/usr/bin/perl -w

use Module::Build;

my $build = Module::Build->new(
    module_name     => 'Method::Signatures',
    license         => 'perl',
    requires        => {
        'Devel::Declare'    => '0.001006',
        'Test::More'        => '0.62',
    },
    
    dist_author     => 'Michael G Schwern <schwern@pobox.com>'
);
$build->create_build_script;
