[![Project Status: Active - The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/0.1.0/active.svg)](http://www.repostatus.org/#active)

# **poio**: Input/Output Functionality for "PO" and "POT" Message Translation Files

R packages use a text file format with a `.po` extension to store translations of messages, warnings, and errors.  **poio** provides functionality to read in these files, fix the metadata, and write the objects back to file.

## Installation

To install the development version, you first need the *devtools* package.


```r
install.packages("devtools")
```

Then you can install the **poio** package using


```r
devtools::install_bitbucket("RL10N/poio")
```

## Functions

`read_po` reads PO and POT files into R, and stores them as an object of class `"po"` (see below for details).

`fix_metadata` fixes the metadata in a `po` object.

`generate_po_from_pot` generates a PO object from a POT object.

`write_po` writes `po` objects back to a PO file.

## PO Objects

`po` objects are lists with class `"po"` (to allow S3 methods), containing the following elements:

- *source_type*: A string.  Either `"r"` or `"c"`, depending upon whether the messages originated from R-level code, or C-level code.
- *file_type*: Either `"po"` or `"pot"`, depending upon whether the messages originated from a PO (language-specific) or POT (master translation) file. Determined from the file name.
- *initial_comments*: A `character` vector of comments added by the translator.
- *metadata*: A `data_frame` of file metadata with columns "name" and "value".
- *direct*: A `data_frame` of messages with a direct translation, as created by `stop`,
`warning`, `message` or`gettext`; its columns are described below.
- *countable*: A `data_frame`of messages where the translation depends upon a countable value, as created by `ngettext`; its columns are described below.

The `direct` element of the `po` object has the following columns.

- *msgid*: Character. The untranslated (should be American English) message.
- *msgstr*: Character. The translated message, or empty strings in the case of POT files.
- *is_obsolete*: Logical. Is the message obsolete?
- *translator_comments*: List of character. Comments added by the translator, typically to explain unclear messages, or why translation choices were made.
- *source_reference_comments*: List of character. Links to where the message occured in the source, in the form "filename:line".
- *flags_comments*: List of character. Typically used to describe formatting directives. R uses C-style formatting, which would imply a `"c-format"` flag.  For example `%d` denotes an integer, and `%s` denotes a string. `"fuzzy"` flags can appear when PO files are merged.
- *previous_string_comment*: List of character. When PO files are merged with an updated POT file ,and a fuzzy flag is generated, the old msgid is stored in a previous string comment.

The `countable` element of the `po` object takes the same form as the `direct` element, with two differences.

- *msgid_plural*: Character. The plural form of the untranslated message.
- *msgstr*: This is now a list of character (rather than character.)

## Examples

A typical workflow begins by generating a POT master translation file for a package using `tools::xgettext2pot`.  In this case, we'll use a sample file stored in the **poio** package.


```r
pot_file <- system.file("extdata/R-poio.pot")
pot <- read_po(pot_file)
```

`tools::xgettext2pot` makes a mess of some of the metadata element that it generates, so they need fixing.


```r
pot_fixed <- fix_metadata(pot)
```

Now you need to choose some languages to translate your messages into.  Suitable language codes can be found in the `language_codes` dataset included in the package.


```r
data(language_codes)
str(language_codes, vec.len = 8)
```

```
## List of 2
##  $ language: chr [1:245] "aa" "ab" "ace" "ae" "af" "ak" "am" "an" ...
##  $ country : chr [1:249] "AD" "AE" "AF" "AG" "AI" "AL" "AM" "AO" ...
```

Then, for each language that you want to create a translation for, generate a `po` object and write it to file. If your current working directory is the root of your package, the correct file name is automatically generated.


```r
for(lang in c("de", "fr_BE"))
{
  po <- generate_po_from_pot(pot, lang)
  write_po(po)
}
```

## See Also

The [*msgtools*](http://github.com/RL10N/msgtools) package, which has higher level tools for working with messages and translations.

The Pology python library has some useful [*documentation on the PO file format*](http://pology.nedohodnik.net/doc/user/en_US/ch-poformat.html).

The GNU [*gettext*](https://www.gnu.org/software/gettext/manual/html_node/index.html) utility.

## Acknowledgements

This package was developed as part of the [*RL10N*](https://rl10n.github.io) project, funded by the [R Consortium](https://www.r-consortium.org/).

