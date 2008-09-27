#!/usr/bin/perl -w

use 5.006;

use Module::Build;

my $build = Module::Build->new(
    module_name     => 'Method::Signatures',
    license         => 'perl',
    requires        => {
        'perl'              => '5.8.1',

        'Devel::Declare'    => '0.002000',
        'Test::More'        => '0.62',
        'Data::Alias'       => '1.07',
        'Sub::Name'         => '0.04',
    },
    
    dist_author     => 'Michael G Schwern <schwern@pobox.com>',
    
    meta_merge      => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  =>
                'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Method-Signatures',
            repository  => 'https://github.com/schwern/method-signatures/tree',
        },
    },
);
$build->create_build_script;
