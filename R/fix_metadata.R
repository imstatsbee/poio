#' Fix metadata in a PO object
#'
#' Fixes the metadata in a \code{po} object, as generated by
#' \code{\link{read_po}}.
#' @param x An object of class \code{po}, or the data frame from the
#' \code{metadata} element of such an object.
#' @param pkg A path to the root of an R package source directory, or a
#' \code{package} object, as created by \code{\link[devtools]{as.package}}.
#' @param file_type A string giving the file type; either "po" or "pot".
#' @param clone Logical. If \code{TRUE}, the \code{po} object is cloned before
#' the metadata is fixed. This has a slight performance cost, but is easier to
#' reason about.
#' @param ... Named arguments of new metadata values.
#' @param .dots A named \code{list} of new metadata values.
#' @return An object of the same type as the input, but with the metadata fixed.
#' @details Columns are added to ensure that the metadata data frame contains
#' character columns named "name" and "value". Likewise rows are added or
#' updated as follows.
#' \describe{
#' \item{Project-Id-Version}{The package name and version, taken from the
#' "Package" and "Version" fields of the DESCRIPTION file specified in the
#' \code{pkg} argument.}
#' \item{Report-Msgid-Bugs-To}{The URL to report bugs to, taken from the
#' "BugReports" field of the DESCRIPTION file specified in the \code{pkg}
#' argument.}
#' \item{POT-Creation-Date}{Not auto-updated.}
#' \item{PO-Revision-Date}{The current date and time, in format
#' "%Y-%m-%d %H:%M:%S%z". See \code{\link[base]{strptime}} for details of date
#' and time formatting specifications.}
#' \item{Last-Translator}{Your name and email, creepily autodetected by
#' \code{\link[whoami]{whoami}}, where possible.}
#' \item{Language-Team}{Not auto-updated. Invent your own team name!}
#' \item{MIME-Version}{Always changed to "1.0".}
#' \item{Content-Type}{Always changed to "text/plain; charset=UTF-8".}
#' \item{Content-Transfer-Encoding}{Always changed to "8bit".}
#' }
#' Additionally PO, but not POT, files have these rows:
#' \describe{
#' \item{Language}{An ISO 639-1 two-letter language code.  See \url{http://www.loc.gov/standards/iso639-2/php/code_list.php}}
#' \item{Plural-Forms}{The plural-form specification for the Language code.}
#' }
#' @examples
#' pot_file <- system.file("extdata/R-summerof69.pot", package = "poio")
#' pot <- read_po(pot_file)
#' pot_fixed <- fix_metadata(pot, system.file(package = "poio"))
#'
#' # Choose your own metadata
#' pot_fixed2 <- fix_metadata(
#'   pot,
#'   system.file(package = "poio"),
#'   "Last-Translator" = "Dr. Daniel Jackson <djackson@stargate.com>",
#'   .dots  = list(
#'     "Language-Team" = "Team RL10N!"
#'   )
#' )
#'
#' # Compare the metadata before and after
#' pot$metadata
#' pot_fixed$metadata
#' @export
fix_metadata <- function(x, pkg = ".", ..., .dots = list())
{
  UseMethod("fix_metadata")
}

#' @rdname fix_metadata
#' @export
fix_metadata.po <- function(x, pkg = ".", clone = TRUE, file_type = x$file_type, ..., .dots = list())
{
  if(clone) {
    x <- x$clone()
  }
  # file_type arg is included to fix issue #17, but it's a bit silly to override
  # for po inputs
  if(file_type != x$file_type) {
    wrn <- sprintf(
      "You specified a file_type argument ('%s') that is different from the file_type of x ('%s').",
      file_type,
      x$file_type
    )
    warning(wrn)
  }
  x$metadata <- fix_metadata(x$metadata, pkg = pkg, file_type = file_type, ..., .dots = .dots)
  x
}

#' @rdname fix_metadata
#' @importFrom assertive.base coerce_to
#' @importFrom assertive.base merge_dots_with_list
#' @importFrom devtools as.package
#' @importFrom magrittr %>%
#' @export
fix_metadata.data.frame <- function(x, pkg = ".", file_type, ..., .dots = list())
{
  .dots = merge_dots_with_list(..., l = .dots)
  if(is.character(pkg))
  {
    pkg <- as.package(pkg)
  }
  x <- x %>%
    fix_metadata_columns() %>%
    fix_metadata_rows(file_type = file_type) %>%
    fix_metadata_project_id_version(pkg, .dots[["Project-Id-Version"]]) %>%
    fix_report_msgid_bugs_to(pkg, .dots[["Report-Msgid-Bugs-To"]]) %>%
    fix_po_revision_date(.dots[["PO-Revision-Date"]]) %>%
    fix_last_translator(.dots[["Last-Translator"]]) %>%
    fix_language_team(.dots[["Language-Team"]]) %>%
    fix_mime_version(.dots[["MIME-Version"]]) %>%
    fix_content_type(.dots[["Content-Type"]]) %>%
    fix_content_transfer_encoding(.dots[["Content-Transfer-Encoding"]])
  if(file_type == "po")
  {
    lang <- x %>%
      filter_(~ name == "Language") %>%
      select_(~ value) %>%
      extract2(1)
    if(is_empty(lang))
    {
      warning("No Language metadata field found. Adding an empty field; please manually set the value.")
      x <- x %>%
        bind_rows(
          data_frame(name = "Language", value = NA_character_)
        )
      return(x)
    }
    # Can't fix the Language field, but we can check its validity
    check_language(lang)
    x <- x %>%
      fix_plural_forms(lang)
  }
  x
}

fix_metadata_columns <- function(x)
{
  # Add missing columns
  required_columns <- c("name", "value")
  n <- nrow(x)
  for(column in required_columns)
  {
    if(is.null(x[[column]]))
    {
      msg <- gettextf(
        "Adding the missing column %s to the metadata.",
        sQuote(column)
      )
      message(msg)
      x[[column]] <- rep.int("INSERT VALUE HERE", n)
    }
  }
  x
}

#' @importFrom dplyr distinct_
fix_metadata_rows <- function(x, file_type = c("po", "pot"))
{
  file_type <- match.arg(file_type)
  required_rows <- c(
    "Project-Id-Version", "Report-Msgid-Bugs-To", "POT-Creation-Date",
    "PO-Revision-Date", "Last-Translator", "Language-Team",
    "MIME-Version", "Content-Type", "Content-Transfer-Encoding"
  )
  if(file_type == "po")
  {
    required_rows <- c(required_rows, "Language", "Plural-Forms")
  }
  for(row in required_rows)
  {
    if(!row %in% x[["name"]])
    {
      msg <- gettextf(
        "Adding the missing row %s to the metadata.",
        sQuote(row)
      )
      message(msg)
      x <- rbind(
        x,
        data.frame(name = row, value = character(1), stringsAsFactors = FALSE)
      )
    }
  }
  # Remove duplicate fields
  if(anyDuplicated(x$name))
  {
    message("Removing duplicate fields.")
    x <- x %>%
      distinct_("name")
  }
  x
}

fix_metadata_project_id_version <- function(x, pkg, newvalue)
{
  # Don't use with fn here since it throws an error if the fields don't exist
  # We want to use the warning mechanism in fix_field instead.
  # Notice that "package" and "version" are lowercase in the indexing since
  # devtools::as.package converts them, but uppercase in desc_fields since
  # those are the originals in the DESCRIPTION file.
  expected <- newvalue %mn% paste(pkg[["package"]], pkg[["version"]])
  fix_field(x, "Project-Id-Version", expected, pkg, c("Package", "Version"))
}

fix_report_msgid_bugs_to <- function(x, pkg, newvalue)
{
  expected <- newvalue %mn% pkg[["bugreports"]]
  fix_field(x, "Report-Msgid-Bugs-To", expected, pkg, "BugReports")
}

fix_po_revision_date <- function(x, newvalue)
{
  expected <- newvalue %mn% format(Sys.time(), "%Y-%m-%d %H:%M:%S%z")
  fix_field(x, "PO-Revision-Date", expected = expected)
}

#' @importFrom assertive.base parenthesize
#' @importFrom whoami fullname
#' @importFrom whoami email_address
fix_last_translator <- function(x, newvalue)
{
  expected <- newvalue %mn%
    paste(
      fullname("FULL NAME"),
      parenthesize(email_address("EMAIL@ADDRESS"), "angle_brackets")
    )
  fix_field(x, "Last-Translator", expected = expected)
}

fix_language_team <- function(x, newvalue)
{
  expected <- newvalue %mn% ""
  fix_field(x, "Language-Team", expected = expected)
}

fix_mime_version <- function(x, newvalue)
{
  expected <- newvalue %mn% "1.0"
  fix_field(x, "MIME-Version", expected = expected)
}

fix_content_type <- function(x, newvalue)
{
  expected <- newvalue %mn% "text/plain; charset=UTF-8"
  fix_field(x, "Content-Type", expected = expected)
}

fix_content_transfer_encoding <- function(x, newvalue)
{
  expected <- newvalue %mn% "8bit"
  fix_field(x, "Content-Transfer-Encoding", expected = expected)
}


fix_plural_forms <- function(x, lang, newvalue)
{
  expected <- newvalue %mn% lookup_plural_forms_for_language(lang)
  if(is.na(expected)) # unknown lang, already warned about
  {
    return(x)
  }
  fix_field(x, "Plural-Forms", expected = expected)
}

#' @importFrom assertive.base bapply
fix_field <- function(x, po_field, expected, pkg, desc_fields = character())
{
  # If user forced pkg = NULL, don't do anything
  if(!missing(pkg) && is.null(pkg))
  {
    msg <- gettextf(
      "No package data available; not fixing the %s field.",
      po_field
    )
    message(msg)
    return(x)
  }
  # If fields from the DESCRIPTION file are needed, check that they exist,
  # and warn otherwise.
  if(length(desc_fields) > 0L)
  {
    bad <- bapply(pkg[tolower(desc_fields)], is.null)
    if(any(bad))
    {
      wrn <- gettextf(
        "The package DESCRIPTION file does not have these required fields: %s.\nPlease add these fields to DESCRIPTION and re-run this function, or manually fix the %s field in your PO or POT file.",
        toString(sQuote(desc_fields[bad])),
        po_field
      )
      warning(wrn)
      return(x)
    }
  }
  # Update field, if necessary
  actual <- x %>%
    filter_(~ name == po_field) %>%
    select_(~ value) %>%
    extract2(1)
  if(actual != expected)
  {
    msg <- gettextf(
      "Updating the %s to %s.",
      po_field,
      sQuote(expected)
    )
    message(msg)
    x[x$name == po_field, "value"] <- expected
  }
  x
}

#' @importFrom assertive.types assert_is_a_string
check_language <- function(lang)
{
  assert_is_a_string(lang, severity = "warning")
  ok <- stri_detect_regex(lang, ALLOWED_LANGUAGE_REGEX)
  if(!ok)
  {
    wrn <- gettextf(
      "The language code %s is not supported by GNU gettext. See ?language_codes for possible values.",
      lang
    )
    warning(wrn)
  }
  invisible(ok)
}


`%mn%` <- function(x, y) {
  if(!missing(x) && !is.null(x)) x else y
}
