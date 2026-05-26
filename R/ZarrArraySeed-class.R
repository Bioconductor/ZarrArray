### =========================================================================
### ZarrArraySeed objects
### -------------------------------------------------------------------------


setClass("ZarrArraySeed",
    contains=c("Array", "OutOfMemoryObject"),
    slots=c(
        ## ----------------- user supplied slots -----------------
        zarr_path="character",     # Path must be absolute.
        s3_client="NULL_OR_list",  # NULL or a list produced by
                                   # paws.storage::s3().

        ## ------------ automatically populated slots ------------
        type="character",
        dim="integer",
        chunkdim="integer",
        fill_value="ANY"     # Not used for anything at the moment. Maybe
                             # drop it? Note that the fill_value slot can
                             # be set to NULL if the "fill value" could
                             # not be determined.
    )
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Validity
###

### TODO


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Getters path(), type(), dim(), and chunkdim()
###
### Note that none of these getters actually needs to access the disk.
###

setMethod("path", "ZarrArraySeed", function(object) object@zarr_path)
setMethod("type", "ZarrArraySeed", function(x) x@type)
setMethod("dim", "ZarrArraySeed", function(x) x@dim)
setMethod("chunkdim", "ZarrArraySeed", function(x) x@chunkdim)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### extract_array()
###

setMethod("extract_array", "ZarrArraySeed",
    function(x, index)
    {
        Rarr::read_zarr_array(x@zarr_path, index, x@s3_client)
    }
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### show()
###

setMethod("show", "ZarrArraySeed",
    function(object)
    {
        cat(S4Arrays:::array_as_one_line_summary(object), ":\n", sep="")
        cat("# path: ", path(object), "\n", sep="")
        cat("# chunkdim: ", paste(chunkdim(object), collapse=" x "),
            "\n", sep="")
        cat("# fill_value: ", object@fill_value, "\n", sep="")
    }
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Constructor
###

.zarr_path_is_remote <- function(zarr_path) grepl("^(https?|s3)://", zarr_path)

.extract_Rtype_from_metadata <- function(metadata)
{
    stopifnot(is.list(metadata), !is.null(names(metadata)))
    zarrtype2Rtype(metadata$datatype$base_type)
}

### Where to find the chunk dim information depends on whether the
### metadata comes from a Zarr v2 or v3 dataset, hence the gymnastics
### below. Note that this could be avoided by modifying get_zarr_metadata()
### so that it **always** return the metadata in Zarr v3 format.
### See IMPORTANT NOTE in R/utils.R.
.extract_chunkdim_from_metadata <- function(metadata)
{
    stopifnot(is.list(metadata), !is.null(names(metadata)))
    chunkdim <- metadata$chunks  # only in Zarr v2
    if (is.null(chunkdim)) {
        chunk_grid <- metadata$chunk_grid  # only in Zarr v3
        if (is.null(chunk_grid))
            stop(wmsg("unable to determine the chunk dimensions ",
                      "for this Zarr dataset"))
        if (!identical(chunk_grid$name, "regular"))
            stop(wmsg("only Zarr datasets with a regular chunk ",
                      "grid are supported at the moment"))
        chunkdim <- chunk_grid$configuration$chunk_shape
        if (is.null(chunkdim))
            stop(wmsg("unable to determine the chunk dimensions ",
                      "for this Zarr dataset"))
    }
    if (is.list(chunkdim))
        chunkdim <- unlist(chunkdim, use.names=FALSE)
    if (!is.numeric(chunkdim))
        stop(wmsg("malformed chunk dim information found ",
                  "in the metadata of this Zarr dataset"))
    if (!is.integer(chunkdim))
        chunkdim <- as.integer(chunkdim)
    if (S4Vectors:::anyMissingOrOutside(chunkdim, 0L))
        stop(wmsg("Zarr datasets with negative or NA chunk dimensions ",
                  "are not supported"))
    chunk_len <- prod(chunkdim)
    if (chunk_len > .Machine$integer.max)
        stop(wmsg("Each physical chunk in this Zarr dataset contains ",
                  chunk_len, " array elements, which is more than what ",
                  "ZarrArraySeed, ZarrArray, or DelayedArray objects ",
                  "can handle."),
             "\n  ",
             wmsg("DelayedArray objects and their derivatives (like ",
                  "ZarrArray objects) can only handle physical chunks ",
                  "made of less than 2^31 array elements each."))
    chunkdim
}

### Returns a NULL if the "fill value" cannot be determined. But can
### this ever happen? Also can be of the wrong type: see
### https://github.com/Huber-group-EMBL/Rarr/issues/137
.extract_fill_value_from_metadata <- function(metadata)
{
    stopifnot(is.list(metadata), !is.null(names(metadata)))
    ans <- metadata$fill_value
    if (is.null(ans))
        warning(wmsg("unable to determine the \"fill value\" ",
                     "for this Zarr dataset"))
    ans
}

ZarrArraySeed <- function(zarr_path, s3_client=NULL)
{
    if (!isSingleString(zarr_path))
        stop(wmsg("'zarr_path' must be a single string"))
    if (.zarr_path_is_remote(zarr_path)) {
        if (is.null(s3_client))
            s3_client <- Rarr:::.create_s3_client(zarr_path)
    } else {
        if (!dir.exists(zarr_path)) {
            msg <- "'zarr_path' must be the path to an existing directory"
            if (file.exists(zarr_path))
                msg <- paste0(msg, ", not a file")
            stop(wmsg(msg))
        }
        if (!is.null(s3_client))
            stop(wmsg("'s3_client' must be NULL when 'zarr_path' ",
                      "is a local path"))
    }
    zarr_path <- Rarr:::.normalize_array_path(zarr_path)
    metadata <- get_zarr_metadata(zarr_path, s3_client=s3_client)
    Rtype <- .extract_Rtype_from_metadata(metadata)
    dim <- as.integer(unlist(metadata$shape), use.names=FALSE)
    chunkdim <- .extract_chunkdim_from_metadata(metadata)
    fill_value <- .extract_fill_value_from_metadata(metadata)
    new2("ZarrArraySeed", zarr_path=zarr_path, s3_client=s3_client,
                          type=Rtype, dim=dim, chunkdim=chunkdim,
                          fill_value=fill_value)
}

