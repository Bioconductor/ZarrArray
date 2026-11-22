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
###

### Only used in the unit tests at the moment.
get_zarr_format <- function(zarr_path, s3_client=NULL)
{
    stopifnot(isSingleString(zarr_path))
    Rarr:::.read_array_metadata(zarr_path, s3_client=s3_client)$zarr_format
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### zarrtype2Rtype()
###

zarrtype2Rtype <- function(base_type)
{
    stopifnot(isSingleString(base_type))
    switch(base_type, bool="logical",
                      int=, uint="integer",
                      float=, bfloat="double",
                      #complex="complex",
                      string=, unicode="character",
                      stop(wmsg("unrecognized Zarr base type: ", base_type)))
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
    dt <- Rarr:::.check_datatype(type, fill_value, nchar=nchar)
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


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### ZarrSparseMatrixSeed() utilities
###
### TODO: Should this go in a dedicated file e.g. ZarrSparseMatrixSeed-utils.R?
###

### Modeled after normarg_h5_filepath() in h5mread/R/utils.R
normarg_zarr_store <- function(zarr_store, what1="'zarr_store'",
                                           what2="the dataset")
{
    if (!isSingleString(zarr_store))
        stop(wmsg(what1, " must be a single string specifying the path ",
                  "to the Zarr store where ", what2, " is located"))
    file_path_as_absolute(zarr_store)  # return absolute path in canonical form
}

### Modeled after normarg_h5_name() in h5mread/R/utils.R
normarg_zarr_group <- function(group, what1="'group'",
                                      what2="the name of the group",
                                      what3="")
{
    if (!isSingleString(group))
        stop(wmsg(what1, " must be a single string specifying ",
                  what2, " in the Zarr store", what3))
    if (startsWith(group, "/")) {
        group <- sub("^/*", "/", group)  # only keep first leading slash
    } else {
        group <- paste0("/", group)
    }
    group
}

.form_zarr_path <- function(zarr_store, name="")
{
    stopifnot(isSingleString(name))
    if (startsWith(name, "/"))
        name <- substr(name, 2L, nchar(name))
    if (!nzchar(name))
        return(zarr_store)
    file.path(zarr_store, name)
}

zarr_exists <- function(zarr_store, name="")
{
    dir.exists(.form_zarr_path(zarr_store, name=name))
}

.zarr_node_type <- function(zarr_store, name="")
{
    zarr_path <- .form_zarr_path(zarr_store, name=name)
    if (file.exists(file.path(zarr_path, ".zarray")))
        return("array")
    if (file.exists(file.path(zarr_path, ".zgroup")))
        return("group")
    node_type <- Rarr:::.read_array_metadata(zarr_path)$node_type
    stopifnot(isSingleString(node_type), node_type %in% c("array", "group"))
    node_type
}

zarr_node_is_dataset <- function(zarr_store, name="")
{
    .zarr_node_type(zarr_store, name=name) == "array"
}

zarr_node_is_group <- function(zarr_store, name="")
{
    .zarr_node_type(zarr_store, name=name) == "group"
}

### Modeled after h5mread::stop_if_big_h5_dimensions().
stop_if_big_zarr_dimensions <- function(dim, zarr_store, name="",
                                        of_what="Zarr dataset",
                                        about_what=of_what)
{
    stopifnot(is.numeric(dim), isSingleString(zarr_store), isSingleString(name))
    if (all(dim <= .Machine$integer.max))
        return(invisible(NULL))
    dim_in1string <- paste0(dim, collapse=" x ")
    supports_what <- of_what
    if (endsWith(supports_what, "matrix")) {
        supports_what <- sub("matrix$", "matrices", supports_what)
    } else if (!endsWith(supports_what, "s")) {
        supports_what <- paste0(supports_what, "s")
    }
    stop(wmsg("Dimensions of ", of_what, " are too big: ", dim_in1string),
         "\n\n  ",
         wmsg("(This error is about ", about_what, " '", name, "' ",
              "from Zarr store '", zarr_store, "'.)"),
         "\n\n  ",
         wmsg("Please note that the ZarrArray package only ",
              "supports ", supports_what, " that have all their ",
              "dimensions <= 2^31-1 (= .Machine$integer.max)."))
}

.zarrdim <- function(zarr_store, name="", as.integer=TRUE)
{
    zarr_path <- .form_zarr_path(zarr_store, name=name)
    metadata <- Rarr:::.read_array_metadata(zarr_path)
    dim <- unlist(metadata$shape, use.names=FALSE)
    if (as.integer) {
        stop_if_big_zarr_dimensions(dim, zarr_store, name)
        dim <- as.integer(dim)
    }
    dim
}

### Length of a one-dimensional Zarr dataset.
### Returns the length as a single integer (if < 2^31) or numeric (if >= 2^31).
zarrlength <- function(zarr_store, name="")
{
    len <- .zarrdim(zarr_store, name=name, as.integer=FALSE)
    stopifnot(length(len) == 1L)
    len
}

