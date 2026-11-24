### =========================================================================
### Control writeZarrArray()'s automatic arguments
### -------------------------------------------------------------------------
###
### EVERYTING IN THIS FILE IS DEPRECATED!
###


get_writeZarrArray_dump_dir <- function()
{
    .Deprecated("get_Zarr_realization_dump_dir")
    get_Zarr_realization_dump_dir()
}

set_writeZarrArray_dump_dir <- function(dir)
{
    .Deprecated("set_Zarr_realization_dump_dir")
    set_Zarr_realization_dump_dir(dir)
}

get_writeZarrArray_auto_path <- function()
{
    .Deprecated("get_Zarr_realization_auto_path")
    get_Zarr_realization_auto_path()
}

get_writeZarrArray_chunk_maxlen <- function()
{
    msg <- c("get_writeZarrArray_chunk_maxlen() is deprecated, do not use ",
             "anymore. Please use get_Zarr_realization_chunk_maxsize() ",
             "instead to get the maximum size (in bytes, before ",
             "compression) of the physical chunks to write to disk.")
    .Deprecated(msg=wmsg(msg))
    get_Zarr_realization_chunk_maxlen("integer")
}

set_writeZarrArray_chunk_maxlen <- function(maxlen=250000L)
{
    msg <- c("set_writeZarrArray_chunk_maxlen() is deprecated, do not use ",
             "anymore. Please use set_Zarr_realization_chunk_maxsize() ",
             "instead to specify the maximum size (in bytes, before ",
             "compression) of the physical chunks to write to disk.")
    .Deprecated(msg=wmsg(msg))
    ## We arbitrarily assume that the type() of the array data is "integer".
    type_size <- get_type_size("integer")[[1L]]
    set_Zarr_realization_chunk_maxsize(length * type_size)
}

get_writeZarrArray_chunk_shape <- function()
{
    .Deprecated("get_Zarr_realization_chunk_shape")
    get_Zarr_realization_chunk_shape()
}

set_writeZarrArray_chunk_shape <- function(shape="scale")
{
    .Deprecated("set_Zarr_realization_chunk_shape")
    set_Zarr_realization_chunk_shape(shape)
}

get_writeZarrArray_auto_chunkdim <- function(dim)
{
    .Deprecated("get_Zarr_realization_auto_chunkdim")
    get_Zarr_realization_auto_chunkdim(dim, "integer")
}

