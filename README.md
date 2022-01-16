[![Actions Status](https://github.com/lizmat/Zef-Configuration/workflows/test/badge.svg)](https://github.com/lizmat/Zef-Configuration/actions)

NAME
====

Zef::Configuration - Manipulate Zef configurations

SYNOPSIS
========

```raku
use Zef::Configuration;
```

DESCRIPTION
===========

Zef::Configuration is a class that allows you to manipulate the configuration of Zef.

GENERAL NOTES
-------------

All of the attributes of the classes provided by this distribution, are either an `Array` (and thus mutable), or a an attribute with the `is rw` trait applied to it. This is generally ok, since it is expected that this module will mostly only be used by a relatively short-lived CLI.

Note that if you change an object that is based on one of the default objects, you will be changing the default as well. This may or may not be what you want. If it is not, then you should probably first create a `clone` of the object, or use the `clone` method with named arguments to create a clone with changed values.

METHODS ON ALL CLASSES
======================

All of these classes provided by this distribution provide these methods (apart from the standard methods provided by Raku).

### data

Return a Raku data-structure for the object. This is usually a `Map`, but can also be a `List`.

### json

Return a pretty JSON string with sorted keys for the object. Takes named parameters `:!pretty` and `:!sorted-keys` should you not want the JSON string to be pretty, or have sorted keys.

METHODS ON MOST CLASSES
=======================

With the exception of the `Zef::Configuration`, `Zef::Configuration::License` and `Zef::Configuration::RepositoryGroup` classes, the following attributes / methods are always provided.

### short-name

A name identifying the object. **Must** be specified in the creation of the object.

### module

The name of the Raku module to be used by this object. **Must** be specified in the creation of the object.

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

ADDITIONAL METHODS
------------------

### user-configuration

Class method that returns an `IO::Path` object of the configuration file that Zef is using by default.

### default-...

Methods for getting the default state of a given aspect of the `Zef::Configuration` object.

  * default-license

  * default-repositories

  * default-repositorygroups

  * default-fetch

  * default-extract

  * default-build

  * default-test

  * default-report

  * default-install

  * default-defaultCUR

Each of these can either called without any arguments: in that case a `Map` will be returned with each of the applicable objects, associated with a **tag**. Or it can be called with one of the valid tags, in which case the associated object will be returned.

Zef::Configuration::License
---------------------------

Contains which licenses are `blacklist`ed and which ones are `whitelist`ed. Defaults to no blacklisted licenses, and `"*"` in the whitelist, indicating that any license will be acceptable. Does not contain any other information.

Zef::Configuration::Repository
------------------------------

Contains the information about a repository in which distributions are located. It provided these additional attributes / methods:

### name

The full name of the repository. Defaults to the `short-name`.

### auto-update

The number of hours that should pass until a local copy of the distribution information about a repository should be considered stale. Defaults to `1`.

### uses-path

A boolean indicating whether the `path` field in the distribution should be used to obtain a distribution. Defaults to `False`, unless the repository's `short-name` equals `zef`.

### mirrors

An array of URLs that should be used to fetch the information about all the distributions in the repository.

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

COPYRIGHT AND LICENSE
=====================

Copyright 2022 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

