### =========================================================================
### Control writeZarrArray's automatic arguments
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
### get/set_writeZarrArray_dump_dir()
###

get_writeZarrArray_dump_dir <- function()
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
set_writeZarrArray_dump_dir <- function(dir)
{
    if (missing(dir)) {
        dir <- file.path(tempdir(), "ZarrArray_realization_dump")
    } else if (!isSingleString(dir) || !nzchar(dir)) {
        stop(wmsg("'dir' must be a non-empty string specifying the path ",
                  "to a new or existing directory"))
    }
    invisible(.set_dump_dir(dir))
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### get_writeZarrArray_auto_path()
###

### Returns the *absolute path* to the realization directory.
get_writeZarrArray_auto_path <- function()
{
    tempfile(pattern="auto_", tmpdir=get_writeZarrArray_dump_dir(),
             fileext=".zarr")
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### get/set_writeZarrArray_chunk_maxlen()
###

get_writeZarrArray_chunk_maxlen <- function()
{
    get_ZarrArray_option("realization.chunk.maxlen")
}

### Called by .onLoad() hook (see zzz.R file).
set_writeZarrArray_chunk_maxlen <- function(maxlen=1000000L)
{
    set_ZarrArray_option("realization.chunk.maxlen", maxlen)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### get/set_writeZarrArray_chunk_shape()
###

get_writeZarrArray_chunk_shape <- function()
{
    get_ZarrArray_option("realization.chunk.shape")
}

### Called by .onLoad() hook (see zzz.R file).
set_writeZarrArray_chunk_shape <- function(shape="scale")
{
    set_ZarrArray_option("realization.chunk.shape", shape)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### get_writeZarrArray_auto_chunkdim()
###

get_writeZarrArray_auto_chunkdim <- function(dim)
{
    chunk_maxlen <- get_writeZarrArray_chunk_maxlen()
    chunk_shape <- get_writeZarrArray_chunk_shape()
    makeCappedVolumeBox(chunk_maxlen, dim, chunk_shape)
}

