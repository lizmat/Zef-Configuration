use JSON::Fast:ver<0.16>;

#-------------------------------------------------------------------------------
# Subclasses

class Zef::Configuration::License {
    has @.blacklist;
    has @.whitelist  = "*";

    method hash() {
        Map.new: (
          :@!blacklist,
          :@!whitelist,
        )
    }
}
my constant $default-license = Zef::Configuration::License.new;

my role Zef::Configuration::Module {
    has Str:D $.short-name is required;
    has Str:D $.module     is required;
    has Int:D $.enabled = 1;
    has Str   $.comment;

    method hash() {
        Map.new: (
          :$!short-name,
          :$!module
          :$!enabled,
          (:comment($_) with $!comment),
        )
    }
}

class Zef::Configuration::Install does Zef::Configuration::Module { }
my constant $default-install = Zef::Configuration::Install.new:
  :short-name<install-raku-dist>,
  :module<Zef::Service::InstallRakuDistribution>;

class Zef::Configuration::Report  does Zef::Configuration::Module { }
my constant $file-reporter = Zef::Configuration::Report.new:
  :short-name<file-reporter>,
  :enabled(0),
  :module<Zef::Service::FileReporter>;

class Zef::Configuration::Build   does Zef::Configuration::Module { }
my constant $default-builder = Zef::Configuration::Build.new:
  :short-name<default-builder>,
  :module<Zef::Service::Shell::DistributionBuilder>;
my constant $legacy-builder = Zef::Configuration::Build.new:
  :short-name<legacy-builder>,
  :module<Zef::Service::Shell::LegacyBuild>;

class Zef::Configuration::Fetch does Zef::Configuration::Module {
    has Str $.scheme;

    method hash() {
        Map.new: (
          self.Zef::Configuration::Module::hash(),
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

class Zef::Configuration::Repository does Zef::Configuration::Module {
    has Str:D  $.name        = $!short-name;
    has Int:D  $.auto-update = 1;
    has Str:D  @.mirrors;

    method uses-path() { :uses-path(1) if $!name eq 'fez' }

    method hash() {
        Map.new: (
          self.Zef::Configuration::Module::hash(),
          options => %(
            :$!name,
            :$!auto-update,
            self.uses-path,
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
  :short-name<rea>,
  :module<Zef::Repository::LocalCache>;

class Zef::Configuration::RepositoryGroup {
    has Zef::Configuration::Repository:D @.repositories = ...;

    method TWEAK() {
        die "Must specify at least 1 repository" unless @!repositories;
    }

    method hash() { @!repositories.map(*.hash).List }
}
my constant $group-primary = Zef::Configuration::RepositoryGroup.new:
  :repositories($repo-fez);
my constant $group-secondary = Zef::Configuration::RepositoryGroup.new:
  :repositories($repo-cpan, $repo-p6c);
my constant $group-tertiary = Zef::Configuration::RepositoryGroup.new:
  :repositories($repo-rea);
my constant $group-last = Zef::Configuration::RepositoryGroup.new:
  :repositories($repo-cached);

class Zef::Configuration::Extract does Zef::Configuration::Module { }
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

class Zef::Configuration::Test does Zef::Configuration::Module { }
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
# Zef::Configuration

class Zef::Configuration:ver<0.0.1>:auth<zef:lizmat> {
    has Str:D     $.ConfigurationVersion = "1";
    has Str:D     $.RootDir    = '$*HOME/.zef';
    has Str:D     $.StoreDir   = "$!RootDir/store";
    has Str:D     $.TempDir    = "$!RootDir/tmp";
    has Str:D     @.DefaultCUR = "auto";
    has License:D $.License = $default-license;
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

    proto method new(|) {*}
    multi method new(:$local) {
        $local
          ?? self.new: from-json
               "/Users/liz/Github/rakudo.moar/install/share/perl6/site/resources/BBFC8550DB3C26C4B99B98A664B28E8EAD6675C5.json"
               .IO.slurp
          !! self.bless
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
            my @Repository := %new<Repository> := [];
            for @groups -> @_ {
                @Repository.push: 
            }
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

    method hash() {
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
}

my $zc := Zef::Configuration.new(:local);
say to-json $zc.hash, :sorted-keys;

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
