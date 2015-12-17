#!/usr/bin/perl -w

use 5.008001;

use Module::Build;

my $class = Module::Build->subclass(
    class => 'Module::Build::Custom',
    code  => <<'SUBCLASS');

sub ACTION_distmeta{
    my ($self) = @_;
    if (eval {require Pod::Readme; Pod::Readme->can('new') } ){
        $self->delete_filetree('README');
        my $prf = Pod::Readme->new(
            target      => 'readme',
            base_dir    => '.',
            input_file  => $self->_main_docfile,
            output_file => 'README.pod',
        );
        $prf->run();
	$self->_add_to_manifest('MANIFEST', 'README.pod');
    }
    $self->SUPER::ACTION_distmeta;
};
   
SUBCLASS

my $build = $class->new(
    module_name     => 'Method::Signatures',
    license         => 'perl',

    recursive_test_files => 1,

    configure_requires => {
        'Module::Build'     => '0.31',
    },

    build_requires      => {
        'Module::Build'     => '0.26',
        'Test::More'        => '0.82',
        'Test::Builder'     => '0.82',
        'Test::Warn'        => '0.10',
        'Test::Exception'   => '0.29',
    },

    requires        => {
        'perl'              => '5.8.1',

        'Devel::Declare'    => '0.006002',
        'Devel::Declare::MethodInstaller::Simple' => '0.006002',
        'Const::Fast'       => '0.006',
        PPI                 => '1.203',
        'Any::Moose'        => '0.11',
        Mouse               => '0.64',
        'Sub::Name'         => '0.03',
        'Lexical::SealRequireHints' => '0.008', #0.008 is for perl 5.10.x, RT#93759
    },

    recommends      => {
        'Moose'             => '0.96',
        'Data::Alias'       => '1.08',
    },

    dist_author     => 'Michael G Schwern <schwern@pobox.com>',

    meta_merge      => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  =>
                'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Method-Signatures',
            repository  => 'https://github.com/evalEmpire/method-signatures',
        },
    },
    create_readme => 1,
    create_license => 1,
);
$build->create_build_script;
