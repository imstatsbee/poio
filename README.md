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

- *source_type*: A string.  Either "r" or "c", depending upon whether the messages originated from R-level code, or C-level code.
- *file_type*: Either "po" or "pot", depending upon whether the messages originated from a PO (language-specific) or POT (master translation) file. Determined from the file name.
- *metadata*: A data frame of file metadata with columns "name" and "value".
- *direct*: A data frame of messages with a direct translation, with columns "msgid" and "msgstr".
- *countable*: A data frame of messages where the translation depends upon a countable value (as created by `ngettext`), with columns "msgid", "msgid_plural" and "msgstr".  The latter column contains a list of character vectors.

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
