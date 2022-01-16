use JSON::Fast:ver<0.16>;

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
    has Str:D  $.module     is rw is required;
    has Bool() $.enabled    is rw = True;
    has Str    $.comment    is rw;

    method data(--> Map:D) {
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

    method data(--> Map:D) {
        Map.new: (
          :@!blacklist,
          :@!whitelist,
        )
    }
}
my constant $default-license = Zef::Configuration::License.new;

#-------------------------------------------------------------------------------
# Repository

class Zef::Configuration::Repository does Module {
    has Str:D  $.name        is rw = $!short-name;
    has Int:D  $.auto-update is rw = 1;
    has Bool() $.uses-path   is rw = $!name eq 'fez';
    has Str:D  @.mirrors;

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

    method data(--> List:D) { @!repositories.map(*.data).List }
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
  :module<Zef::Service::Shell::FetchPath>;
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

class Zef::Configuration::Report  does Module { }
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
# Defaults

my constant $default-repositories = Map.new: (
  fez    => $repo-fez,
  cpan   => $repo-cpan,
  p6c    => $repo-p6c,
  rea    => $repo-rea,
  cached => $repo-cached,
);
my constant $default-fetch = Map.new: (
  git          => $fetch-git,
  path         => $fetch-path,
  curl         => $fetch-curl,
  wget         => $fetch-wget,
  pswebrequest => $fetch-pswebrequest,
);
my constant $default-extract = Map.new: (
  git     => $extract-git,
  path    => $extract-path,
  tar     => $extract-tar,
  p5tar   => $extract-p5tar,
  unzip   => $extract-unzip,
  psunzip => $extract-psunzip,
);
my constant $default-build = Map.new: (
  default  => $build-default,
  legacy   => $build-legacy,
);
my constant $default-test = Map.new: (
  tap-harness => $test-tap-harness,
  prove       => $test-prove,
  raku-test   => $test-raku-test,
);
my constant $default-report = Map.new: (
  file => $report-file,
);
my constant $default-install = Map.new: (
  default  => $install-default,
);

#-------------------------------------------------------------------------------
# Configuration

class Zef::Configuration:ver<0.0.1>:auth<zef:lizmat> does JSONify {
    has Str:D     $.ConfigurationVersion is rw = "1";
    has Str:D     $.RootDir  is rw = '$*HOME/.zef';
    has Str:D     $.StoreDir is rw = "$!RootDir/store";
    has Str:D     $.TempDir  is rw = "$!RootDir/tmp";
    has License:D $.License  is rw = $default-license;
    has Str:D     @.DefaultCUR = "auto";
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

    method data(--> Map:D) {
        Map.new: (
          :$!ConfigurationVersion,
          :$!RootDir,
          :$!StoreDir,
          :$!TempDir,
          :@!DefaultCUR,
          :License($!License.data),
          :Repository(@!Repository.map(*.data).List),
          :Fetch(@!Fetch.map(*.data).List),
          :Extract(@!Extract.map(*.data).List),
          :Build(@!Build.map(*.data).List),
          :Test(@!Test.map(*.data).List),
          :Report(@!Report.map(*.data).List),
          :Install(@!Install.map(*.data).List),
        )
    }

    method user-configuration(--> IO:D) {
        my $proc := run <zef --help>, :err;
        with $proc.err.lines.first(*.starts-with('CONFIGURATION ')) {
            .substr(14).IO
        }
    }

    method !default(%map, $name) {
        $name
          ?? %map{$name}
          !! %map.sort(*.key).map: *.value.short-name
    }

    method default-repositories($name?) {
        self!default($default-repositories, $name)
    }
    method default-fetch($name?) {
        self!default($default-fetch, $name)
    }
    method default-extract($name?) {
        self!default($default-extract, $name)
    }
    method default-build($name?) {
        self!default($default-build, $name)
    }
    method default-test($name?) {
        self!default($default-test, $name)
    }
    method default-report($name?) {
        self!default($default-report, $name)
    }
    method default-install($name?) {
        self!default($default-install, $name)
    }
}

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

=head2 GENERAL NOTES

All of the attributes of the classes provided by this distribution, are
either an C<Array> (and thus mutable), or a an attribute with the C<is rw>
trait applied to it.  This is generally ok, since it is expected that this
module will mostly only be used by a relatively short-lived CLI.

Note that if you change an object that is based on one of the default objects,
you will be changing the default as well.  This may or may not be what you
want.  If it is not, then you should probably first create a C<clone> of
the object, or use the C<clone> method with named arguments to create a
clone with changed values.

=head1 METHODS ON ALL CLASSES

All of these classes provided by this distribution provide these methods
(apart from the standard methods provided by Raku).

=head3 data

Return a Raku data-structure for the object.  This is usually a C<Map>, but
can also be a C<List>.

=head3 json

Return a pretty JSON string with sorted keys for the object.  Takes named
parameters C<:!pretty> and C<:!sorted-keys> should you not want the JSON
string to be pretty, or have sorted keys.

=head1 METHODS ON MOST CLASSES

With the exception of the C<Zef::Configuration::License> and
C<Zef::Configuration::RepositoryGroup> classes, the following methods are
always provided.

=head3 short-name

A name identifying the object.  B<Must> be specified in the creation of the
object.

=head3 module

The name of the Raku module to be used by this object.  B<Must> be specified
in the creation of the object.

=head3 enabled

A boolean indicating whether the object is enabled.  Defaults to C<True>.

=head3 comment

Any comments applicable to this object.  Defaults to the C<Str> type object.

=head1 CLASSES

=head2 Zef::Configuration

=head2 Zef::Configuration::License

Contains which licenses are C<blacklist>ed and which ones are C<whitelist>ed.
Defaults to no blacklisted licenses, and C<"*"> in the whitelist, indicating
that any license will be acceptable.  Does not contain any other information.

=head2 Zef::Configuration::Repository

=head2 Zef::Configuration::RepositoryGroup

Contains a list of C<Zef::Configuration::Repository> objects in the order in
which a search should be done for modules.  Does not contain any other
information.

=head2 Zef::Configuration::Fetch

Information on how to fetch a distribution from a
C<Zef::Configuration::Repository>.

=head2 Zef::Configuration::Extract

Information on how to extract information from a fetched distribution.

=head2 Zef::Configuration::Build

Information on how to build modules from a fetched distribution.

=head2 Zef::Configuration::Test

Information on how to perform tesing on a fetched distribution.

=head2 Zef::Configuration::Report

Information about how a report of a distribution test should be reported.

=head2 Zef::Configuration::Install

Information about how a distribution should be installed.

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/Zef-Configuration .
Comments and Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
