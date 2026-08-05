### =========================================================================
### ZarrSparseMatrixSeed objects
### -------------------------------------------------------------------------


setClass("ZarrSparseMatrixSeed",
    contains=c("Array", "OutOfMemoryObject"),
    representation(
        "VIRTUAL",

        ## ----------------- user supplied slots -----------------

        ## Absolute path to the Zarr store so the object won't break when
        ## the user changes the working directory (e.g. with 'setwd()').
        zarr_store="character",

        ## Name of the group in the Zarr store where the sparse matrix
        ## is stored.
        group="character",

        ## If 'file.path(zarr_store, group, "data")' is a group, name
        ## of a dataset in that group. Otherwise, must be set to NULL.
        subdata="character_OR_NULL",

        ## ------------ automatically populated slots ------------

        dim="integer",

        ## Can't use an IRanges object for this at the moment because IRanges
        ## objects don't support large integer start/end values yet.
        indptr_ranges="data.frame",

        ## --------- populated by specialized subclasses ---------

        dimnames="list"
    ),
    prototype(
        dimnames=list(NULL, NULL)
    )
)

.get_data_name <- function(subdata, group=NULL)
{
    name <- "data"
    if (!is.null(subdata))
        name <- file.path(name, subdata)
    if (!is.null(group))
        name <- file.path(group, name)
    name
}

setClass("CSC_ZarrSparseMatrixSeed", contains="ZarrSparseMatrixSeed")
setClass("CSR_ZarrSparseMatrixSeed", contains="ZarrSparseMatrixSeed")


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Transposition
###

### S3/S4 combo for t.CSC_ZarrSparseMatrixSeed
t.CSC_ZarrSparseMatrixSeed <- function(x)
{
    x@dim <- rev(x@dim)
    x@dimnames <- rev(x@dimnames)
    class(x) <- class(new("CSR_ZarrSparseMatrixSeed"))
    x
}
setMethod("t", "CSC_ZarrSparseMatrixSeed", t.CSC_ZarrSparseMatrixSeed)

### S3/S4 combo for t.CSR_ZarrSparseMatrixSeed
t.CSR_ZarrSparseMatrixSeed <- function(x)
{
    x@dim <- rev(x@dim)
    x@dimnames <- rev(x@dimnames)
    class(x) <- class(new("CSC_ZarrSparseMatrixSeed"))
    x
}
setMethod("t", "CSR_ZarrSparseMatrixSeed", t.CSR_ZarrSparseMatrixSeed)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### path() getter
###

### Does NOT access the file.
setMethod("path", "ZarrSparseMatrixSeed", function(object) object@zarr_store)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### group() getter
###

### Does NOT access the file.
setMethod("group", "ZarrSparseMatrixSeed",
    function(object)
    {
        group <- object@group
        if (!startsWith(group, "/"))
            group <- paste0("/", group)
        group
    }
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### dim() and dimnames() getters
###

### Does NOT access the file.
setMethod("dim", "ZarrSparseMatrixSeed", function(x) x@dim)

### Does NOT access the file.
setMethod("dimnames", "ZarrSparseMatrixSeed",
    function(x) S4Arrays:::simplify_NULL_dimnames(x@dimnames)
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### chunkdim() getter
###

### Does NOT access the file.
setMethod("chunkdim", "CSC_ZarrSparseMatrixSeed",
    function(x) c(nrow(x), min(ncol(x), 1L))
)

setMethod("chunkdim", "CSR_ZarrSparseMatrixSeed",
    function(x) c(min(nrow(x), 1L), ncol(x))
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### is_sparse() and nzcount() methods
###

### This is about **structural** sparsity, not about quantitative sparsity
### measured by sparsity().
setMethod("is_sparse", "ZarrSparseMatrixSeed", function(x) TRUE)

setMethod("nzcount", "ZarrSparseMatrixSeed",
    function(x) zarrlength(x@zarr_store, .get_data_name(x@subdata, x@group))
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Low-level helper for reading sparse Zarr data
###

### All the "sparse Zarr" components are monodimensional.
read_sparse_zarr_component <- function(zarr_store, group, name,
                                       start=NULL, count=NULL)
{
    name <- file.path(group, name)
    if (is.null(start))
        start <- seq_len(zarrlength(zarr_store, name))
    if (!is.null(count))
        start <- sequence(count, start)
    index <- list(start)
    ans <- Rarr::read_zarr_array(file.path(zarr_store, name), index)
    dim(ans) <- NULL
    ans
}

### Returns a numeric vector (integer or double).
.read_sparse_zarr_dim <- function(zarr_store, group)
{
    if (zarr_exists(zarr_store, file.path(group, "shape"))) {
        ## 10x layout
        return(read_sparse_zarr_component(zarr_store, group, "shape"))
    }
    ## AnnData-style layout
    zarr_attrs <- read_zarr_attributes(file.path(zarr_store, group))
    shape <- zarr_attrs$shape
    if (is.null(shape))
        stop(wmsg("Group \"", group, "\" in Zarr store \"", zarr_store, "\" ",
                  "contains no 'shape' dataset. As a consequence, the ",
                  "dimensions of the sparse matrix can't be determined."))
    ## We pass 'shape' thru as.vector() to drop its class attribute in case
    ## it's an array.
    rev(as.vector(shape))
}

.read_sparse_zarr_layout <- function(zarr_store, group)
{
    if (zarr_exists(zarr_store, file.path(group, "shape"))) {
        ## 10x format
        return("csr")
    }
    ## AnnData-style layout
    zarr_attrs <- read_zarr_attributes(file.path(zarr_store, group))
    sparse_zarr_layout <- zarr_attrs[["encoding-type"]]
    if (is.null(sparse_zarr_layout))
        return("csr")
    ans <- tolower(substr(sparse_zarr_layout, 1L, 3L))
    if (!(ans %in% c("csr", "csc")))
        stop(wmsg("sparse matrix in group \"", group, "\" of Zarr ",
                  "store \"", zarr_store, "\" uses an unsupported ",
                  "layout \"", sparse_zarr_layout, "\""))
    ans
}

.read_sparse_zarr_indptr <- function(zarr_store, group)
    read_sparse_zarr_component(zarr_store, group, "indptr")

.read_sparse_zarr_data <-
    function(zarr_store, group, subdata, start=NULL, count=NULL)
{
    name <- .get_data_name(subdata)
    read_sparse_zarr_component(zarr_store, group, name,
                               start=start, count=count)
}

### The row (or column) indices stored in sparse Zarr component "indices"
### are 0-based and we return them as such.
.read_sparse_zarr_indices <- function(zarr_store, group, start=NULL, count=NULL)
    read_sparse_zarr_component(zarr_store, group, "indices",
                               start=start, count=count)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Constructor
###

.check_group <- function(zarr_store, group)
{
    if (!zarr_exists(zarr_store, group))
        stop(wmsg("Group \"", group, "\" does not exist in this Zarr store"))
    if (zarr_node_is_dataset(zarr_store, group)) {
        is_X_or_layer <- group == "/X" || startsWith(group, "/layers/")
        msg1 <- c("\"", group, "\" is a Zarrr dataset, not a Zarr group, ",
                  "so it looks like the matrix that you are trying to ",
                  "access is not stored in a sparse format. Please ",
                  "consider using the ")
        if (is_X_or_layer) {
            msg2 <- c("ZarrADMatrix() constructor if you are trying to ",
                      "access the central matrix of an AnnData-style Zarr ",
                      "store. Otherwise, use the ZarrArray() constructor.")
        } else {
            msg2 <- "ZarrArray() constructor to access this dataset."
        }
        stop(wmsg(msg1, msg2))
    }
    if (!zarr_node_is_group(zarr_store, group))
        stop(wmsg("Zarr object \"", group, "\" is not a group"))
}

.check_data_and_subdata <- function(zarr_store, group, subdata)
{
    data_fullname <- file.path(group, "data")
    if (!zarr_exists(zarr_store, data_fullname))
        stop(wmsg("Object \"", data_fullname, "\" does not ",
                  "exist in this Zarr store. Are you sure that Zarr ",
                  "group \"", group, "\" contains a sparse matrix ",
                  "stored in CSR/CSC/Yale layout?"))
    if (is.null(subdata)) {
        if (zarr_node_is_group(zarr_store, data_fullname))
            stop(wmsg("\"", data_fullname, "\" is a Zarr group, not a ",
                      "Zarr dataset. Please use the 'subdata' argument to ",
                      "specify the name of the dataset in this group that ",
                      "contains the matrix data."))
        if (!zarr_node_is_dataset(zarr_store, data_fullname))
            stop(wmsg("Zarr object \"", data_fullname, "\" is not a dataset."))
    } else {
        if (!isSingleString(subdata) || !nzchar(subdata))
            stop(wmsg("'subdata' must be NULL or a single non-empty string"))
        if (zarr_node_is_dataset(zarr_store, data_fullname))
            stop(wmsg("\"", data_fullname, "\" is a Zarr dataset, not a ",
                      "Zarr group. Please note that the 'subdata' argument ",
                      "can be used only when it's a group."))
        if (!zarr_node_is_group(zarr_store, data_fullname))
            stop(wmsg("Zarr object \"", data_fullname, "\" is not a group."))
        subdata_fullname <- .get_data_name(subdata, group)
        if (!zarr_exists(zarr_store, subdata_fullname))
            stop(wmsg("Zarr object \"", subdata_fullname, "\" does not ",
                      "exist in this Zarr store."))
        if (!zarr_node_is_dataset(zarr_store, subdata_fullname))
            stop(wmsg("Zarr object \"", subdata_fullname, "\" is ",
                      "not a dataset."))
    }
}

.get_sparse_matrix_dim <- function(zarr_store, group, dim=NULL)
{
    if (is.null(dim)) {
        dim <- .read_sparse_zarr_dim(zarr_store, group)
        stopifnot(length(dim) == 2L)
        return(dim_as_integer(dim, zarr_store, group, what="sparse matrix"))
    }
    ## Check user-supplied 'dim'.
    if (!is.numeric(dim) || length(dim) != 2L || anyNA(dim))
        stop(wmsg("supplied 'dim' must be an integer vector ",
                  "of length 2 with no NAs"))
    if (!is.integer(dim)) {
        if (any(dim > .Machine$integer.max))
            stop(wmsg("supplied dimensions are too big (all dimensions ",
                      "must be <= '.Machine$integer.max' (= 2^31 - 1))"))
        dim <- as.integer(dim)
    }
    if (any(dim < 0L))
        stop(wmsg("supplied 'dim' cannot contain negative values"))
    dim
}

### Must return "CSC" or "CSR".
.get_sparse_matrix_layout <- function(zarr_store, group, sparse.layout=NULL)
{
    if (is.null(sparse.layout)) {
        sparse_layout <- .read_sparse_zarr_layout(zarr_store, group)
        ## Layout in R will be transposed w.r.t. layout used in Zarr store.
        ans <- switch(sparse_layout, `csr`="CSC", `csc`="CSR",
                      stop(wmsg("unsupported 'sparse_layout': ",
                                sparse_layout)))
        return(ans)
    }
    ## Check user-supplied 'sparse.layout'.
    if (!isSingleString(sparse.layout))
        stop(wmsg("'sparse.layout' must be a single string"))
    ans <- toupper(sparse.layout)
    if (!(ans %in% c("CSC", "CSR")))
        stop(wmsg("'sparse.layout' must be either \"CSC\" or \"CSR\""))
    ans
}

### Returns a ZarrSparseMatrixSeed derivative (can be either a
### CSC_ZarrSparseMatrixSeed or CSR_ZarrSparseMatrixSeed object).
ZarrSparseMatrixSeed <- function(zarr_store, group, subdata=NULL,
                                 dim=NULL, sparse.layout=NULL)
{
    ## Check 'zarr_store', 'group', and 'subdata'.
    zarr_store <- normarg_zarr_store(zarr_store,
                                     what2="the sparse matrix")
    group <- normarg_zarr_group(group,
                                what1="'group'",
                                what2="the name of the group",
                                what3=" that stores the sparse matrix")
    .check_group(zarr_store, group)
    .check_data_and_subdata(zarr_store, group, subdata)

    ## Get matrix dimensions.
    dim <- .get_sparse_matrix_dim(zarr_store, group, dim=dim)

    ## Get sparse layout to use ("CSC" or "CSR").
    ## For consistency with H5SparseMatrixSeed, we flip the notions of rows
    ## and columns w.r.t. to the AnnData convention. So:
    ## - "compressed sparse row" in the AnnData-style Zarr store
    ##   becomes "compressed sparse column" at the R level,
    ## - "compressed sparse column" in the AnnData-style Zarr store
    ##   becomes "compressed sparse row" at the R level.
    layout <- .get_sparse_matrix_layout(zarr_store, group,
                                        sparse.layout=sparse.layout)
    if (layout == "CSC") {
        expected_indptr_len <- dim[[2L]] + 1L
        ans_class <- "CSC_ZarrSparseMatrixSeed"
    } else {
        expected_indptr_len <- dim[[1L]] + 1L
        ans_class <- "CSR_ZarrSparseMatrixSeed"
    }

    ## Get 'indptr_ranges'.
    nzcount <- zarrlength(zarr_store, .get_data_name(subdata, group))
    indices_len <- zarrlength(zarr_store, file.path(group, "indices"))
    stopifnot(indices_len == nzcount)
    indptr <- .read_sparse_zarr_indptr(zarr_store, group)
    stopifnot(length(indptr) == expected_indptr_len,
              indptr[[1L]] == 0L,
              indptr[[length(indptr)]] == nzcount)
    indptr_ranges <- data.frame(start=indptr[-length(indptr)] + 1,
                                width=as.integer(diff(indptr)))

    new2(ans_class, zarr_store=zarr_store, group=group,
                    dim=dim, indptr_ranges=indptr_ranges)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### .load_CSC_ZarrSparseMatrixSeed
###
### Loads whole CSC_ZarrSparseMatrixSeed object 'x' into memory as an
### SVT_SparseMatrix object, or only selected columns if 'j' is specified.
### This is the workhorse behind the extract_sparse_array(), extract_array(),
### and read_block_as_sparse() methods for ZarrSparseMatrixSeed objects, as
### well as behind coercion from CSC_ZarrSparseMatrixSeed to SVT_SparseMatrix.
### Does NOT propagate the dimnames.
###
### Notes:
### - SparseArray:::make_SVT_SparseMatrix_from_CSC() will fail if passed
###   long vectors via its 'data' and/or 'row_indices' arguments because R
###   does not support passing long vectors to the .Call interface yet!
###   So we use a block strategy where we load blocks of adjacent columns
###   and convert them to SVT_SparseMatrix objects, then cbind() all the
###   objects together. By default, blocks are made of 125 millions
###   data/indices elements.
### - Supports parallelization via the 'BPPARAM' argument. However some
###   quick testing with 'BiocParallel::MulticoreParam(2)' on a powerful
###   Linux server seemed to indicate that it's not worth it. Execution
###   time remained about the same but memory footprint increased
###   significantly!

.load_CSC_ZarrSparseMatrixSeed <- function(x, j=NULL,
                                           DATABLOCKLEN=125000000L,
                                           BPPARAM=NULL)
{
    stopifnot(is(x, "CSC_ZarrSparseMatrixSeed"),
              isSingleInteger(DATABLOCKLEN), DATABLOCKLEN >= 0L)
    if (is.null(j)) {
        ans_ncol <- ncol(x)
        w <- x@indptr_ranges[ , "width"]
    } else {
        stopifnot(is.integer(j))
        ans_ncol <- length(j)
        if (ans_ncol != 0L)
            stopifnot(isStrictlySorted(j),
                      1L <= j[[1L]], j[[ans_ncol]] <= ncol(x))
        w <- x@indptr_ranges[j , "width"]
    }
    ans_dim <- c(nrow(x), ans_ncol)
    ## 'cumsum(as.double(w))' instead of 'cumsum(w)' to avoid integer overflow.
    ans_indptr <- c(0, cumsum(as.double(w)))
    ans_nzcount <- ans_indptr[[length(ans_indptr)]]

    ## DATABLOCKLEN == 0L means no block processing.
    if (DATABLOCKLEN == 0L || ans_nzcount <= DATABLOCKLEN) {
        if (is.null(j)) {
            start <- count <- NULL
        } else {
            start <- x@indptr_ranges[j, "start"]
            count <- x@indptr_ranges[j, "width"]
        }
        ans_data <- .read_sparse_zarr_data(x@zarr_store, x@group, x@subdata,
                                        start=start, count=count)
        ans_row_indices <- .read_sparse_zarr_indices(x@zarr_store, x@group,
                                        start=start, count=count)
        ans <- SparseArray:::make_SVT_SparseMatrix_from_CSC(ans_dim,
                                        ans_indptr, ans_data, ans_row_indices)
        return(ans)
    }

    ## Compute 'nblock' (will always be >= 2).
    nblock <- ans_nzcount %/% DATABLOCKLEN
    if (ans_nzcount %% DATABLOCKLEN != 0L)
        nblock <- nblock + 1L

    ## Partition column indices in ranges (nb of ranges is guaranteed to be
    ## >= 1 and <= 'min(nblock, ans_ncol)').
    col_ranges <- breakInChunks(ans_ncol, nblock)
    ## There will be zero-width ranges if and only if 'nblock' > 'ans_ncol'.
    ## Drop them.
    col_ranges <- col_ranges[width(col_ranges) != 0L]
    s <- start(col_ranges)
    e <- end(col_ranges)

    ## Load ranges of columns into SVT_SparseMatrix objects.
    objects <- S4Arrays:::bplapply2(seq_along(col_ranges),
        function(b, x, j, s, e) {
            k1 <- s[[b]]
            k2 <- e[[b]]
            jj <- if (is.null(j)) k1:k2 else j[k1:k2]
            ## Set 'DATABLOCKLEN' to 0L to disable block processing.
            .load_CSC_ZarrSparseMatrixSeed(x, jj, DATABLOCKLEN=0L)
        },
        x, j, s, e,
        BPPARAM=BPPARAM
    )

    ## Combine all objects together.
    do.call(cbind, objects)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### extract_sparse_array() and extract_array() methods
###

.extract_sparse_array_from_CSC_ZarrSparseMatrixSeed <- function(x, index)
{
    j <- index[[2L]]
    if (!is.null(j)) {
        if (!is.integer(j))
            j <- as.integer(j)
        sort_j <- !isStrictlySorted(j)
        if (sort_j) {
            j0 <- j
            j <- unique(sort(j))
        }
    }
    svt <- .load_CSC_ZarrSparseMatrixSeed(x, j=j)
    index2 <- list(index[[1L]], NULL)
    if (!is.null(j) && sort_j)
        index2[[2L]] <- match(j0, j)
    extract_sparse_array(svt, index2)
}

setMethod("extract_sparse_array", "CSC_ZarrSparseMatrixSeed",
    function(x, index)
        .extract_sparse_array_from_CSC_ZarrSparseMatrixSeed(x, index)
)

setMethod("extract_sparse_array", "CSR_ZarrSparseMatrixSeed",
    function(x, index)
        t(.extract_sparse_array_from_CSC_ZarrSparseMatrixSeed(t(x), rev(index)))
)

setMethod("extract_array", "ZarrSparseMatrixSeed",
    function(x, index) as.array(extract_sparse_array(x, index))
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Show
###

setMethod("show", "ZarrSparseMatrixSeed",
    function(object)
    {
        cat(S4Arrays:::array_as_one_line_summary(object), ":\n", sep="")
        cat("# Zarr store dirname: ", dirname(object), "\n", sep="")
        cat("# Zarr store basename: ", basename(object), "\n", sep="")
        cat("# Zarr group: ", object@group, "\n", sep="")
    }
)

