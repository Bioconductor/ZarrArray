
test_that("ZarrSparseMatrixRealizationSink()", {

    expect_true(extends("ZarrSparseMatrixRealizationSink", "RealizationSink"))

    ## --- Some edge cases (0-col or 0-row sink) ---

    ## ZarrSparseMatrixRealizationSink() will pass its 'type' argument to
    ## the 'data_type' argument of Rarr::create_empty_zarr_array(), which
    ## doesn't accept "complex" or "raw" at the moment.
    ## Also we don't support 'type="character"' at the moment (see TODOs
    ## in R/writeZarrSparseMatrix.R).
    ## TODO: Add "character" to list of types below once it's supported.
    for (type in c("integer", "logical", "double")) {

        ## 0-col sink:

        sink <- ZarrSparseMatrixRealizationSink(c(20, 0), type=type)
        expect_true(is(sink, "ZarrSparseMatrixRealizationSink"))
        expect_identical(dim(sink), c(20L, 0L))
        expect_identical(chunkdim(sink), c(20L, 0L))
        expect_identical(type(sink), type)

        seed <- as(sink, "ZarrSparseMatrixSeed")
        expect_true(is(seed, "ZarrSparseMatrixSeed"))
        expect_identical(dim(seed), dim(sink))
        expect_identical(chunkdim(seed), chunkdim(sink))
        expect_identical(type(seed), type(sink))

        ## 0-row sink:

        sink <- ZarrSparseMatrixRealizationSink(c(0, 15), type=type)
        expect_true(is(sink, "ZarrSparseMatrixRealizationSink"))
        expect_identical(dim(sink), c(0L, 15L))
        expect_identical(chunkdim(sink), c(0L, 1L))
        expect_identical(type(sink), type)

        expect_error(as(sink, "ZarrSparseMatrixSeed"),  # too soon!
                     regexp="cannot close")

        viewport <- ArrayViewport(dim(sink), IRanges(start=c(1, 1),
                                                     end  =c(nrow(sink), 11)))
        block <- matrix(vector(type), nrow=nrow(viewport), ncol=ncol(viewport))
        sink <- write_block(sink, viewport, block)

        expect_error(as(sink, "ZarrSparseMatrixSeed"),  # still too soon!
                     regexp="cannot close")

        ## Invalid viewport: not adjacent to previously written block!
        viewport <- ArrayViewport(dim(sink), IRanges(start=c(1, 13),
                                                     end  =c(nrow(sink), 15)))
        block <- matrix(vector(type), nrow=nrow(viewport), ncol=ncol(viewport))
        expect_error(write_block(sink, viewport, block),
                     regexp="Invalid viewport", ignore.case=TRUE)

        viewport <- ArrayViewport(dim(sink), IRanges(start=c(1, 12),
                                                     end  =c(nrow(sink), 15)))
        block <- matrix(vector(type), nrow=nrow(viewport), ncol=ncol(viewport))
        sink <- write_block(sink, viewport, block)

        seed <- as(sink, "ZarrSparseMatrixSeed")
        expect_true(is(seed, "ZarrSparseMatrixSeed"))
        expect_identical(dim(seed), dim(sink))
        expect_identical(chunkdim(seed), chunkdim(sink))
        expect_identical(type(seed), type(sink))
    }

    ## --- Create a ZarrSparseMatrixRealizationSink and fill it with zeros ---

    sink <- ZarrSparseMatrixRealizationSink(c(20, 15))
    expect_true(is(sink, "ZarrSparseMatrixRealizationSink"))
    expect_identical(dim(sink), c(20L, 15L))
    expect_identical(chunkdim(sink), c(20L, 1L))
    expect_identical(type(sink), "double")

    ## Invalid viewport: does not span full columns!
    viewport <- ArrayViewport(dim(sink), IRanges(c(1, 1), c(19, 10)))
    block <- matrix(0, nrow=nrow(viewport), ncol=ncol(viewport))
    expect_error(write_block(sink, viewport, block),
                 regexp="Invalid viewport", ignore.case=TRUE)

    ## Invalid viewport: does not span full columns!
    viewport <- ArrayViewport(dim(sink), IRanges(c(2, 1), c(20, 10)))
    block <- matrix(0, nrow=nrow(viewport), ncol=ncol(viewport))
    expect_error(write_block(sink, viewport, block),
                 regexp="Invalid viewport", ignore.case=TRUE)

    ## Invalid viewport: does not start at beginning of sink!
    viewport <- ArrayViewport(dim(sink), IRanges(c(1, 2), c(20, 10)))
    block <- matrix(0, nrow=nrow(viewport), ncol=ncol(viewport))
    expect_error(write_block(sink, viewport, block),
                 regexp="Invalid viewport", ignore.case=TRUE)

    ## Valid viewport.
    viewport <- ArrayViewport(dim(sink), IRanges(c(1, 1), c(20, 10)))
    block <- matrix(0, nrow=nrow(viewport), ncol=ncol(viewport))
    sink <- write_block(sink, viewport, block)

    ## Invalid viewport: not adjacent to previously written block!
    viewport <- ArrayViewport(dim(sink), IRanges(c(1, 1), c(20, 5)))
    block <- matrix(0, nrow=nrow(viewport), ncol=ncol(viewport))
    expect_error(write_block(sink, viewport, block),
                 regexp="Invalid viewport", ignore.case=TRUE)

    ## Invalid viewport: not adjacent to previously written block!
    viewport <- ArrayViewport(dim(sink), IRanges(c(1, 10), c(20, 14)))
    block <- matrix(0, nrow=nrow(viewport), ncol=ncol(viewport))
    expect_error(write_block(sink, viewport, block),
                 regexp="Invalid viewport", ignore.case=TRUE)

    ## Invalid viewport: not adjacent to previously written block!
    viewport <- ArrayViewport(dim(sink), IRanges(c(1, 12), c(20, 14)))
    block <- matrix(0, nrow=nrow(viewport), ncol=ncol(viewport))
    expect_error(write_block(sink, viewport, block),
                 regexp="Invalid viewport", ignore.case=TRUE)

    ## Valid viewport.
    viewport <- ArrayViewport(dim(sink), IRanges(c(1, 11), c(20, 14)))
    block <- matrix(0, nrow=nrow(viewport), ncol=ncol(viewport))
    sink <- write_block(sink, viewport, block)

    ## Trying to close too soon.
    expect_error(close(sink), regexp="cannot close")

    ## Valid viewport.
    viewport <- ArrayViewport(dim(sink), IRanges(c(1, 15), c(20, 15)))
    block <- matrix(0, nrow=nrow(viewport), ncol=ncol(viewport))
    sink <- write_block(sink, viewport, block)

    close(sink)

    seed <- as(sink, "ZarrSparseMatrixSeed")
    expect_true(is(seed, "ZarrSparseMatrixSeed"))
    expect_identical(dim(seed), dim(sink))
    expect_identical(chunkdim(seed), chunkdim(sink))
    expect_identical(type(seed), type(sink))

    data <- ZarrArray:::.read_zarr_sparse_data(path(seed), group(seed), NULL)
    expect_identical(data, numeric(0))

    indices <- ZarrArray:::.read_zarr_sparse_indices(path(seed), group(seed))
    expect_identical(indices, integer(0))

    indptr <- ZarrArray:::.read_zarr_sparse_indptr(path(seed), group(seed))
    expect_identical(indptr, numeric(1 + ncol(seed)))

    ## --- Create a ZarrSparseMatrixRealizationSink and fill it ---
    ## ---                 with a sparse matrix                 ---

    sink <- ZarrSparseMatrixRealizationSink(c(9, 15), type="integer")
    expect_true(is(sink, "ZarrSparseMatrixRealizationSink"))
    expect_identical(dim(sink), c(9L, 15L))
    expect_identical(chunkdim(sink), c(9L, 1L))
    expect_identical(type(sink), "integer")

    set.seed(2009)
    svt <- poissonSparseMatrix(nrow(sink), ncol(sink), density=0.3)

    viewport <- ArrayViewport(dim(sink), IRanges(c(1, 1), c(9, 2)))
    sink <- write_block(sink, viewport, svt[ , 1:2])
    viewport <- ArrayViewport(dim(sink), IRanges(c(1, 3), c(9, 5)))
    sink <- write_block(sink, viewport, as.matrix(svt[ , 3:5]))
    viewport <- ArrayViewport(dim(sink), IRanges(c(1, 6), c(9, 6)))
    sink <- write_block(sink, viewport, svt[ , 6, drop=FALSE])
    viewport <- ArrayViewport(dim(sink), IRanges(c(1, 7), c(9, 10)))
    sink <- write_block(sink, viewport, as(svt[ , 7:10], "dgCMatrix"))

    ## Trying to close too soon.
    expect_error(close(sink), regexp="cannot close")

    viewport <- ArrayViewport(dim(sink), IRanges(c(1, 11), c(9, 15)))
    sink <- write_block(sink, viewport, as(svt[ , 11:15], "COO_SparseMatrix"))

    close(sink)

    seed <- as(sink, "ZarrSparseMatrixSeed")
    expect_true(is(seed, "ZarrSparseMatrixSeed"))
    expect_identical(dim(seed), dim(sink))
    expect_identical(chunkdim(seed), chunkdim(sink))
    expect_identical(type(seed), type(sink))

    expected_data <- nzvals(svt)
    Mindex <- nzwhich(svt, arr.ind=TRUE)

    data <- ZarrArray:::.read_zarr_sparse_data(path(seed), group(seed), NULL)
    expect_identical(data, expected_data)

    indices <- ZarrArray:::.read_zarr_sparse_indices(path(seed), group(seed))
    expect_identical(indices, Mindex[ , 1L] - 1L)

    indptr <- ZarrArray:::.read_zarr_sparse_indptr(path(seed), group(seed))
    expect_identical(rep.int(seq_len(ncol(seed)), diff(indptr)), Mindex[ , 2L])
})

test_that("writeZarrSparseMatrix", {
    set.seed(2009)
    svt <- poissonSparseMatrix(100, 375, density=0.4) * c(0.1, -0.1)
    m <- as.matrix(svt)
    dgc <- as(svt, "dgCMatrix")

    library(HDF5Array)
    TENx <- writeTENxMatrix(svt)

    objects <- list(svt, m, dgc, TENx)

    ## By default, blocks are much bigger than 'svt', so, BLOCK_write_to_sink(),
    ## the workhorse behind writeZarrSparseMatrix(), would walk on a grid
    ## made of a single block that covers the full matrix-like object to
    ## write.
    ## So choosing a block size that will induce a grid made of 3 blocks.
    ## This can be seen by calling writeZarrSparseMatrix() with 'verbose=TRUE'.
    setAutoBlockSize(135000)

    for (zarr_version in 3:2) {
        zarr_store <- tempfile(fileext=".zarr")
        for (i in seq_along(objects)) {
            x <- objects[[i]]
            group <- paste0("/M", i)
            ZSM <- writeZarrSparseMatrix(x, zarr_store=zarr_store, group=group,
                                         zarr_version=zarr_version)
            expect_true(is(ZSM, "ZarrSparseMatrix"))
            expect_identical(dim(ZSM), dim(svt))
            expect_identical(chunkdim(ZSM), c(100L, 1L))
            expect_identical(path(ZSM), zarr_store)
            expect_identical(group(ZSM), group)
            expect_identical(extract_sparse_array(ZSM, list(NULL, NULL)), svt)
            expect_identical(as.matrix(ZSM), m)
        }
    }
})

