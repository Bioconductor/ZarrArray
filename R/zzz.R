
.onLoad <- function(libname, pkgname)
{
    if (!ZarrArray_option_is_set("realization.dump.dir"))
        set_Zarr_realization_dump_dir()
    if (!ZarrArray_option_is_set("realization.chunk.maxsize"))
        set_Zarr_realization_chunk_maxsize()
    if (!ZarrArray_option_is_set("realization.chunk.shape"))
        set_Zarr_realization_chunk_shape()
    if (!ZarrArray_option_is_set("realization.auto.version"))
        set_Zarr_realization_auto_version()
    if (!ZarrArray_option_is_set("realization.auto.group"))
        set_Zarr_realization_auto_group()
    if (!ZarrArray_option_is_set("realization.auto.layout"))
        set_Zarr_realization_auto_layout()
    #file.create(get_Zarr_dump_logfile())
}

