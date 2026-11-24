### =========================================================================
### append_zarr_array()
### -------------------------------------------------------------------------
###
### Nothing in this file is exported.
###


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### .update_zarr_shape()
###

### Hacky and ugly! :-/
.ZARR_V2_ARRAY_METADATA_FILE <- ".zarray"
.ZARR_V2_GROUP_METADATA_FILE <- ".zgroup"
.ZARR_V3_METADATA_FILE <- "zarr.json"

.get_zarr_metadata_path <- function(zarr_path, s3_client=NULL)
{
    zarr_path <- Rarr:::.normalize_array_path(zarr_path)
    metadata_files <- c(.ZARR_V2_ARRAY_METADATA_FILE,
                        .ZARR_V2_GROUP_METADATA_FILE,
                        .ZARR_V3_METADATA_FILE)
    ok <- Rarr:::.store_check_exist(zarr_path, files=metadata_files,
                                    s3_client=s3_client)
    nb_metadata_files <- sum(ok)
    if (nb_metadata_files != 1L) {
        in1string <- paste0("'", metadata_files, "'", collapse=", ")
        stop(wmsg("Invalid Zarr folder: ", zarr_path),
             "\n\n  ",
             wmsg("Folder should contain one of files ", in1string, ". ",
                  "Contains ", nb_metadata_files, ". Are you sure ",
                  "this is the path to a Zarr array or group?"))
    }
    ## Not using file.path() here because Rarr:::.normalize_array_path()
    ## above already added a trailing / to 'zarr_path'.
    paste0(zarr_path, names(ok)[ok])
}

.normarg_new_shape <- function(new_shape)
{
    if (!is.numeric(new_shape))
        stop(wmsg("'new_shape' must be a numeric vector"))
    if (length(new_shape) == 0L)
        stop(wmsg("'new_shape' cannot be an empty vector"))
    if (anyNA(new_shape) || any(new_shape < 0))
        stop(wmsg("'new_shape' cannot contain NAs or negative values"))
    trunc(new_shape)
}

### Only works for Zarr arrays in V3 format!
.update_zarr_shape <- function(zarr_path, new_shape)
{
    metadata_path <- .get_zarr_metadata_path(zarr_path)
    if (basename(metadata_path) == .ZARR_V2_GROUP_METADATA_FILE)
         stop(wmsg("Invalid Zarr array: ", zarr_path),
              "\n\n  ",
              wmsg("Zarr node is a group, not an array."))
    metadata <- Rarr:::.read_json_file(metadata_path)
    stopifnot(isSingleNumber(metadata$zarr_format),
              metadata$zarr_format %in% 2:3)
    if (metadata$zarr_format == 3L && metadata$node_type != "array")
        stop(wmsg("Invalid Zarr array: ", zarr_path),
             "\n\n",
             wmsg("Zarr node is a ", metadata$node_type, ", not an array."))
    stopifnot(is.list(metadata$shape))
    new_shape <- .normarg_new_shape(new_shape)
    if (length(new_shape) != length(metadata$shape))
        stop(wmsg("'new_shape' must preserve the number of dimensions ",
                  "(", length(metadata$shape), ") of the Zarr array to update"))
    metadata$shape <- as.list(new_shape)
    ## Calling write_json() here like Rarr:::.write_zarr_metadata() does
    ## to write the metadata.
    jsonlite::write_json(metadata, metadata_path,
                         auto_unbox=TRUE, pretty=TRUE, null="null")
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### append_zarr_array()
###
### Only supported for 1D arrays at the moment.
###

### Has its own unit tests in tests/testthat/test-append_zarr_array.R!
### IMPORTANT NOTE: append_zarr_array() is based on Rarr::update_zarr_array()
### which will **silently** alter the values in 'x' that don't fit in
### the 'data_type' of the destination array. For example, if 'data_type'
### is "uint8", then 'x' will silently be replaced with 'x %% 256' when
### written on disk.
### Returns the new length of the array.
append_zarr_array <- function(zarr_path, x)
{
    ## zarrlength() will fail if the array has more than 1 dimension.
    old_len <- zarrlength(zarr_path)
    x_len <- length(x)
    new_len <- old_len + x_len
    ## Note that Zarr stores the last chunk (also called edge or
    ## boundary chunk) as a full-sized chunk padded with the array’s
    ## designated 'fill_value'. This means that there's nothing really
    ## special about the last chunk and that we don't need to do anything
    ## about it when we increase the length of the array.
    .update_zarr_shape(zarr_path, new_len)
    Rarr::update_zarr_array(zarr_path, x, list(seq_len(x_len) + old_len))
    new_len
}

