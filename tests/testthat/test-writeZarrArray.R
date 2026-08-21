
test_that("ZarrRealizationSink()", {
    for (zarr_version in 3:2) {
        sink <- ZarrRealizationSink(c(85, 20, 300), zarr_version=zarr_version)
        expect_true(is(sink, "ZarrRealizationSink"))
        expect_true(is(sink, "RealizationSink"))
        format <- ZarrArray:::get_zarr_format(sink@zarr_path)
        expect_identical(format, zarr_version)
        seed <- as(sink, "ZarrArraySeed")
        expect_true(is(seed, "ZarrArraySeed"))
        expect_identical(dim(seed), c(85L, 20L, 300L))
    }
    expect_error(ZarrRealizationSink(letters))
    expect_error(ZarrRealizationSink(integer(0)))
    expect_error(ZarrRealizationSink(c(10, -1)))
    expect_error(ZarrRealizationSink(c(10, NA)))
    expect_error(ZarrRealizationSink(c(85, 90), chunkdim=c(50, 50, 50)))
    expect_error(ZarrRealizationSink(c(85, 20, 300), chunkdim=c(50, 50, 50)))
    expect_error(ZarrRealizationSink(c(85, 20, 300), chunkdim=c(50, 0, 50)))
})

.read_from_sink <- function(sink, index)
{
    Rarr::read_zarr_array(sink@zarr_path, index=index)
}

.check_ZarrRealizationSink_methods <-
    function(sink, expected_dim, expected_type, expected_chunkdim,
             a, index, viewport, block)
{
    expect_true(is(sink, "ZarrRealizationSink"))
    expect_identical(dim(sink), expected_dim)
    expect_identical(type(sink), expected_type)
    expect_identical(chunkdim(sink), expected_chunkdim)
    FUN <- if (expected_type == "double") expect_equal else expect_identical
    FUN(as.array(as(sink, "ZarrArraySeed")), a)
    expected_slice1 <- extract_array(a, index)
    FUN(.read_from_sink(sink, index), expected_slice1)
    sink <- write_block(sink, viewport, block)
    expected_slice2 <- extract_array(write_block(a, viewport, block), index)
    FUN(.read_from_sink(sink, index), expected_slice2)
}

test_that("ZarrRealizationSink methods", {
    dim <- c(25L, 12L, 100L)
    passed_chunkdims    <- list(c(10, 5, 25),  c(10, NA, 25), c(NA, NA, NA))
    expected_chunkdims <- list(c(10L, 5L, 25L), c(10L, 12L, 25L), dim)
    index <- list(16:25, 5:7, 1:5)
    viewport <- ArrayViewport(dim, IRanges(c("11-20", "1-6", "5")))

    for (zarr_version in 3:2) {
      for (i in seq_along(passed_chunkdims)) {
        chunkdim <- passed_chunkdims[[i]]
        expected_chunkdim <- expected_chunkdims[[i]]

        ## Rarr::create_empty_zarr_array() only supports arrays of type
        ## integer, double, character and logical at the moment. Therefore
        ## so do ZarrRealizationSink().

        type <- "integer"
        ## Setting 'fill_value' to NA_integer_ is broken at the moment.
        ## See https://github.com/Huber-group-EMBL/Rarr/issues/137
        #for (fill_value in list(NULL, 0L, -1L, NA_integer_)) {
        for (fill_value in list(NULL, 0L, -1L, .Machine$integer.max)) {
            sink <- ZarrRealizationSink(dim, type=type, chunkdim=chunkdim,
                                        fill_value=fill_value)
            if (is.null(fill_value))
                fill_value <- vector(type, length=1L)  # effective fill value
            a <- array(fill_value, dim=dim)
            block_data <- c(-1L, NA_integer_, 0L, .Machine$integer.max)
            block <- array(block_data, dim(viewport))
            .check_ZarrRealizationSink_methods(sink, dim, type,
                                               expected_chunkdim,
                                               a, index, viewport, block)
        }

        type <- "double"
        ## Setting 'fill_value' to NA_real_, NaN, Inf, or -Inf is broken at
        ## the moment. See https://github.com/Huber-group-EMBL/Rarr/issues/137
        fill_values <- list(NULL, 0, -2.78, 4e10,
                            #NA_real_, NaN, Inf, -Inf,
                            .Machine$double.xmin, -.Machine$double.xmin,
                            .Machine$double.xmax, -.Machine$double.xmax)
        for (fill_value in fill_values) {
            sink <- ZarrRealizationSink(dim, type=type, chunkdim=chunkdim,
                                        fill_value=fill_value)
            if (is.null(fill_value))
                fill_value <- vector(type, length=1L)  # effective fill value
            a <- array(fill_value, dim=dim)
            block_data <- c(Inf, NA_real_, 0L, -Inf, NaN, pi)
            block <- array(block_data, dim(viewport))
            .check_ZarrRealizationSink_methods(sink, dim, type,
                                               expected_chunkdim,
                                               a, index, viewport, block)
        }

        type <- "logical"
        ## Setting 'fill_value' to NA is broken at the moment.
        ## See https://github.com/Huber-group-EMBL/Rarr/issues/137
        #fill_values <- list(NULL, FALSE, TRUE, NA)
        fill_values <- list(NULL, FALSE, TRUE)
        for (fill_value in fill_values) {
            sink <- ZarrRealizationSink(dim, type=type, chunkdim=chunkdim,
                                        fill_value=fill_value)
            if (is.null(fill_value))
                fill_value <- vector(type, length=1L)  # effective fill value
            a <- array(fill_value, dim=dim)
            ## Writing NAs to a Zarr array of type "logical" is not
            ## supported yet.
            ## See https://github.com/Huber-group-EMBL/Rarr/issues/138
            #block_data <- c(TRUE, TRUE, FALSE, TRUE, NA, FALSE)
            block_data <- c(TRUE, TRUE, FALSE, TRUE, FALSE, FALSE)
            block <- array(block_data, dim(viewport))
            .check_ZarrRealizationSink_methods(sink, dim, type,
                                               expected_chunkdim,
                                               a, index, viewport, block)
        }

        type <- "character"
        ## Setting 'nchar' to 5 means we're not allowed to use a string
        ## longer than 5 chars for 'fill_value' or in 'block'. Right now
        ## Rarr::create_empty_zarr_array() and Rarr::update_zarr_array()
        ## allow this but then the strings get silently truncated when they
        ## land on disk. TODO: Report this.
        nchar <- 5
        ## Setting 'fill_value' to NA_character_ is broken at the moment.
        ## See https://github.com/Huber-group-EMBL/Rarr/issues/137
        #fill_values <- list(NULL, "", ".", NA_character_)
        fill_values <- list(NULL, "", ".", " \n.")
        for (fill_value in fill_values) {
            sink <- ZarrRealizationSink(dim, type=type, chunkdim=chunkdim,
                                        fill_value=fill_value, nchar=nchar)
            if (is.null(fill_value))
                fill_value <- vector(type, length=1L)  # effective fill value
            a <- array(fill_value, dim=dim)
            ## Writing NAs to a Zarr array of type "character" is not
            ## supported yet.
            ## See https://github.com/Huber-group-EMBL/Rarr/issues/138
            #block_data <- c("xY/z", "", "ABCDE", ".\n ", NA_character_)
            block_data <- c("xY/z", "", "ABCDE", ".\n ")
            block <- array(block_data, dim(viewport))
            .check_ZarrRealizationSink_methods(sink, dim, type,
                                               expected_chunkdim,
                                               a, index, viewport, block)
        }
      }
    }
})

.check_written_ZarrArray <-
    function(object, expected_class, expected_format, expected_chunkdim, a)
{
    expect_true(is(object, expected_class))
    expect_identical(ZarrArray:::get_zarr_format(path(object)), expected_format)
    expect_identical(chunkdim(object), expected_chunkdim)
    expect_identical(dim(object), dim(a))
    expect_identical(type(object), type(a))
    expect_identical(as.array(object), a)
}

test_that("writeZarrArray()", {
    for (zarr_version in 3:2) {
        set.seed(123)

        ## --- 3D array ---

        ## type() is "integer"
        a3 <- array(c(5:-5, NA, 13:1200), dim=c(4, 100, 3))

        chunkdims <- list(dim(a3), c(2L, 20L, 3L), c(1L, 10L, 1L))
        for (chunkdim in chunkdims) {
            A <- writeZarrArray(a3, chunkdim=chunkdim,
                                zarr_version=zarr_version)
            .check_written_ZarrArray(A, "ZarrArray",
                                     zarr_version, chunkdim, a3)
            index <- list(1L, 15:11, NULL)
            expect_identical(extract_array(A, index),
                             a3[1, 15:11, , drop=FALSE])
            index <- list(NULL, 15:11, NULL)
            expect_identical(extract_array(A, index),
                             a3[ , 15:11, ])
        }

        ## --- 2D arrays ---

        ## type() is "double"
        m1 <- matrix(runif(2e5), ncol=200)
        m1[1, 3:6] <- c(NA, NaN, Inf, -Inf)

        chunkdim <- c(50L, 50L)
        M <- writeZarrArray(m1, chunkdim=chunkdim, zarr_version=zarr_version)
        .check_written_ZarrArray(M, "ZarrMatrix", zarr_version, chunkdim, m1)
        index <- list(15:11, NULL)
        expect_identical(extract_array(M, index), m1[15:11, ])
        index <- list(integer(0), 5:9)
        expect_identical(extract_array(M, index), m1[0, 5:9])

        chunkdim <- c(500L, 60L)
        M <- writeZarrArray(m1, chunkdim=chunkdim, zarr_version=zarr_version)
        .check_written_ZarrArray(M, "ZarrMatrix", zarr_version, chunkdim, m1)
        index <- list(15:11, NULL)
        expect_identical(extract_array(M, index), m1[15:11, ])
        index <- list(integer(0), 5:9)
        expect_identical(extract_array(M, index), m1[0, 5:9])

        ## type() is "character"
        # Note that NAs in Zarr datasets of type "character" are causing
        # problems at the moment. See
        # https://github.com/Huber-group-EMBL/Rarr/issues/138
        #data <- c(strrep(letters, sample(0:8, 26, replace=TRUE)), NA)
        #m2 <- matrix(data, ncol=3)
        data <- strrep(letters, sample(0:8, 26, replace=TRUE))
        m2 <- matrix(data, ncol=2)

        chunkdim <- c(4L, 2L)
        M <- writeZarrArray(m2, chunkdim=chunkdim, zarr_version=zarr_version)
        .check_written_ZarrArray(M, "ZarrMatrix", zarr_version, chunkdim, m2)
        index <- list(c(13:8, 9L), NULL)
        expect_identical(extract_array(M, index), m2[c(13:8, 9L), ])
        index <- list(5:9, integer(0))
        expect_identical(extract_array(M, index), m2[5:9, 0])

        ## type() is "logical"
        # Note that NAs in Zarr datasets of type "character" are not handled
        # properly at the moment. See
        # https://github.com/Huber-group-EMBL/Rarr/issues/138
        #m3 <- matrix(c(TRUE, NA, FALSE, TRUE, TRUE), nrow=11, ncol=60)
        m3 <- matrix(c(TRUE, FALSE, FALSE, TRUE, TRUE), nrow=11, ncol=60)

        chunkdim <- c(2L, 20L)
        M <- writeZarrArray(m3, chunkdim=chunkdim, zarr_version=zarr_version)
        .check_written_ZarrArray(M, "ZarrMatrix", zarr_version, chunkdim, m3)
        index <- list(9L, c(8:5, 7L))
        expect_identical(extract_array(M, index), m3[9, c(8:5, 7), drop=FALSE])
        index <- list(5:9, c(60, 8:5, 1:10))
        expect_identical(extract_array(M, index), m3[5:9, c(60, 8:5, 1:10)])
        index <- list(5:9, integer(0))
        expect_identical(extract_array(M, index), m3[5:9, 0])

        ## --- 1D array ---

        ## type() is "integer"
        a1 <- array(11:-11, dim=23)

        chunkdims <- list(dim(a1), 10L, 1L)
        for (chunkdim in chunkdims) {
            A <- writeZarrArray(a1, chunkdim=chunkdim,
                                zarr_version=zarr_version)
            .check_written_ZarrArray(A, "ZarrArray",
                                     zarr_version, chunkdim, a1)
            index <- list(15:11)
            expect_identical(extract_array(A, index), a1[15:11])
            index <- list(integer(0))
            expect_identical(extract_array(A, index), array(0L, dim=0))
        }
    }
})

