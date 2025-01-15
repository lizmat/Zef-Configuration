[![Actions Status](https://github.com/lizmat/Zef-Configuration/actions/workflows/linux.yml/badge.svg)](https://github.com/lizmat/Zef-Configuration/actions) [![Actions Status](https://github.com/lizmat/Zef-Configuration/actions/workflows/macos.yml/badge.svg)](https://github.com/lizmat/Zef-Configuration/actions) [![Actions Status](https://github.com/lizmat/Zef-Configuration/actions/workflows/windows.yml/badge.svg)](https://github.com/lizmat/Zef-Configuration/actions)

NAME
====

Zef::Configuration - Manipulate Zef configurations

SYNOPSIS
========

```raku
use Zef::Configuration;

my $zc = Zef::Configuration.new;         # factory settings

my $zc = Zef::Configuration.new(:user);  # user settings

my $zc = Zef::Configuration.new($io);    # from a config file path
```

Or use the command-line interface:

    $ zef-configure

    $ zef-configure enable something

    $ zef-configure disable something

    $ zef-configure reset

DESCRIPTION
===========

Zef::Configuration is a class that allows you to manipulate the configuration of Zef programmatically. Perhaps more importantly, it provides a command-line script `zef-configure` that allows you to perform simple actions to Zef's config-files.

COMMAND-LINE INTERFACE
======================

General named arguments
-----------------------

### config-path

    $ zef-configure --config-path=~/.zef/config.json

The `config-path` named argument can be used to indicate the location of the configuration to read from / write to.

### dry-run

    $ zef-configure enable rea --dry-run

The `dry-run` named argument can be used to inhibit writing any changes to the configuration file.

Possible actions
----------------

The `zef-configure` script that is installed with this module, allows for the following actions. Please note that sub-commands (such as "enable") can be shortened as long as they are not ambiguous..

Getting an overview
-------------------

    $ zef-configure

Calling `zef-configure` without any parameters (except maybe the `config-path` parameter) will show an overview of all the settings in the configuration. The names shown can be used to indicate what part of the configuration you want changed.

Enabling a setting
------------------

    $ zef-configure enable rea

If a setting is disabled, then you can enable it with the `enable` directive, followed by the name of the setting you want enabled.

Disabling a setting
-------------------

    $ zef-configure disable cpan

If a setting is enabled, then you can disable it with the `disable` directive, followed by the name of the setting you want disabled.

Reset to factory settings
-------------------------

    $ zef-configure reset

To completely reset a configuration to the "factory" settings, you can use the `reset` directive.

    $ zef-configure reset --config-path=~/.zef/config.json

You can also use this function in combination with `config-=path` to create a configuration file with the "factory" settings.

GENERAL NOTES
=============

All of the attributes of the classes provided by this distribution, are either an `Array` (and thus mutable), or a an attribute with the `is rw` trait applied to it. This is generally ok, since it is expected that this module will mostly only be used by a relatively short-lived CLI.

Note that if you change an object that is based on one of the default objects, you will be changing the default as well. This may or may not be what you want. If it is not, then you should probably first create a `clone` of the object, or use the `clone` method with named arguments to create a clone with changed values.

METHODS ON ALL CLASSES
======================

All of these classes provided by this distribution provide these methods (apart from the standard methods provided by Raku).

### new

Apart from the normal way of creating objects with named arguments, one can also specify a hash as returned with `data` to create an object.

### data

Return a Raku data-structure for the object. This is usually a `Map`, but can also be a `List`.

### json

Return a pretty JSON string with sorted keys for the object. Takes named parameters `:!pretty` and `:!sorted-keys` should you not want the JSON string to be pretty, or have sorted keys.

### status

Return a string describing the status of the object.

METHODS ON MOST CLASSES
=======================

With the exception of the `Zef::Configuration`, `Zef::Configuration::License` and `Zef::Configuration::RepositoryGroup` classes, the following attributes / methods are always provided.

### short-name

A name identifying the object. **Must** be specified in the creation of the object.

### module

The name of the Raku module to be used by this object. **Must** be specified in the creation of the object unless there is a default available for the given object.

### enabled

A boolean indicating whether the object is enabled. Defaults to `True`.

### comment

Any comments applicable to this object. Defaults to the `Str` type object.

Zef::Configuration
==================

The `Zef::Configuration` class contains all information about a configuration of `Zef`. A `Zef::Configuration` object can be made in 6 different ways:

CREATION
--------

```raku
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
```

ATTRIBUTES / METHODS
--------------------

It contains the following attributes / methods:

### ConfigurationVersion

The version of the configuration. Defaults to `1`.

### RootDir

The directory in which Zef keeps all of its information. Defaults to `$*HOME/.zef`.

### StoreDir

The directory in which Zef keeps all of the information that has been downloaded. Defaults to `RootDir ~ "/store"`.

### TempDir

The directory in which Zef stores temporary files. Defaults to `RootDir ~ "/tmp"`.

### License

A `Zef::Configuration::License` object. Defaults to `Zef::Configuration.default-licenses<default>`.

### Repository

An array of `Zef::Configuration::RepositoryGroup` objects in the order in which they will be checked when searching for distributions. Defaults to `Zef::Configuration.default-repository-groups` in the order: `primary`, `secondary`, `tertiary`, `last`.

### Fetch

An array of `Zef::Configuration::Fetch` objects. Defaults to `Zef::Configuration.default-fetch`.

### Extract

An array of `Zef::Configuration::Extract` objects. Defaults to `Zef::Configuration.default-extract`.

### Build

An array of `Zef::Configuration::Build` objects. Defaults to `Zef::Configuration.default-build`.

### Test

An array of `Zef::Configuration::Test` objects. Defaults to `Zef::Configuration.default-test`.

### Report

An array of `Zef::Configuration::Report` objects. Defaults to `Zef::Configuration.default-report`.

### Install

An array of `Zef::Configuration::Install` objects. Defaults to `Zef::Configuration.default-install`.

### DefaultCUR

An array of strings indicating which `CompUnitRepository`(s) to be used when installing a module. Defaults to `Zef::Configuration.default-defaultCUR`.

ADDITIONAL CLASS METHODS
------------------------

### is-configuration-writeable

Class method that takes an `IO::Path` of a configuration file (e.g. as returned by `user-configuration`) and returns whether that file is safe to write to (files part of the installation should not be written to).

### new-user-configuration

Class method that returns an `IO::Path` with location at which a new configuration file can be stored, to be visible with future default incantations of Zef. Returns `Nil` if no such location could be found.

### user-configuration

Class method that returns an `IO::Path` object of the configuration file that Zef is using by default.

ADDITIONAL INSTANCE METHODS
---------------------------

### default-...

Instance methods for getting the default state of a given aspect of the `Zef::Configuration` object.

  * default-license

  * default-repository

  * default-repositorygroup

  * default-fetch

  * default-extract

  * default-build

  * default-test

  * default-report

  * default-install

  * default-defaultCUR

Each of these can either called without any arguments: in that case a `Map` will be returned with each of the applicable objects, associated with a **tag**. Or it can be called with one of the valid tags, in which case the associated object will be returned.

### object-from-tag

Instance method that allows selection of an object by its tag (usually the `short-name`) in one of the attributes of the `Zef::Configuration` object.

Tags can be specified just by themselves if they are not ambiguous, else the group name should be prefixed with a hyphen inbetween (e.g. `license-default`).

If an ambiguous tag is given, then a `List` of `Pair`s will be returned in which the key is a group name, and the value is the associated object.

If only one object was found, then that will be returned. If no objects were found, then `Nil` will be returned.

Zef::Configuration::License
---------------------------

Contains which licenses are `blacklist`ed and which ones are `whitelist`ed. Defaults to no blacklisted licenses, and `"*"` in the whitelist, indicating that any license will be acceptable. Does not contain any other information.

Zef::Configuration::Repository
------------------------------

Contains the information about a repository in which distributions are located. It provided these additional attributes / methods:

### name

The full name of the repository. Defaults to the `short-name`.

### module

The Raku module to be used for handling the `Zef::Configuration::Repository` defaults to `Zef::Repository::Ecosystems`.

### auto-update

The number of hours that should pass until a local copy of the distribution information about a repository should be considered stale. Defaults to `1`.

### uses-path

A boolean indicating whether the `path` field in the distribution should be used to obtain a distribution. Defaults to `False`, unless the repository's `short-name` equals `zef`.

### mirrors

An array of URLs that should be used to fetch the information about all the distributions in the repository. **Must** be specified with the URL of at least one mirror if `auto-update` has been (implicitely) set to a non-zero value.

Zef::Configuration::RepositoryGroup
-----------------------------------

Contains a list of `Zef::Configuration::Repository` objects in the order in which a search should be done for modules. Does not contain any other information.

Zef::Configuration::Fetch
-------------------------

Information on how to fetch a distribution from a `Zef::Configuration::Repository`.

Zef::Configuration::Extract
---------------------------

Information on how to extract information from a fetched distribution.

Zef::Configuration::Build
-------------------------

Information on how to build modules from a fetched distribution.

Zef::Configuration::Test
------------------------

Information on how to perform tesing on a fetched distribution.

Zef::Configuration::Report
--------------------------

Information about how a report of a distribution test should be reported.

Zef::Configuration::Install
---------------------------

Information about how a distribution should be installed.

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/Zef-Configuration . Comments and Pull Requests are welcome.

If you like this module, or what I’m doing more generally, committing to a [small sponsorship](https://github.com/sponsors/lizmat/) would mean a great deal to me!

COPYRIGHT AND LICENSE
=====================

Copyright 2022, 2023, 2024, 2025 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

