### =========================================================================
### Control Zarr realization settings
### -------------------------------------------------------------------------
###
### The functionality implemented in this file is the ZarrArray equivalent
### of the HDF5 dump management stuff implemented in the HDF5Array package
### (see R/dump-management.R in HDF5Array).
### TODO: Investigate the feasibility of making this stuff more generic so
### we can move it to its own package (e.g. DelayedArrayRealization).
### Ideally we'd want to be able to reuse it across the HDF5RealizationSink,
### TENxRealizationSink, ZarrRealizationSink, and TileDBRealizationSink
### constructors. Also maybe move files RealizationSink-class.R and realize.R
### from DelayedArray to DelayedArrayRealization?
### Important question: What kind of relationship will DelayedArrayRealization
### and DelayedArray have? Will we need to make DelayedArrayRealization depend
### on DelayedArray or will it need to be the other way around?
### Cleanest design would be to avoid any strong dep between the two, and
### have them suggest one each other.


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### get/set_Zarr_realization_dump_dir()
###

get_Zarr_realization_dump_dir <- function()
{
    get_ZarrArray_option("realization.dump.dir")
}

### Create directory 'dir' if it doesn't exist yet.
.set_dump_dir <- function(dir)
{
    ## Even though file_path_as_absolute() will trim the trailing slashes,
    ## we need to do this early. Otherwise, checking for the existence of a
    ## file of the same name as the to-be-created directory will fail.
    if (nchar(dir) > 1L)
        dir <- trim_trailing_slashes(dir)
    if (!dir.exists(dir)) {
        if (file.exists(dir))
            stop(wmsg("\"", dir, "\" already exists and is a file, ",
                      "not a directory"))
        if (!suppressWarnings(dir.create(dir)))
            stop(wmsg("cannot create directory \"", dir, "\""))
    }
    dir <- file_path_as_absolute(dir)
    set_ZarrArray_option("realization.dump.dir", dir)
}

### Called by .onLoad() hook (see zzz.R file).
set_Zarr_realization_dump_dir <- function(dir)
{
    if (missing(dir)) {
        dir <- file.path(tempdir(), "Zarr_realization_dump")
    } else if (!isSingleString(dir) || !nzchar(dir)) {
        stop(wmsg("'dir' must be a non-empty string specifying the path ",
                  "to a new or existing directory"))
    }
    invisible(.set_dump_dir(dir))
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### get_Zarr_realization_auto_path()
###

### Returns the *absolute path* to the realization directory.
get_Zarr_realization_auto_path <- function()
{
    tempfile(pattern="auto_", tmpdir=get_Zarr_realization_dump_dir(),
             fileext=".zarr")
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### get/set_Zarr_realization_chunk_maxsize()
### get_Zarr_realization_chunk_maxlen()
###

get_Zarr_realization_chunk_maxsize <- function()
{
    get_ZarrArray_option("realization.chunk.maxsize")
}

### Chunk max size is in bytes.
### Called by .onLoad() hook (see zzz.R file).
set_Zarr_realization_chunk_maxsize <- function(maxsize=1000000L)
{
    set_ZarrArray_option("realization.chunk.maxsize", maxsize)
}

get_Zarr_realization_chunk_maxlen <- function(type)
{
    if (missing(type))
        stop(wmsg("Please specify the type() of the array data. ",
                  "See '?get_Zarr_realization_chunk_maxlen'."))
    if (!isSingleString(type))
        stop(wmsg("'type' must be a single string"))
    type_size <- get_type_size(type)
    chunk_maxsize <- get_Zarr_realization_chunk_maxsize()
    ans <- chunk_maxsize / type_size
    if (ans > .Machine$integer.max)
        stop(wmsg("The maximum chunk length is too big. Chunks of length ",
                  "> .Machine$integer.max are not supported. Please reduce ",
                  "the maximum chunk length by reducing the maximum chunk ",
                  "size with set_Zarr_realization_chunk_maxsize()."))
    max(as.integer(ans), 1L)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### get/set_Zarr_realization_chunk_shape()
###

get_Zarr_realization_chunk_shape <- function()
{
    get_ZarrArray_option("realization.chunk.shape")
}

### Called by .onLoad() hook (see zzz.R file).
set_Zarr_realization_chunk_shape <- function(shape="scale")
{
    set_ZarrArray_option("realization.chunk.shape", shape)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### get_Zarr_realization_auto_chunkdim()
###

get_Zarr_realization_auto_chunkdim <- function(dim, type)
{
    chunk_maxlen <- get_Zarr_realization_chunk_maxlen(type)
    block_len <- getAutoBlockLength(type)
    if (chunk_maxlen > block_len)
        chunk_maxlen <- block_len
    chunk_shape <- get_Zarr_realization_chunk_shape()
    makeCappedVolumeBox(chunk_maxlen, dim, chunk_shape)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### get/set_Zarr_realization_auto_version()
###

get_Zarr_realization_auto_version <- function()
{
    get_ZarrArray_option("realization.auto.version")
}


### Called by .onLoad() hook (see zzz.R file).
set_Zarr_realization_auto_version <- function(zarr_version=3)
{
    if (!(isSingleNumber(zarr_version) && zarr_version %in% 2:3))
        stop(wmsg("'zarr_version' must be 2 or 3"))
    set_ZarrArray_option("realization.auto.version", as.integer(zarr_version))
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### get/set_Zarr_realization_auto_group()
###

get_Zarr_realization_auto_group <- function()
{
    get_ZarrArray_option("realization.auto.group")
}


### Called by .onLoad() hook (see zzz.R file).
set_Zarr_realization_auto_group <- function(group="/")
{
    if (!isSingleString(group))
        stop(wmsg("'group' must be a single string"))
    set_ZarrArray_option("realization.auto.group", group)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### get/set_Zarr_realization_auto_layout()
###

get_Zarr_realization_auto_layout <- function()
{
    get_ZarrArray_option("realization.auto.layout")
}


### Called by .onLoad() hook (see zzz.R file).
set_Zarr_realization_auto_layout <- function(sparse.layout="tenx")
{
    if (!isSingleString(sparse.layout))
        stop(wmsg("'sparse.layout' must be a single string"))
    set_ZarrArray_option("realization.auto.layout", sparse.layout)
}

