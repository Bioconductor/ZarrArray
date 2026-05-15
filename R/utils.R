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

### Only used in the unit tests at the moment.
get_zarr_format <- function(zarr_path, s3_client=NULL)
{
    get_zarr_metadata(zarr_path, s3_client=s3_client)$zarr_format
}

### Returns the metadata in a named list.
get_zarr_metadata <- function(zarr_path, s3_client=NULL)
{
    stopifnot(isSingleString(zarr_path))
    Rarr:::.read_array_metadata(zarr_path, s3_client=s3_client)
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

