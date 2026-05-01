### =========================================================================
### Some low-level utilities
### -------------------------------------------------------------------------
###
### Nothing in this file is exported.
###


trim_trailing_slashes <- function(x)
{
    sub("/*$", "", x)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### get_zarr_format()
### get_zarr_metadata()
###

.ZARR_V2_METADATA_FILE <- ".zarray"
.ZARR_V3_METADATA_FILE <- "zarr.json"

.get_zarr_metadata_file <- function(zarr_path, s3_client=NULL)
{
    stopifnot(S4Vectors:::has_suffix(zarr_path, "/"))
    metadata_files <- c(.ZARR_V2_METADATA_FILE, .ZARR_V3_METADATA_FILE)
    ok <- Rarr:::.file_or_blob_exists(zarr_path, s3_client, metadata_files)
    if (!any(ok))
        stop(wmsg("No Zarr metadata file ('", .ZARR_V2_METADATA_FILE, "' ",
                  "or '", .ZARR_V3_METADATA_FILE, "') found in: ", zarr_path),
             "\n  ",
             wmsg("Are you sure this is the path to a Zarr dataset?"))
    if (all(ok))
        stop(wmsg("Invalid Zarr dataset at: ", zarr_path),
             "\n  ",
             wmsg("Directory contains Zarr metadata files ",
                   "'", .ZARR_V2_METADATA_FILE, "' and ",
                   "'", .ZARR_V3_METADATA_FILE, "'. Should contain one ",
                   "or the other, but not both."))
    names(ok)[ok]
}

### Only used in the unit tests at the moment.
get_zarr_format <- function(zarr_path, s3_client=NULL)
{
    stopifnot(isSingleString(zarr_path))
    metadata_file <- .get_zarr_metadata_file(zarr_path, s3_client=s3_client)
    if (metadata_file == .ZARR_V3_METADATA_FILE) 3L else 2L
}

### Returns the metadata in a named list.
### IMPORTANT NOTE: The exact components of the named list and their names
### depend on the Zarr version (a.k.a. Zarr format) of the Zarr dataset,
### which can be 2 or 3. However, the Rarr package has
### Rarr:::.convert_metadata_version() for converting the metadata
### to a given version. This is something that we could use in
### get_zarr_metadata() to always return the metadata in the same
### form e.g. in the form that corresponds to Zarr v3.
get_zarr_metadata <- function(zarr_path, s3_client=NULL)
{
    stopifnot(isSingleString(zarr_path))
    metadata_file <- .get_zarr_metadata_file(zarr_path, s3_client=s3_client)
    Rarr:::.read_array_metadata(zarr_path, metadata_file, s3_client=s3_client)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### zarrtype2Rtype()
###

zarrtype2Rtype <- function(base_type)
{
    stopifnot(isSingleString(base_type))
    switch(base_type, bool="logical",
                      int=, uint="integer",
                      float="double",
                      #complex="complex",
                      string=, unicode="character",
                      stop(wmsg("unreocgnized Zarr base type: ", base_type)))
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### compute_max_string_size()
###

### Copied and adapted from h5mread/R/utils.R
compute_max_string_size <- function(x, keepNA=FALSE)
{
    ## We want this to work on any array-like object, not just ordinary
    ## arrays, so we must use type() instead of is.character().
    if (type(x) != "character")
        return(NULL)
    if (length(x) == 0L)
        return(0L)
    ## Calling nchar() on 'x' will trigger block processing if 'x' is a
    ## DelayedArray object, so it could take a while.
    max(nchar(x, type="bytes", keepNA=keepNA))
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### create_empty_zarr_array2()
###

.normarg_fill_value <- function(fill_value, type, nchar=NULL)
{
    if (is.null(fill_value)) {
        dt <- Rarr:::.check_datatype(type, nchar=nchar)
    } else {
        dt <- Rarr:::.check_datatype(type, fill_value, nchar=nchar)
    }
    stopifnot(identical(names(dt), c("data_type", "fill_value")))
    dt$fill_value
}

### Rarr:::create_empty_zarr_array() interface is too messy. This wrapper
### tries to simplify it a little. We also perform our own sanity checks
### of user input (shallow checks only). Note that we don't handle
### original arguments 'order', 'compressor', 'dimension_separator',
### and 'dimension_names' for now.
create_empty_zarr_array2 <-
    function(zarr_path, dim, chunkdim, type,
             fill_value=NULL, nchar=NULL, zarr_version=3)
{
    stopifnot(isSingleString(zarr_path),
              is.integer(dim), is.integer(chunkdim),
              length(dim) == length(chunkdim),
              !anyNA(dim), !anyNA(chunkdim),
              isSingleString(type))
    fill_value <- .normarg_fill_value(fill_value, type, nchar=nchar)
    if (!(isSingleNumber(zarr_version) && zarr_version %in% 2:3))
        stop(wmsg("'zarr_version' must be 3 or 2"))
    Rarr::create_empty_zarr_array(zarr_path, dim, chunkdim, type,
                                  fill_value=fill_value, nchar=nchar,
                                  zarr_version=zarr_version)
}

