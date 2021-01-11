# sml-unicode [![Build Status](https://travis-ci.org/diku-dk/sml-unicode.svg?branch=master)](https://travis-ci.org/diku-dk/sml-unicode)

This library makes it possible to process unicode stored in
[UTF8](http://en.wikipedia.org/wiki/UTF-8) format.

Just refer to the `unicode.mlb` file in your SML project. Then you can
use the structures `Utf8` and `UnicodeChars`. The `Utf8` structure
provides basic operations for processing UTF8 files. The
`UnicodeChars` structure provides bindings for a series of useful
unicode characters.


## Overview of MLB files

- `lib/github.com/diku-dk/sml-unicode/unicode.mlb`:

  - **signature** [`UTF8`](lib/github.com/diku-dk/sml-unicode/UTF8.sig)
  - **signature** [`UNICODE_CHARS`](lib/github.com/diku-dk/sml-unicode/UNICODE_CHARS.sig)
  - **structure** `Utf8` :> `UTF8`
  - **structure** `UnicodeChars` :> `UNICODE_CHARS`

## Use of the package

This library is set up to work well with the SML package manager
[smlpkg](https://github.com/diku-dk/smlpkg).  To use the package, in
the root of your project directory, execute the command:

```
$ smlpkg add github.com/diku-dk/sml-unicode
```

This command will add a _requirement_ (a line) to the `sml.pkg` file in your
project directory (and create the file, if there is no file `sml.pkg`
already).

To download the library into the directory
`lib/github.com/diku-dk/sml-unicode`, execute the command:

```
$ smlpkg sync
```

You can now reference the `mlb`-file using relative paths from within
your project's `mlb`-files.

Notice that you can choose either to treat the downloaded package as
part of your own project sources (vendoring) or you can add the
`sml.pkg` file to your project sources and make the `smlpkg sync`
command part of your build process.

## Authors

Copyright (c) 2015-2021 Martin Elsman, University of Copenhagen.
