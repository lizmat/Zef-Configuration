use JSON::Fast:ver<0.17>:auth<cpan:TIMOTIMO>;

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
    has Int:D  $.auto-update is rw = 0;
    has Bool() $.uses-path   is rw = $!name eq 'fez';
    has Str:D  @.mirrors;

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
  :auto-update(1),
  :mirrors<https://360.zef.pm/>;
my constant $repo-cpan = Zef::Configuration::Repository.new:
  :short-name<cpan>,
  :module<Zef::Repository::Ecosystems>,
  :auto-update(1),
  :mirrors(
    "https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/cpan1.json",
    "https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/cpan.json",
    "git://github.com/ugexe/Perl6-ecosystems.git",
  );
my constant $repo-p6c = Zef::Configuration::Repository.new:
  :short-name<p6c>,
  :module<Zef::Repository::Ecosystems>,
  :auto-update(1),
  :mirrors(
    "https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/p6c1.json",
    "git://github.com/ugexe/Perl6-ecosystems.git",
    "http://ecosystem-api.p6c.org/projects1.json",
  );
my constant $repo-rea = Zef::Configuration::Repository.new:
  :short-name<rea>,
  :module<Zef::Repository::Ecosystems>,
  :auto-update(1),
  :enabled(0),
  :mirrors<https://raw.githubusercontent.com/Raku/REA/main/META.json>;
my constant $repo-cached = Zef::Configuration::Repository.new:
  :short-name<cached>,
  :module<Zef::Repository::LocalCache>;

#-------------------------------------------------------------------------------
# RepositoryGroup

class Zef::Configuration::RepositoryGroup does JSONify {
    has Zef::Configuration::Repository:D @.repositories;

    method TWEAK() {
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

class Zef::Configuration:ver<0.0.8>:auth<zef:lizmat> does JSONify {
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
        self.new: from-json $io.slurp
    }
    multi method new(Str:D $json) {
        self.new: from-json $json
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

=begin pod

=head1 NAME

Zef::Configuration - Manipulate Zef configurations

=head1 SYNOPSIS

=begin code :lang<raku>

use Zef::Configuration;

my $zc = Zef::Configuration.new;         # factory settings

my $zc = Zef::Configuration.new(:user);  # user settings

my $zc = Zef::Configuration.new($io);    # from a config file path

=end code

Or use the command-line interface:

    $ zef-configure

    $ zef-configure enable something

    $ zef-configure disable something

    $ zef-configure reset

=head1 DESCRIPTION

Zef::Configuration is a class that allows you to manipulate the configuration
of Zef programmatically.  Perhaps more importantly, it provides a command-line
script C<zef-configure> that allows you to perform simple actions to Zef's
config-files.

=head1 COMMAND-LINE INTERFACE

=head2 General named arguments

=head3 config-path

    $ zef-configure --config-path=~/.zef/config.json

The C<config-path> named argument can be used to indicate the location
of the configuration to read from / write to.

=head3 dry-run

    $ zef-configure enable rea --dry-run

The C<dry-run> named argument can be used to inhibit writing any changes
to the configuration file.

=head2 Possible actions

The C<zef-configure> script that is installed with this module, allows for
the following actions.  Please note that sub-commands (such as "enable")
can be shortened as long as they are not ambiguous..

=head2 Getting an overview

    $ zef-configure

Calling C<zef-configure> without any parameters (except maybe the
C<config-path> parameter) will show an overview of all the settings in
the configuration.  The names shown can be used to indicate what part
of the configuration you want changed.

=head2 Enabling a setting

    $ zef-configure enable rea

If a setting is disabled, then you can enable it with the C<enable>
directive, followed by the name of the setting you want enabled.

=head2 Disabling a setting

    $ zef-configure disable cpan

If a setting is enabled, then you can disable it with the C<disable>
directive, followed by the name of the setting you want disabled.

=head2 Reset to factory settings

    $ zef-configure reset

To completely reset a configuration to the "factory" settings, you can
use the C<reset> directive.

    $ zef-configure reset --config-path=~/.zef/config.json

You can also use this function in combination with C<config-=path> to
create a configuration file with the "factory" settings.

=head1 GENERAL NOTES

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

=head3 new

Apart from the normal way of creating objects with named arguments, one can
also specify a hash as returned with C<data> to create an object.

=head3 data

Return a Raku data-structure for the object.  This is usually a C<Map>, but
can also be a C<List>.

=head3 json

Return a pretty JSON string with sorted keys for the object.  Takes named
parameters C<:!pretty> and C<:!sorted-keys> should you not want the JSON
string to be pretty, or have sorted keys.

=head3 status

Return a string describing the status of the object.

=head1 METHODS ON MOST CLASSES

With the exception of the C<Zef::Configuration>, C<Zef::Configuration::License>
and C<Zef::Configuration::RepositoryGroup> classes, the following attributes /
methods are always provided.

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

=head1 Zef::Configuration

The C<Zef::Configuration> class contains all information about a configuration
of C<Zef>.  A C<Zef::Configuration> object can be made in 6 different ways:

=head2 CREATION

=begin code :lang<raku>

my $zc = Zef::Configuration.new;         # "factory settings"

my $zc = Zef::Configuration.new(:user);  # from the user's Zef config

my $zc = Zef::Configuration.new($io);    # from a file as an IO object

my $zc = Zef::Configuration.new($json);  # a string containing JSON

my $zc = Zef::Configuration.new(%hash);  # a hash, as decoded from JSON

my $zc = Zef::Configuration.new:         # named arguments to set attributes
  ConfigurationVersion => 2,
  RootDir              => 'foo/bar',
  ...
;

=end code

=head2 ATTRIBUTES / METHODS

It contains the following attributes / methods:

=head3 ConfigurationVersion

The version of the configuration.  Defaults to C<1>.

=head3 RootDir

The directory in which Zef keeps all of its information.  Defaults to
C<$*HOME/.zef>.

=head3 StoreDir

The directory in which Zef keeps all of the information that has been
downloaded.  Defaults to C<RootDir ~ "/store">.

=head3 TempDir

The directory in which Zef stores temporary files.  Defaults to
C<RootDir ~ "/tmp">.

=head3 License

A C<Zef::Configuration::License> object.  Defaults to
C<Zef::Configuration.default-licenses<default>>.

=head3 Repository

An array of C<Zef::Configuration::RepositoryGroup> objects in the order in
which they will be checked when searching for distributions.  Defaults to
C<Zef::Configuration.default-repository-groups> in the order: C<primary>,
C<secondary>, C<tertiary>, C<last>.

=head3 Fetch

An array of C<Zef::Configuration::Fetch> objects.  Defaults to
C<Zef::Configuration.default-fetch>.

=head3 Extract

An array of C<Zef::Configuration::Extract> objects.  Defaults to
C<Zef::Configuration.default-extract>.

=head3 Build

An array of C<Zef::Configuration::Build> objects.  Defaults to
C<Zef::Configuration.default-build>.

=head3 Test

An array of C<Zef::Configuration::Test> objects.  Defaults to
C<Zef::Configuration.default-test>.

=head3 Report

An array of C<Zef::Configuration::Report> objects.  Defaults to
C<Zef::Configuration.default-report>.

=head3 Install

An array of C<Zef::Configuration::Install> objects.  Defaults to
C<Zef::Configuration.default-install>.

=head3 DefaultCUR

An array of strings indicating which C<CompUnitRepository>(s) to be used when
installing a module.  Defaults to C<Zef::Configuration.default-defaultCUR>.

=head2 ADDITIONAL CLASS METHODS

=head3 is-configuration-writeable

Class method that takes an C<IO::Path> of a configuration file (e.g. as
returned by C<user-configuration>) and returns whether that file is safe
to write to (files part of the installation should not be written to).

=head3 new-user-configuration

Class method that returns an C<IO::Path> with location at which a new
configuration file can be stored, to be visible with future default
incantations of Zef.  Returns C<Nil> if no such location could be found.

=head3 user-configuration

Class method that returns an C<IO::Path> object of the configuration file
that Zef is using by default.

=head2 ADDITIONAL INSTANCE METHODS

=head3 default-...

Instance methods for getting the default state of a given aspect of the
C<Zef::Configuration> object.

=item default-license
=item default-repository
=item default-repositorygroup
=item default-fetch
=item default-extract
=item default-build
=item default-test
=item default-report
=item default-install
=item default-defaultCUR

Each of these can either called without any arguments: in that case a C<Map>
will be returned with each of the applicable objects, associated with a
B<tag>.  Or it can be called with one of the valid tags, in which case the
associated object will be returned.

=head3 object-from-tag

Instance method that allows selection of an object by its tag (usually the
C<short-name>) in one of the attributes of the C<Zef::Configuration> object.

Tags can be specified just by themselves if they are not ambiguous, else
the group name should be prefixed with a hyphen inbetween (e.g.
C<license-default>).

If an ambiguous tag is given, then a C<List> of C<Pair>s will be returned in
which the key is a group name, and the value is the associated object.

If only one object was found, then that will be returned.  If no objects
were found, then C<Nil> will be returned.

=head2 Zef::Configuration::License

Contains which licenses are C<blacklist>ed and which ones are C<whitelist>ed.
Defaults to no blacklisted licenses, and C<"*"> in the whitelist, indicating
that any license will be acceptable.  Does not contain any other information.

=head2 Zef::Configuration::Repository

Contains the information about a repository in which distributions are
located.  It provided these additional attributes / methods:

=head3 name

The full name of the repository.  Defaults to the C<short-name>.

=head3 auto-update

The number of hours that should pass until a local copy of the distribution
information about a repository should be considered stale.  Defaults to C<0>
indicating no automatic updating should be done.

=head3 uses-path

A boolean indicating whether the C<path> field in the distribution should be
used to obtain a distribution.  Defaults to C<False>, unless the repository's
C<short-name> equals C<zef>.

=head3 mirrors

An array of URLs that should be used to fetch the information about all the
distributions in the repository.

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
