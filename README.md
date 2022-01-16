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

With the exception of the `Zef::Configuration::License` and `Zef::Configuration::RepositoryGroup` classes, the following methods are always provided.

### short-name

A name identifying the object. **Must** be specified in the creation of the object.

### module

The name of the Raku module to be used by this object. **Must** be specified in the creation of the object.

### enabled

A boolean indicating whether the object is enabled. Defaults to `True`.

### comment

Any comments applicable to this object. Defaults to the `Str` type object.

CLASSES
=======

Zef::Configuration
------------------

Zef::Configuration::License
---------------------------

Contains which licenses are `blacklist`ed and which ones are `whitelist`ed. Defaults to no blacklisted licenses, and `"*"` in the whitelist, indicating that any license will be acceptable. Does not contain any other information.

Zef::Configuration::Repository
------------------------------

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

