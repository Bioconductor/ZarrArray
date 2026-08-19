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

### Modelled after normarg_h5_filepath() in h5mread/R/utils.R
normarg_zarr_store <- function(zarr_store, what1="'zarr_store'",
                                           what2="the dataset")
{
    if (!isSingleString(zarr_store))
        stop(wmsg(what1, " must be a single string specifying the path ",
                  "to the Zarr store where ", what2, " is located"))
    file_path_as_absolute(zarr_store)  # return absolute path in canonical form
}

### Modelled after normarg_h5_name() in h5mread/R/utils.R
normarg_zarr_group <- function(name, what1="'name'",
                                     what2="the name of a dataset",
                                     what3="")
{
    if (!isSingleString(name))
        stop(wmsg(what1, " must be a single string specifying ",
                  what2, " in the Zarr store", what3))
    if (name == "")
        stop(wmsg(what1, " cannot be the empty string"))
    if (startsWith(name, "/")) {
        name <- sub("^/*", "/", name)  # only keep first leading slash
    } else {
        name <- paste0("/", name)
    }
    name
}

zarr_exists <- function(zarr_store, name)
{
    dir.exists(file.path(zarr_store, name))
}

.zarr_node_type <- function(zarr_store, name)
{
    zarr_path <- file.path(zarr_store, name)
    if (file.exists(file.path(zarr_path, ".zarray")))
        return("array")
    if (file.exists(file.path(zarr_path, ".zgroup")))
        return("group")
    node_type <- Rarr:::.read_array_metadata(zarr_path)$node_type
    stopifnot(isSingleString(node_type), node_type %in% c("array", "group"))
    node_type
}

zarr_node_is_dataset <- function(zarr_store, name)
{
    .zarr_node_type(zarr_store, name) == "array"
}

zarr_node_is_group <- function(zarr_store, name)
{
    .zarr_node_type(zarr_store, name) == "group"
}

### Copied and adapted from h5mread/R/h5dim.R
dim_as_integer <- function(dim, zarr_store, name, what="Zarr dataset")
{
    if (is.integer(dim))
        return(dim)
    if (any(dim > .Machine$integer.max)) {
        dim_in1string <- paste0(dim, collapse=" x ")
        stop(wmsg("Dimensions of ", what, " are too big: ", dim_in1string),
             "\n\n  ",
             wmsg("(This error is about Zarr dataset '", name, "' ",
                  "from Zarr store '", zarr_store, "'.)"),
             "\n\n  ",
             wmsg("Please note that the ZarrArray package only ",
                  "supports datasets where each dimension is ",
                  "<= '.Machine$integer.max' (= 2**31 - 1)."))
    }
    as.integer(dim)
}

.zarrdim <- function(zarr_store, name, as.integer=TRUE)
{
    metadata <- Rarr:::.read_array_metadata(file.path(zarr_store, name))
    dim <- unlist(metadata$shape, use.names=FALSE)
    if (as.integer)
        dim <- dim_as_integer(dim, zarr_store, name)
    dim
}

### Length of a one-dimensional Zarr dataset.
### Return the length as a single integer (if < 2^31) or numeric (if >= 2^31).
zarrlength <- function(zarr_store, name)
{
    len <- .zarrdim(zarr_store, name, as.integer=FALSE)
    stopifnot(length(len) == 1L)
    len
}

