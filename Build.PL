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
        Dancer2     => 0.166001,
        Template    => 0,
        Plack::Test => 0,
        JSON        => 0,
        Dancer2::Plugin::DBIC      => 0,
        Dancer2::Plugin::Auth::Tiny => 0,
        Dancer2::Plugin::Passphrase => 0,
        MooseX::MarkAsMethods      => 0,
        MooseX::NonMoose           => 0,
        DBIx::Class::EncodedColumn => 0,
        Email::Stuffer             => 0,
    },
    build_requires => {
        Test::Class => 0,
        Test::More => 0,
    },
    create_makefile_pl => 'traditional',
);

$build->create_build_script;

