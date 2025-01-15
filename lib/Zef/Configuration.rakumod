use JSON::Fast:ver<0.19+>:auth<cpan:TIMOTIMO>;

#-------------------------------------------------------------------------------
# Roles

my role JSONify {
    method json(
      Bool:D :$pretty      = True,
      Bool:D :$sorted-keys = True,
    --> Str:D) {
        to-json self.data, :$pretty, :$sorted-keys
    }
}

my role Module does JSONify {
    has Str:D  $.short-name is rw is required;
    has Str:D  $.module     is rw = self.default-module;
    has Bool() $.enabled    is rw = True;
    has Str    $.comment    is rw;

    method default-module() {
        X::Attribute::Required.new(:name<$!module>).throw
    }

    multi method new(Module: %data) { self.new: |%data }

    method data(--> Map:D) {
        Map.new: (
          :$!short-name,
          :$!module,
          :enabled($!enabled.Int),
          (:comment($_) with $!comment),
        )
    }

    method status(--> Str:D) {
        $!enabled
          ?? $!short-name
          !! "$!short-name (disabled)"
    }
}

#-------------------------------------------------------------------------------
# License

class Zef::Configuration::License does JSONify {
    has $.blacklist = ();
    has $.whitelist = ("*",);

    multi method new(Zef::Configuration::License: %data) {
        self.new: |%data
    }

    method data(--> Map:D) {
        Map.new: (
          :$!blacklist,
          :$!whitelist,
        )
    }

    method status(--> Str:D) {
        "blacklist($!blacklist) whitelist($!whitelist)"
    }
}
my constant $license-default = Zef::Configuration::License.new;

#-------------------------------------------------------------------------------
# Repository

class Zef::Configuration::Repository does Module {
    has Str:D  $.name        is rw = $!short-name;
    has Int:D  $.auto-update is rw = 1;
    has Bool() $.uses-path   is rw = $!name eq 'fez';
    has Str:D  @.mirrors;

    method default-module() { "Zef::Repository::Ecosystems" }

    multi method new(Zef::Configuration::Repository: %data) {
        my %new = %data<short-name enabled module>:p;
        with %data<options> -> %options {
            for <name auto-update uses-path> -> $name {
                %new{$name} := $_ with %options{$name};
            }
            with %options<mirrors> -> @mirrors {
                %new<mirrors> := @mirrors;
            }
        }
        self.new: |%new
    }

    method data(--> Map:D) {
        Map.new: (
          self.Module::data(),
          options => %(
            :$!name,
            :$!auto-update,
            (:uses-path    if $!uses-path),
            :@!mirrors,
          )
        )
    }
}
my constant $repo-fez = Zef::Configuration::Repository.new:
  :short-name<fez>,
  :module<Zef::Repository::Ecosystems>,
  :mirrors<https://360.zef.pm/>;
my constant $repo-cpan = Zef::Configuration::Repository.new:
  :short-name<cpan>,
  :module<Zef::Repository::Ecosystems>,
  :enabled(0),
  :mirrors(
    "https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/cpan1.json",
    "https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/cpan.json",
    "git://github.com/ugexe/Perl6-ecosystems.git",
  );
my constant $repo-p6c = Zef::Configuration::Repository.new:
  :short-name<p6c>,
  :module<Zef::Repository::Ecosystems>,
  :enabled(0),
  :mirrors(
    "https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/p6c1.json",
    "git://github.com/ugexe/Perl6-ecosystems.git",
    "http://ecosystem-api.p6c.org/projects1.json",
  );
my constant $repo-rea = Zef::Configuration::Repository.new:
  :short-name<rea>,
  :module<Zef::Repository::Ecosystems>,
  :mirrors<https://raw.githubusercontent.com/Raku/REA/main/META.json>;
my constant $repo-cached = Zef::Configuration::Repository.new:
  :short-name<cached>,
  :auto-update(0),
  :module<Zef::Repository::LocalCache>;

#-------------------------------------------------------------------------------
# RepositoryGroup

class Zef::Configuration::RepositoryGroup does JSONify {
    has Zef::Configuration::Repository:D @.repositories;

    submethod TWEAK() {
        die "Must specify at least 1 repository" unless @!repositories;
    }

    method data(--> List:D) { @!repositories.map(*.data).List }
    method status() {
        @!repositories == 1
          ?? @!repositories.head.status
          !! '(' ~ @!repositories.map(*.status).join(',') ~ ')'
    }
}
my constant $group-primary = Zef::Configuration::RepositoryGroup.new:
  :repositories($repo-fez);
my constant $group-secondary = Zef::Configuration::RepositoryGroup.new:
  :repositories($repo-cpan, $repo-p6c);
my constant $group-tertiary = Zef::Configuration::RepositoryGroup.new:
  :repositories($repo-rea);
my constant $group-last = Zef::Configuration::RepositoryGroup.new:
  :repositories($repo-cached);

#-------------------------------------------------------------------------------
# Fetch

class Zef::Configuration::Fetch does Module {
    has Str $.scheme is rw;

    multi method new(Zef::Configuration::Fetch: %data) {
        my %new = %data<short-name module enabled>:p;
        %new<scheme> := $_ with %data<options><scheme>;
        self.new: |%new
    }

    method data(--> Map:D) {
        Map.new: (
          self.Module::data(),
          (options => %(:$!scheme) if $!scheme)
        )
    }
}
my constant $fetch-git = Zef::Configuration::Fetch.new:
  :short-name<git>,
  :module<Zef::Service::Shell::git>,
  :scheme<https>;
my constant $fetch-path = Zef::Configuration::Fetch.new:
  :short-name<path>,
  :module<Zef::Service::FetchPath>;
my constant $fetch-curl = Zef::Configuration::Fetch.new:
  :short-name<curl>,
  :module<Zef::Service::Shell::curl>;
my constant $fetch-wget = Zef::Configuration::Fetch.new:
  :short-name<wget>,
  :module<Zef::Service::Shell::wget>;
my constant $fetch-pswebrequest = Zef::Configuration::Fetch.new:
  :short-name<pswebrequest>,
  :module<Zef::Service::Shell::Powershell::download>;

#-------------------------------------------------------------------------------
# Extract

class Zef::Configuration::Extract does Module { }
my constant $extract-git = Zef::Configuration::Extract.new:
  :short-name<git>,
  :module<Zef::Service::Shell::git>,
  :comment("used to checkout (extract) specific tags/sha1/commit/branch from a git repo");
my constant $extract-path = Zef::Configuration::Extract.new:
  :short-name<path>,
  :module<Zef::Service::FetchPath>,
  :comment("if this goes before git then git wont be able to extract/checkout local paths because this reaches it first :(");
my constant $extract-tar = Zef::Configuration::Extract.new:
  :short-name<tar>,
  :module<Zef::Service::Shell::tar>;
my constant $extract-p5tar = Zef::Configuration::Extract.new:
  :short-name<p5tar>,
  :module<Zef::Service::Shell::p5tar>;
my constant $extract-unzip = Zef::Configuration::Extract.new:
  :short-name<unzip>,
  :module<Zef::Service::Shell::unzip>;
my constant $extract-psunzip = Zef::Configuration::Extract.new:
  :short-name<psunzip>,
  :module<Zef::Service::Shell::PowerShell::unzip>;

#-------------------------------------------------------------------------------
# Build

class Zef::Configuration::Build   does Module { }
my constant $build-default = Zef::Configuration::Build.new:
  :short-name<default-builder>,
  :module<Zef::Service::Shell::DistributionBuilder>;
my constant $build-legacy = Zef::Configuration::Build.new:
  :short-name<legacy-builder>,
  :module<Zef::Service::Shell::LegacyBuild>;

#-------------------------------------------------------------------------------
# Test

class Zef::Configuration::Test does Module { }
my constant $test-tap-harness = Zef::Configuration::Test.new:
  :short-name<tap-harness>,
  :module<Zef::Service::Tap>,
  :comment("Raku TAP::Harness adapter");
my constant $test-prove = Zef::Configuration::Test.new:
  :short-name<prove>,
  :module<Zef::Service::Shell::prove>;
my constant $test-raku-test = Zef::Configuration::Test.new:
  :short-name<raku-test>,
  :module<Zef::Service::Shell::Test>;

#-------------------------------------------------------------------------------
# Report

class Zef::Configuration::Report does Module { }
my constant $report-file = Zef::Configuration::Report.new:
  :short-name<file-reporter>,
  :enabled(0),
  :module<Zef::Service::FileReporter>;

#-------------------------------------------------------------------------------
# Install

class Zef::Configuration::Install does Module { }
my constant $install-default = Zef::Configuration::Install.new:
  :short-name<install-raku-dist>,
  :module<Zef::Service::InstallRakuDistribution>;

#-------------------------------------------------------------------------------
# CUR

my constant $defaultCUR-default = ("auto",);

#-------------------------------------------------------------------------------
# Defaults

my constant $default-licenses = Map.new: (
  default => $license-default,
);
my constant $default-repositories = Map.new: (
  fez    => $repo-fez,
  cpan   => $repo-cpan,
  p6c    => $repo-p6c,
  rea    => $repo-rea,
  cached => $repo-cached,
);
my constant $default-repository-groups = Map.new: (
  primary   => $group-primary,
  secondary => $group-secondary,
  tertiary  => $group-tertiary,
  last      => $group-last,
);
my constant $default-fetches = Map.new: (
  git          => $fetch-git,
  path         => $fetch-path,
  curl         => $fetch-curl,
  wget         => $fetch-wget,
  pswebrequest => $fetch-pswebrequest,
);
my constant $default-extracts = Map.new: (
  git     => $extract-git,
  path    => $extract-path,
  tar     => $extract-tar,
  p5tar   => $extract-p5tar,
  unzip   => $extract-unzip,
  psunzip => $extract-psunzip,
);
my constant $default-builds = Map.new: (
  default-builder => $build-default,
  legacy-builder  => $build-legacy,
);
my constant $default-tests = Map.new: (
  tap-harness => $test-tap-harness,
  prove       => $test-prove,
  raku-test   => $test-raku-test,
);
my constant $default-reports = Map.new: (
  file => $report-file,
);
my constant $default-installs = Map.new: (
  install-raku-dist => $install-default,
);
my constant $default-defaultCURs = Map.new: (
  default => $defaultCUR-default,
);

#-------------------------------------------------------------------------------
# Configuration

class Zef::Configuration does JSONify {
    has Str:D     $.ConfigurationVersion is rw = "1";
    has Str:D     $.RootDir  is rw = '$*HOME/.zef';
    has Str:D     $.StoreDir is rw = "$!RootDir/store";
    has Str:D     $.TempDir  is rw = "$!RootDir/tmp";
    has License:D $.License  is rw = $license-default;
    has RepositoryGroup:D @.Repository =
      $group-primary, $group-secondary, $group-tertiary, $group-last;
    has Fetch:D   @.Fetch =
      $fetch-git, $fetch-path, $fetch-curl, $fetch-wget, $fetch-pswebrequest;
    has Extract:D @.Extract =
      $extract-git,$extract-path,$extract-tar,$extract-p5tar,$extract-psunzip;
    has Build:D   @.Build   = $build-default, $build-legacy;
    has Test:D    @.Test    = $test-tap-harness, $test-prove, $test-raku-test;
    has Report:D  @.Report  = $report-file;
    has Install:D @.Install = $install-default;
    has Str:D     @.DefaultCUR = $defaultCUR-default;

    multi method new(:$user!) {
        $user
          ?? self.new: self.user-configuration
          !! self.bless
    }
    multi method new(IO::Path:D $io) {
        self.new: from-json $io.slurp, :immutable
    }
    multi method new(Str:D $json) {
        self.new: from-json $json, :immutable
    }
    multi method new(%hash) {
        my %new = %hash<ConfigurationVersion RootDir StoreDir TempDir>:p;

        with %hash<License> -> %_ {
            %new<License> := Zef::Configuration::License.new: %_;
        }

        with %hash<Repository> -> @groups {
            my @RepositoryGroups;
            for @groups -> @_ {
                @RepositoryGroups.push:
                  Zef::Configuration::RepositoryGroup.new:
                    repositories => @_.map(-> %_ {
                        Zef::Configuration::Repository.new: %_
                    }).List
            }
            %new<Repository> := @RepositoryGroups;
        }

        with %hash<Fetch> -> @_ {
            %new<Fetch> := @_.map(-> %_ {
                Zef::Configuration::Fetch.new: %_
            }).List;
        }

        for <Extract Build Install Report Test> -> $name {
            with %hash{$name} -> @_ {
                %new{$name} := @_.map(-> %_ {
                    ::("Zef::Configuration::$name").new(%_) }
                ).List;
            }
        }

        with %hash<DefaultCUR> -> @_ { %new<DefaultCUR> := @_ }

        self.bless: |%new
    }

    method data(--> Map:D) {
        Map.new: (
          :$!ConfigurationVersion,
          :$!RootDir,
          :$!StoreDir,
          :$!TempDir,
          :License($!License.data),
          :Repository(@!Repository.map(*.data).List),
          :Fetch(@!Fetch.map(*.data).List),
          :Extract(@!Extract.map(*.data).List),
          :Build(@!Build.map(*.data).List),
          :Test(@!Test.map(*.data).List),
          :Report(@!Report.map(*.data).List),
          :Install(@!Install.map(*.data).List),
          :@!DefaultCUR,
        )
    }

    method user-configuration(--> IO::Path:D) {
        my $proc := run <zef --help>, :err;
        with $proc.err.lines.first(*.starts-with('CONFIGURATION ')) {
            .substr(14).IO;
        }
    }

    method is-configuration-writeable(IO:D $path --> Bool:D) {
        $path.w && !$path.contains:
          / '/resources/' <[0123456789ABCDEF]> ** 40 '.json' $ /
    }

    method new-user-configuration(--> IO::Path:D) {
        my $zef;
        if %*ENV<XDG_CONFIG_HOME> -> $home {
            $zef := $home.IO.add("zef");
        }
        elsif $*HOME -> $home {
            $zef := $home.IO.add(".config").add("zef");
        }
        if $zef {
            $zef.mkdir;
            $zef.d ?? $zef.add("config.json") !! Nil
        }
        else {
            Nil
        }
    }

    method status(--> Str:D) {
        ( "   License: $!License.status()",
          "Repository: @!Repository.map(*.status).join(', ')",
          "     Fetch: @!Fetch.map(*.status).join(', ')",
          "   Extract: @!Extract.map(*.status).join(', ')",
          "     Build: @!Build.map(*.status).join(', ')",
          "      Test: @!Test.map(*.status).join(', ')",
          "    Report: @!Report.map(*.status).join(', ')",
          "   Install: @!Install.map(*.status).join(', ')",
          "DefaultCUR: @!DefaultCUR.join(', ')",
        ).join("\n")
    }

    method group-status($object --> Str:D) {
        with $object.^name {
            my $group := .substr(.rindex('::') + 2);
            "$group: " ~ self."$group"().map(*.status).join(', ')
        }
    }

    method !default(%map, $name) {
        $name
          ?? %map{$name}
          !! %map.sort(*.key).map: *.value.short-name
    }

    method default-license($name?) {
        self!default($default-licenses, $name)
    }
    method default-repository($name?) {
        self!default($default-repositories, $name)
    }
    method default-repository-group($name?) {
        self!default($default-repository-groups, $name)
    }
    method default-fetch($name?) {
        self!default($default-fetches, $name)
    }
    method default-extract($name?) {
        self!default($default-extracts, $name)
    }
    method default-build($name?) {
        self!default($default-builds, $name)
    }
    method default-test($name?) {
        self!default($default-tests, $name)
    }
    method default-report($name?) {
        self!default($default-reports, $name)
    }
    method default-install($name?) {
        self!default($default-installs, $name)
    }
    method default-defaultCUR($name?) {
        self!default($default-defaultCURs, $name)
    }

    method object-from-tag($name) {
        my @found;
#        @found.push(Pair.new("license", $!License)) if $name eq "default";

        for @!Repository -> $group {
            @found.append: $group.repositories.map: {
                Pair.new("Repository", $_) if .short-name eq $name
            }
        }

        for (
          :@!Fetch, :@!Extract, :@!Build, :@!Test, :@!Report,:@!Install,
        ) -> (:key($group), :value($entries)) {
            for @$entries {
                my $short-name := .short-name;
                @found.push(Pair.new($group, $_))
                  if $name eq $short-name | "$group-$short-name";
            }
        }

#        @found.push(Pair.new("defaultCUR", @!DefaultCUR)) if $name eq "default";

        @found
          ?? @found == 1
            ?? @found.head.value
            !! @found.List
          !! Nil
    }
}

# vim: expandtab shiftwidth=4
