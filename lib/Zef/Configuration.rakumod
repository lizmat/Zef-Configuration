use JSON::Fast:ver<0.16>;

#-------------------------------------------------------------------------------
# Roles

my role JSONify {
    method json(
      Bool:D :$pretty      = True,
      Bool:D :$sorted-keys = True,
    --> Str:D) {
        to-json self.hash, :$pretty, :$sorted-keys
    }
}

my role Module does JSONify {
    has Str:D  $.short-name is rw is required;
    has Str:D  $.module     is rw is required;
    has Bool() $.enabled    is rw = True;
    has Str    $.comment    is rw;

    method hash(--> Map:D) {
        Map.new: (
          :$!short-name,
          :$!module,
          (:1enabled if :$!enabled),
          (:comment($_) with $!comment),
        )
    }
}

#-------------------------------------------------------------------------------
# License

class Zef::Configuration::License does JSONify {
    has @.blacklist;
    has @.whitelist  = "*";

    method hash(--> Map:D) {
        Map.new: (
          :@!blacklist,
          :@!whitelist,
        )
    }
}
my constant $default-license = Zef::Configuration::License.new;

#-------------------------------------------------------------------------------
# Install

class Zef::Configuration::Install does Module { }
my constant $default-install = Zef::Configuration::Install.new:
  :short-name<install-raku-dist>,
  :module<Zef::Service::InstallRakuDistribution>;

#-------------------------------------------------------------------------------
# Report

class Zef::Configuration::Report  does Module { }
my constant $file-reporter = Zef::Configuration::Report.new:
  :short-name<file-reporter>,
  :enabled(0),
  :module<Zef::Service::FileReporter>;

#-------------------------------------------------------------------------------
# Build

class Zef::Configuration::Build   does Module { }
my constant $default-builder = Zef::Configuration::Build.new:
  :short-name<default-builder>,
  :module<Zef::Service::Shell::DistributionBuilder>;
my constant $legacy-builder = Zef::Configuration::Build.new:
  :short-name<legacy-builder>,
  :module<Zef::Service::Shell::LegacyBuild>;

#-------------------------------------------------------------------------------
# Fetch

class Zef::Configuration::Fetch does Module {
    has Str $.scheme is rw;

    method hash(--> Map:D) {
        Map.new: (
          self.Module::hash(),
          (options => %(:$!scheme) if $!scheme)
        )
    }
}
my constant $git-fetch = Zef::Configuration::Fetch.new:
  :short-name<git>,
  :module<Zef::Service::Shell::git>,
  :scheme<https>;
my constant $path-fetch = Zef::Configuration::Fetch.new:
  :short-name<path>,
  :module<Zef::Service::Shell::FetchPath>;
my constant $curl-fetch = Zef::Configuration::Fetch.new:
  :short-name<curl>,
  :module<Zef::Service::Shell::curl>;
my constant $wget-fetch = Zef::Configuration::Fetch.new:
  :short-name<wget>,
  :module<Zef::Service::Shell::wget>;
my constant $pswebrequest-fetch = Zef::Configuration::Fetch.new:
  :short-name<pswebrequest>,
  :module<Zef::Service::Shell::Powershell::download>;

#-------------------------------------------------------------------------------
# Repository

class Zef::Configuration::Repository does Module {
    has Str:D  $.name        is rw = $!short-name;
    has Int:D  $.auto-update is rw = 1;
    has Bool() $.uses-path   is rw = $!name eq 'fez';
    has Str:D  @.mirrors;

    method hash(--> Map:D) {
        Map.new: (
          self.Module::hash(),
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
  :mirrors(
    "https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/cpan1.json",
    "https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/cpan.json",
    "git://github.com/ugexe/Perl6-ecosystems.git",
  );
my constant $repo-p6c = Zef::Configuration::Repository.new:
  :short-name<p6c>,
  :module<Zef::Repository::Ecosystems>,
  :mirrors(
    "https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/p6c1.json",
    "git://github.com/ugexe/Perl6-ecosystems.git",
    "http://ecosystem-api.p6c.org/projects1.json",
  );
my constant $repo-rea = Zef::Configuration::Repository.new:
  :short-name<rea>,
  :module<Zef::Repository::Ecosystems>,
  :enabled(0),
  :mirrors<https://raw.githubusercontent.com/Raku/REA/main/META.json>;
my constant $repo-cached = Zef::Configuration::Repository.new:
  :short-name<cached>,
  :module<Zef::Repository::LocalCache>;

#-------------------------------------------------------------------------------
# RepositoryGroup

class Zef::Configuration::RepositoryGroup does JSONify {
    has Zef::Configuration::Repository:D @.repositories = ...;

    method TWEAK() {
        die "Must specify at least 1 repository" unless @!repositories;
    }

    method hash(--> List:D) { @!repositories.map(*.hash).List }
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
# Extract

class Zef::Configuration::Extract does Module { }
my constant $extract-git = Zef::Configuration::Extract.new:
  :short-name<git>,
  :module<Zef::Service::Shell::git>,
  :comment("used to checkout (extract) specific tags/sha1/commit/branch from a git repo");
my constant $extract-path = Zef::Configuration::Extract.new:
  :short-name<path>,
  :module<Zef::Service::Shell::FetchPath>,
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
# Test

class Zef::Configuration::Test does Module { }
my constant $test-tap-harness = Zef::Configuration::Test.new:
  :short-name<tap-harness>,
  :module<Zef::Service::Tap>,
  :comment("Raku TAP::Harness adapter");
my constant $test-prove = Zef::Configuration::Test.new:
  :short-name<tap-harness>,
  :module<Zef::Service::Shell::prove>;
my constant $test-raku-test = Zef::Configuration::Test.new:
  :short-name<raku-test>,
  :module<Zef::Service::Shell::Test>;

#-------------------------------------------------------------------------------
# Configuration

my constant $default-repositories = Map.new: (
  fez    => $repo-fez,
  cpan   => $repo-cpan,
  p6c    => $repo-p6c,
  rea    => $repo-rea,
  cached => $repo-cached,
);

class Zef::Configuration:ver<0.0.1>:auth<zef:lizmat> does JSONify {
    has Str:D     $.ConfigurationVersion is rw = "1";
    has Str:D     $.RootDir              is rw = '$*HOME/.zef';
    has Str:D     $.StoreDir             is rw  = "$!RootDir/store";
    has Str:D     $.TempDir              is rw = "$!RootDir/tmp";
    has License:D $.License              is rw = $default-license;
    has Str:D     @.DefaultCUR = "auto";
    has RepositoryGroup:D @.Repository =
      $group-primary, $group-secondary, $group-tertiary, $group-last;
    has Fetch:D   @.Fetch =
      $git-fetch, $path-fetch, $curl-fetch, $wget-fetch, $pswebrequest-fetch;
    has Extract:D @.Extract =
      $extract-git,$extract-path,$extract-tar,$extract-p5tar,$extract-psunzip;
    has Build:D   @.Build   = $default-builder, $legacy-builder;
    has Install:D @.Install = $default-install;
    has Report:D  @.Report  = $file-reporter;
    has Test:D    @.Test    = $test-tap-harness, $test-prove, $test-raku-test;

    multi method new(:$user!) {
        $user
          ?? self.new: self.user-configuration
          !! self.bless
    }
    multi method new(IO::Path:D $io) {
        self.new: from-json $io.slurp
    }
    multi method new(%hash) {
        my %new = %hash<ConfigurationVersion RootDir StoreDir TempDir>:p;

        with %hash<DefaultCUR> -> @_ { %new<DefaultCUR> := @_ }

        with %hash<License> -> %_ {
            %new<License> := Zef::Configuration::License.new: |%_;
        }
        with %hash<Fetch> -> @_ {
            %new<Fetch> := @_.map( -> %_ {
                my %new = %_<short-name module>:p;
                %new<scheme> := $_ with %_<options><scheme>;
                Zef::Configuration::Fetch.new: |%new
            }).List;
        }

        with %hash<Repository> -> @groups {
            my @RepositoryGroups;
            for @groups -> @_ {
                my @repositories;
                for @_ -> %_ {
                    my %new = %_<short-name enabled module>:p;
                    with %_<options> -> %options {
                        for <name auto-update uses-path> -> $name {
                            %new{$name} := $_ with %options{$name};
                        }
                        with %options<mirrors> -> @mirrors {
                            %new<mirrors> := @mirrors;
                        }
                    }
                    @repositories.push:
                      Zef::Configuration::Repository.new: |%new;
                }
                @RepositoryGroups.push:
                  Zef::Configuration::RepositoryGroup.new: :@repositories;
            }
            %new<Repository> := @RepositoryGroups;
        }

        for <Extract Build Install Report Test> -> $name {
            with %hash{$name} -> @_ {
                %new{$name} := @_.map({
                    ::("Zef::Configuration::$name").new(|$_) }
                ).List;
            }
        }

        self.bless: |%new
    }

    method hash(--> Map:D) {
        Map.new: (
          :$!ConfigurationVersion,
          :$!RootDir,
          :$!StoreDir,
          :$!TempDir,
          :@!DefaultCUR,
          :License($!License.hash),
          :Repository(@!Repository.map(*.hash).List),
          :Fetch(@!Fetch.map(*.hash).List),
          :Extract(@!Extract.map(*.hash).List),
          :Build(@!Build.map(*.hash).List),
          :Install(@!Install.map(*.hash).List),
          :Report(@!Report.map(*.hash).List),
          :Test(@!Test.map(*.hash).List),
        )
    }

    method user-configuration(--> IO:D) {
        my $proc := run <zef --help>, :err;
        with $proc.err.lines.first(*.starts-with('CONFIGURATION ')) {
            .substr(14).IO
        }
    }

    proto method default-repositories(|) {*}
    multi method default-repositories() {
        $default-repositories.sort(*.key).map: *.value.short-name
    }
    multi method default-repositories(str $name) {
        $default-repositories{$name}
    }
}

#my $zc := Zef::Configuration.new;
#$zc.Repository[2].repositories[0].enabled = True;
#say $zc.json;
#say $zc.default-repositories;

=begin pod

=head1 NAME

Zef::Configuration - Manipulate Zef configurations

=head1 SYNOPSIS

=begin code :lang<raku>

use Zef::Configuration;

=end code

=head1 DESCRIPTION

Zef::Configuration is a class that allows you to manipulate the configuration
of Zef.

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/Zef-Configuration .
Comments and Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
