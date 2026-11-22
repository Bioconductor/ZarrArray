### =========================================================================
### writeZarrArray()
### -------------------------------------------------------------------------
###


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### ZarrRealizationSink objects
###
### The ZarrRealizationSink class is a concrete RealizationSink subclass that
### implements a realization sink for Zarr datasets. It must comply with
### the "sink contract". See R/RealizationSink-class.R in the DelayedArray
### package for the details of the "sink contract".
###

setClass("ZarrRealizationSink",
    contains="RealizationSink",
    representation(
        ## Slots that support the RealizationSink constructor contract.
        dim="integer",          # Naming this slot "dim" makes dim() work
                                # out of the box.
        type="character",       # Single string.

        ## Other slots.
        zarr_path="character",  # Single string.
        chunkdim="integer"      # An integer vector parallel to the 'dim' slot.
    )
)

setMethod("type", "ZarrRealizationSink", function(x) x@type)

setMethod("chunkdim", "ZarrRealizationSink", function(x) x@chunkdim)

.normarg_chunkdim <- function(chunkdim, dim)
{
    if (!(is.numeric(chunkdim) || is.logical(chunkdim) && all(is.na(chunkdim))))
        stop(wmsg("'chunkdim' must be NULL or an integer vector"))
    if (!is.integer(chunkdim))
        chunkdim <- as.integer(chunkdim)
    if (length(chunkdim) != length(dim))
        stop(wmsg("'chunkdim' must be an integer vector of length ",
                  "the number of dimensions of the object to write"))
    if (any(chunkdim < 0L, na.rm=TRUE))
        stop(wmsg("'chunkdim' cannot contain negative values"))
    if (!all(chunkdim <= dim, na.rm=TRUE))
        stop(wmsg("the chunk dimensions specified in 'chunkdim' exceed ",
                  "the dimensions of the object to write"))
    if (any(chunkdim == 0L & dim != 0L, na.rm=TRUE))
        stop(wmsg("'chunkdim' must contain nonzero values unless ",
                  "the zero values correspond to dimensions in the ",
                  "object to write that are also zero"))
    na_idx <- which(is.na(chunkdim))
    chunkdim[na_idx] <- dim[na_idx]
    if (prod(chunkdim) > .Machine$integer.max)
        stop(wmsg("The chunk dimensions in 'chunkdim' are too big. The ",
                  "product of the chunk dimensions should always be <= ",
                  ".Machine$integer.max"))
    chunkdim
}

### According to the "sink contract", the first 3 arguments must be 'dim',
### 'dimnames', and 'type'.
### Based on Rarr::create_empty_zarr_array() which only supports creation
### of Zarr v2 datasets at the moment (Rarr 1.11.24).
ZarrRealizationSink <- function(dim, dimnames=NULL, type="double",
                                zarr_path=NULL, chunkdim=NULL,
                                fill_value=NULL, nchar=NULL, zarr_version=3)
{
    dim <- S4Arrays:::normarg_dim(dim)
    if (!is.null(dimnames))
        warning(wmsg("'dimnames' is not supported and will be ignored"),
                immediate.=TRUE)
    if (is.null(zarr_path)) {
        zarr_path <- get_writeZarrArray_auto_path()
    } else {
        zarr_path <- Rarr:::.normalize_array_path(zarr_path)
    }
    if (is.null(chunkdim)) {
        chunkdim <- get_writeZarrArray_auto_chunkdim(dim)
    } else {
        chunkdim <- .normarg_chunkdim(chunkdim, dim)
    }
    create_empty_zarr_array2(zarr_path, dim, chunkdim, type,
                             fill_value=fill_value, nchar=nchar,
                             zarr_version=zarr_version)
    new2("ZarrRealizationSink", dim=dim, type=type,
                                zarr_path=zarr_path, chunkdim=chunkdim)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Writing data to a ZarrRealizationSink object
###

setMethod("write_block", "ZarrRealizationSink",
    function(sink, viewport, block)
    {
        if (!is.array(block))
            block <- as.array(block)
        ## If 'viewport' is empty then there's nothing to write.
        ## Note that Rarr::update_zarr_array() should be able to handle this
        ## but it doesn't at the moment (Rarr 1.11.24). So we skip the call
        ## to Rarr::update_zarr_array() when 'viewport' is empty.
        ## Also note that 'viewport' and 'block' are guaranteed to have
        ## the same dimensions.
        if (all(dim(viewport) != 0L)) {  # same as 'length(viewport) != 0L'
            index <- makeNindexFromArrayViewport(viewport,
                                                 expand.RangeNSBS=TRUE)
            Rarr::update_zarr_array(sink@zarr_path, x=block, index=index)
        }
        sink
    }
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Coercing a ZarrRealizationSink object
###

setAs("ZarrRealizationSink", "ZarrArraySeed",
    function(from) ZarrArraySeed(from@zarr_path)
)

setAs("ZarrRealizationSink", "ZarrArray",
    function(from) DelayedArray(as(from, "ZarrArraySeed"))
)

setAs("ZarrRealizationSink", "DelayedArray",
    function(from) DelayedArray(as(from, "ZarrArraySeed"))
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### writeZarrArray()
###

### Does NOT write dimnames(x) to disk at the moment!
### TODO: writeZarrArray() needs to write the array dimnames to disk.
### Does the Zarr format support this?
writeZarrArray <- function(x, zarr_path=NULL, chunkdim=NULL,
                              nchar=NULL, zarr_version=3,
                              verbose=NA)
{
    x_dim <- dim(x)
    if (is.null(x_dim))
        stop(wmsg("'x' must be an array-like object ",
                  "(i.e. it must have dimensions)"))
    x_type <- type(x)
    if (x_type == "character") {
        if (is.null(nchar)) {
            ## We use 'keepNA=TRUE' for now because we want to detect the
            ## presence of NAs in 'x' and fail early if we find any. That's
            ## because writing NAs to a Zarr dataset of type character is not
            ## supported yet. See
            ## https://github.com/Huber-group-EMBL/Rarr/issues/138
            ## TODO: Remove 'keepNA=TRUE' once writing NAs to a Zarr dataset
            ## of type character is supported.
            ## +1 to add NUL terminator.
            nchar <- compute_max_string_size(x, keepNA=TRUE) + 1L
            has_NAs <- is.na(nchar)
        } else {
            has_NAs <- anyNA(x)
        }
        ## TODO: Get rid of this once writing NAs to a Zarr dataset
        ## of type character is supported.
        if (has_NAs)
            stop(wmsg("input array has type() character and contains NAs --> ",
                      "this is not supported yet"))
    } else if (x_type == "logical") {
        ## Writing NAs to a Zarr dataset of type logical is not supported yet.
        ## See https://github.com/Huber-group-EMBL/Rarr/issues/138
        ## TODO: Get rid of this once writing NAs to a Zarr dataset
        ## of type logical is supported.
        if (anyNA(x))
            stop(wmsg("input array has type() logical and contains NAs --> ",
                      "this is not supported yet"))
    }
    verbose <- DelayedArray:::normarg_verbose(verbose)
    if (is.null(chunkdim))
        chunkdim <- chunkdim(x)
    sink <- ZarrRealizationSink(x_dim, NULL, x_type,
                                zarr_path=zarr_path, chunkdim=chunkdim,
                                nchar=nchar, zarr_version=zarr_version)
    sink <- BLOCK_write_to_sink(sink, x, verbose=verbose)
    as(sink, "ZarrArray")
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Coercion to ZarrArray
###
### The methods below write the array data to disk. Note that coercion from
### ZarrRealizationSink to ZarrArray is already taken care of by the specific
### method above and doesn't write anything to disk. So coercing to ZarrArray
### in general writes the array data to disk *except* when the object to
### coerce is a ZarrRealizationSink object.
###

### Writes to the ZarrArray realization dump by default.
### Unfortunately, the dimnames are NOT propagated because writeZarrArray()
### does NOT propagate them either. See TODO above.
.asZarrArray <- function(from) writeZarrArray(from)

setAs("ANY", "ZarrArray", .asZarrArray)

### Automatic coercion methods from DelayedArray to ZarrArray and from
### DelayedMatrix to ZarrMatrix silently return broken objects (unfortunately
### these dummy automatic coercion methods don't bother to validate the object
### they return). So we overwrite them.
setAs("DelayedArray", "ZarrArray", .asZarrArray)
setAs("DelayedMatrix", "ZarrMatrix", .asZarrArray)

