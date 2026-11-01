# sml-unicode [![CI](https://github.com/diku-dk/sml-unicode/workflows/CI/badge.svg)](https://github.com/diku-dk/sml-unicode/actions)

This library provides operations for Unicode text stored in UTF-8 strings.

Refer to `unicode.mlb` in your SML project to use these structures:

- `Utf8` provides basic operations for processing UTF-8 text.
- `UnicodeChars` provides bindings for useful Unicode characters.
- `UnicodeNormalise` provides canonical composition (NFC) and decomposition
  (NFD) of UTF-8 strings.


## Overview of MLB files

- `lib/github.com/diku-dk/sml-unicode/unicode.mlb`:

  - **signature** [`UTF8`](lib/github.com/diku-dk/sml-unicode/UTF8.sig)
  - **signature** [`UNICODE_CHARS`](lib/github.com/diku-dk/sml-unicode/UNICODE_CHARS.sig)
  - **signature** [`UNICODE_NORMALISE`](lib/github.com/diku-dk/sml-unicode/unicode-normalise.sig)
  - **structure** `Utf8` :> `UTF8`
  - **structure** `UnicodeChars` :> `UNICODE_CHARS`
  - **structure** `UnicodeNormalise` :> `UNICODE_NORMALISE`

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

## Canonical normalisation

`UnicodeNormalise` implements the following interface:

```sml
signature UNICODE_NORMALISE = sig
    val nfc : string -> string
    val nfd : string -> string
end
```

For example, `å` can be represented by one code point or by `a` followed by
a combining ring. NFC gives both spellings the same composed representation;
NFD gives both the same decomposed representation:

```sml
val composed = UnicodeNormalise.nfc "a\204\138" (* UTF-8 å *)
val decomposed = UnicodeNormalise.nfd composed (* a + combining ring *)
```

The interface is documented in
[`unicode-normalise.sig`](lib/github.com/diku-dk/sml-unicode/unicode-normalise.sig).
Both functions accept and return UTF-8 strings, use Unicode 17.0.0, and raise
`Chr` for malformed UTF-8. They support supplementary characters and Hangul,
and preserve compatibility distinctions and unassigned code points.

The implementation uses the [UAX #15 section 9](https://www.unicode.org/reports/tr15/#Detecting_Normalization_Forms)
Quick_Check properties and
canonical combining-class order to return already-normalised strings without
building a normalised copy. NFC `Maybe` cases use the full algorithm. ASCII
has a separate fast path. The tables use the supplied Unicode properties,
including the context-sensitive cases discussed in section 9.2.

### Testing

Run the existing tests and normalisation regressions with `make test`.
For the full Unicode conformance suite:

```sh
curl -fL https://www.unicode.org/Public/17.0.0/ucd/NormalizationTest.txt -o /tmp/NormalizationTest.txt
make conformance NORMALIZATION_TEST=/tmp/NormalizationTest.txt
```

The conformance runner checks the NFC/NFD column relationships and identity
for every remaining Unicode scalar value.

### Regenerating the Unicode tables

Only table regeneration requires Python 3. Download `UnicodeData.txt` and
`DerivedNormalizationProps.txt` from
<https://www.unicode.org/Public/17.0.0/ucd/> into a directory, then run:

```sh
python3 tools/generate-normalisation.py /path/to/ucd > lib/github.com/diku-dk/sml-unicode/UnicodeNormaliseData.sml
```

The generator verifies pinned input hashes. Unicode data is covered by
[`tools/unicode-license.txt`](tools/unicode-license.txt); the generated tables
require no runtime files or external libraries.

## Authors

Copyright (c) 2015-2026 Martin Elsman, University of Copenhagen.
Normalisation added with help from GPT-6.1 Sol Light
