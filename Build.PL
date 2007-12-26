#!/usr/bin/perl -w

use Module::Build;

my $build = Module::Build->new(
    module_name     => 'Method::Signatures',
    license         => 'perl',
    requires        => {
        'Devel::Declare'    => '0.001006',
        'Test::More'        => '0.62',
    },
    
    dist_author     => 'Michael G Schwern <schwern@pobox.com>',
    
    meta_merge      => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  =>
                'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Method-Signatures',
            repository  => 'http://svn.schwern.org/svn/CPAN/Method-Signatures',
        },
    },
);
$build->create_build_script;
