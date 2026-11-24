### =========================================================================
### writeZarrSparseMatrix()
### -------------------------------------------------------------------------
###


.SUPPORTED_SPARSE_LAYOUTS <- c("tenx", "csc", "csr")

.normarg_sparse.layout <- function(sparse.layout="tenx")
{
    if (!isSingleString(sparse.layout))
        stop(wmsg("'sparse.layout' must be a single string"))
    m <- pmatch(tolower(sparse.layout), .SUPPORTED_SPARSE_LAYOUTS)
    if (is.na(m)) {
        in1string <- paste0("\"", .SUPPORTED_SPARSE_LAYOUTS, "\"",
                            collapse=", ")
        stop(wmsg("'sparse.layout' should be one of ", in1string))
    }
    .SUPPORTED_SPARSE_LAYOUTS[[m]]
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### ZarrSparseMatrixRealizationSink objects
###
### The ZarrSparseMatrixRealizationSink class is a concrete RealizationSink
### subclass that implements a ZarrSparseMatrix realization sink.
###

setClass("ZarrSparseMatrixRealizationSink",
    contains="RealizationSink",
    representation(
        ## Slots that support the RealizationSink constructor contract.
        dim="integer",           # Naming this slot "dim" makes dim() work
                                 # out of the box.
        dimnames="list",
        type="character",        # Single string.

        ## Other slots.
        zarr_store="character",  # Single string.
        group="character"        # Name of the group in the HDF5 file
                                 # where to write the data.
    ),
    prototype(
        dimnames=list(NULL, NULL),
        group="/"
    )
)

setMethod("dimnames", "ZarrSparseMatrixRealizationSink",
    function(x)
    {
        ans <- x@dimnames
        if (all(S4Vectors:::sapply_isNULL(ans)))
            return(NULL)
        ans
    }
)

setMethod("type", "ZarrSparseMatrixRealizationSink", function(x) x@type)

### If 'zarr_store' is "auto" (the default), the path to the Zarr store
### is obtained with get_Zarr_realization_auto_path().
### NOTE: We don't support 'type="character"' at the moment.
### TODO: Add 'nchar' argument and support 'type="character"' like in
### ZarrRealizationSink().
### TODO: Add support for other layouts (only "tenx" is supported at
### the moment) and harmonize with 'sparse.layout' argument of
### ZarrSparseMatrixSeed().
ZarrSparseMatrixRealizationSink <-
    function(dim, dimnames=NULL, type="double",
             zarr_store="auto", group="auto", sparse.layout="auto",
             zarr_version="auto")
{
    dim <- S4Arrays:::normarg_dim(dim)
    if (length(dim) != 2L)
        stop(wmsg("ZarrSparseMatrix backend only supports ",
                  "realization of matrix-like objects"))
    if (is.null(dimnames)) {
        dimnames <- vector("list", length(dim))
    } else {
        if (!(is.list(dimnames) && length(dimnames) == length(dim)))
            stop(wmsg("'dimnames' must be NULL or a list ",
                      "with 1 list element per dimension"))
    }
    if (isSingleString(zarr_store) && zarr_store == "auto" ||
        is.null(zarr_store))
    {
        zarr_store <- get_Zarr_realization_auto_path()
    } else {
        zarr_store <- Rarr:::.normalize_array_path(zarr_store)
    }
    if (isSingleString(group) && group == "auto") {
        group <- get_Zarr_realization_auto_group()
    } else {
        group <- normarg_zarr_group(group,
                                    what3=" where to write the sparse matrix")
    }
    ## write_zarr_group() doesn't like it when 'group' starts with '/'.
    if (startsWith(group, "/"))
        group <- substr(group, 2L, nchar(group))

    if (isSingleString(sparse.layout) && sparse.layout == "auto") {
        sparse.layout <- get_Zarr_realization_auto_layout()
    } else {
        sparse.layout <- .normarg_sparse.layout(sparse.layout)
    }

    if (isSingleString(zarr_version) && zarr_version == "auto")
        zarr_version <- get_Zarr_realization_auto_version()

    Rarr::write_zarr_group(zarr_store, group, zarr_version=zarr_version)
    group_path <- file.path(zarr_store, group)

    shape_path <- file.path(group_path, "shape")
    Rarr::write_zarr_array(array(dim), shape_path, chunk_dim=length(dim),
                           zarr_version=zarr_version)

    data_path <- file.path(group_path, "data")
    create_empty_zarr_array2(data_path, dim=0L, chunkdim=25000000L,
                             type=type, zarr_version=zarr_version)

    indices_path <- file.path(group_path, "indices")
    create_empty_zarr_array2(indices_path, dim=0L, chunkdim=25000000L,
                             type="integer", zarr_version=zarr_version)

    indptr_path <- file.path(group_path, "indptr")
    indptr_len <- max(dim[[2L]], 1L)
    ## Rarr::create_empty_zarr_array() will emit a "Chunk dimensions are
    ## larger than array dimensions" warning (doesn't happen when 'dim' is 0).
    suppressWarnings(
        create_empty_zarr_array2(indptr_path, dim=1L, chunkdim=indptr_len,
                                 type="double", fill_value=0,
                                 zarr_version=zarr_version)
    )

    new2("ZarrSparseMatrixRealizationSink",
         dim=dim, dimnames=dimnames, type=type,
         zarr_store=zarr_store, group=paste0("/", group))
}

### Defining this method will force writeZarrSparseMatrix() (thru
### BLOCK_write_to_sink() thru sinkApply()) to write blocks that
### span full columns which is a requirement of the write_block()
### method for ZarrSparseMatrixRealizationSink objects. See below.
setMethod("chunkdim", "ZarrSparseMatrixRealizationSink",
    function(x) c(nrow(x), min(ncol(x), 1L))
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### write_block() and close() methods
###
### Taken and slightly adapted from HDF5Array/R/writeTENxMatrix.R
###

### The current length of 'indptr' is the "current 1-based column index"
### i.e. the nb of columns written so far + 1.
.get_current_col_idx <- function(zarr_store, group)
{
    zarrlength(zarr_store, file.path(group, "indptr"))
}

.check_viewport <- function(viewport, sink)
{
    S4Arrays:::stop_if_viewport_on_2D_sink_is_not_full_height(sink, viewport)
    current_col_idx <- .get_current_col_idx(sink@zarr_store, sink@group)
    S4Arrays:::stop_if_viewport_on_2D_sink_is_not_adj_to_prev(sink, viewport,
                                                              current_col_idx)
}

.append_data <- function(group_path, data)
{
    data_path <- file.path(group_path, "data")
    append_zarr_array(data_path, data)
}

.append_row_indices <- function(group_path, row_indices)
{
    indices_path <- file.path(group_path, "indices")
    append_zarr_array(indices_path, row_indices)
}

### Returns the last value in the updated "indptr" dataset.
.append_indptr <- function(group_path, block_indptr)
{
    indptr_path <- file.path(group_path, "indptr")
    old_len <- zarrlength(indptr_path)
    old_data_len <- Rarr::read_zarr_array(indptr_path, list(old_len))
    indptr <- as.double(old_data_len) + block_indptr
    append_zarr_array(indptr_path, indptr)
    indptr[[length(indptr)]]
}

### Supports "appending mode" only.
setMethod("write_block", "ZarrSparseMatrixRealizationSink",
    function(sink, viewport, block)
    {
        .check_viewport(viewport, sink)
        group_path <- file.path(sink@zarr_store, sink@group)
        nzdata <- nzvals(block)
        Mindex <- nzwhich(block, arr.ind=TRUE)

        ## Append the nonzero data.
        ## Note that .append_data() is based on Rarr::update_zarr_array()
        ## which requires the new data to be of the same type as the
        ## existing data.
        if (type(nzdata) != type(sink))
            type(nzdata) <- type(sink)
        new_data_len1 <- .append_data(group_path, nzdata)

        ## Append the 0-based row indices of the nonzero data.
        new_data_len2 <- .append_row_indices(group_path, Mindex[ , 1L] - 1L)
        stopifnot(new_data_len2 == new_data_len1)  # sanity check

        ## Append the "indptr" values.
        partitioning <- PartitioningByEnd(Mindex[ , 2L], NG=ncol(block))
        block_indptr <- end(partitioning)  # sorted integer vector
        new_data_len3 <- .append_indptr(group_path, block_indptr)
        stopifnot(new_data_len3 == new_data_len1)  # sanity check
        sink
    }
)

### Only performs some sanity checks (there is actually nothing to close).
setMethod("close", "ZarrSparseMatrixRealizationSink",
    function(con)
    {
        current_col_idx <- .get_current_col_idx(con@zarr_store, con@group)
        if (current_col_idx <= ncol(con))
            stop(wmsg("cannot close ", class(con), " object before ",
                      "writing all data blocks to it"))
        stopifnot(current_col_idx == ncol(con) + 1L)  # should never happen
    }
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Coercing a ZarrSparseMatrixRealizationSink object
###

### Calls close() on the ZarrSparseMatrixRealizationSink object before
### turning it into a ZarrSparseMatrixSeed object.
setAs("ZarrSparseMatrixRealizationSink", "ZarrSparseMatrixSeed",
    function(from)
    {
        close(from)
        ZarrSparseMatrixSeed(from@zarr_store, from@group)
    }
)

setAs("ZarrSparseMatrixRealizationSink", "ZarrSparseMatrix",
    function(from) DelayedArray(as(from, "ZarrSparseMatrixSeed"))
)

setAs("ZarrSparseMatrixRealizationSink", "DelayedArray",
    function(from) DelayedArray(as(from, "ZarrSparseMatrixSeed"))
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### writeZarrSparseMatrix()
###

### If 'zarr_store' is "auto" (the default), the path to the Zarr store is
### obtained with get_Zarr_realization_auto_path().
### NOTE: We don't support 'type="character"' at the moment.
### TODO: Add 'nchar' argument and support 'type="character"' like in
### writeZarrArray().
writeZarrSparseMatrix <- function(x, zarr_store="auto", group="auto",
                                     sparse.layout="auto",
                                     zarr_version="auto", verbose=NA)
{
    verbose <- DelayedArray:::normarg_verbose(verbose)
    sink <- ZarrSparseMatrixRealizationSink(dim(x), dimnames(x), type(x),
                                            zarr_store=zarr_store, group=group,
                                            sparse.layout=sparse.layout,
                                            zarr_version=zarr_version)
    sink <- BLOCK_write_to_sink(sink, x, verbose=verbose)
    ans <- as(sink, "ZarrSparseMatrix")  # will call close() on 'sink'
    if (verbose)
        message("sparsity: ", round(sparsity(ans), digits=2))
    ans
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Coercion to ZarrSparseMatrix
###
### The methods below realize any matrix-like object to disk as a
### ZarrSparseMatrix object.
### Note that coercion from ZarrSparseMatrixRealizationSink to
### ZarrSparseMatrix is already taken care of by the specific method above
### and it doesn't write anything to disk. So coercing to ZarrSparseMatrix
### in general writes the matrix data to disk (and will use block-processing
### if needed) *except* when the object to coerce is a
### ZarrSparseMatrixRealizationSink object.
###

### Writes to Zarr store path obtained with get_Zarr_realization_auto_path().
.as_ZarrSparseMatrix <- function(from) writeZarrSparseMatrix(from)

setAs("ANY", "ZarrSparseMatrix", .as_ZarrSparseMatrix)

### Automatic coercion method from DelayedArray to ZarrSparseMatrix silently
### returns a broken object (unfortunately these dummy automatic coercion
### methods don't bother to validate the object they return). So we overwrite
### it.
setAs("DelayedArray", "ZarrSparseMatrix", .as_ZarrSparseMatrix)
setAs("DelayedMatrix", "ZarrSparseMatrix", .as_ZarrSparseMatrix)

