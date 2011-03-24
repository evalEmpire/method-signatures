#!/usr/bin/perl -w

use 5.008001;

use Module::Build;

my $build = Module::Build->new(
    module_name     => 'Method::Signatures',
    license         => 'perl',

    recursive_test_files => 1,

    configure_requires => {
        'Module::Build'     => '0.26',
    },

    build_requires      => {
        'Module::Build'     => '0.26',
        'Test::More'        => '0.82',
        'Test::Builder'     => '0.82',
        'Test::Warn'        => '0.10',
    },

    requires        => {
        'perl'              => '5.8.1',

        'Devel::Declare::MethodInstaller::Simple' => '0.003003',
        'Devel::BeginLift'  => '0.001001',
        'Const::Fast'       => '0.006',
        PPI                 => '1.203',
        'Data::Alias'       => '1.08',
        'Any::Moose'        => '0.11',
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
