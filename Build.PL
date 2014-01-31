use Module::Build;
my $build = Module::Build->new(
    module_name => 'Lystyng',
    license => 'perl',
    requires => {
        perl        => '5.10.0',
        DBIx::Class => 0,
        DBD::mysql  => 0,
        Moose       => 0,
        YAML        => 0,
        Dancer      => 1,
        Template    => 1,
        Dancer::Plugin::DBIC       => 0,
        MooseX::MarkAsMethods      => 0,
        MooseX::NonMoose           => 0,
        DBIx::Class::EncodedColumn => 0,
    },
    build_requires => {
        Test::Class => 0,
        Test::More => 0,
    },
    create_makefile_pl => 'traditional',
);

$build->create_build_script;

