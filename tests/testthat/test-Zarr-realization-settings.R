
test_that("get_Zarr_realization_auto_*()", {
    path <- get_Zarr_realization_auto_path()
    expect_true(isSingleString(path))
    expect_identical(dirname(path), get_Zarr_realization_dump_dir())

    set_Zarr_realization_chunk_shape("scale")  # the default

    setAutoBlockSize()  # make sure auto block size is set to its default

    set_Zarr_realization_chunk_maxsize(1e6)  # the default

    x_dim <- c(2800, 2800, 2800)
    chunkdim <- get_Zarr_realization_auto_chunkdim(x_dim, "raw")
    expect_identical(chunkdim, c(100L, 100L, 100L))  # prod() == 1e6
    chunkdim <- get_Zarr_realization_auto_chunkdim(x_dim, "double")
    expect_identical(chunkdim, c(50L, 50L, 50L))     # prod() == 1e6 / 8

    x_dim <- c(1500, 6000, 3000)
    chunkdim <- get_Zarr_realization_auto_chunkdim(x_dim, "raw")
    expect_identical(chunkdim, c(50L, 200L, 100L))   # prod() == 1e6
    chunkdim <- get_Zarr_realization_auto_chunkdim(x_dim, "double")
    expect_identical(chunkdim, c(25L, 100L, 50L))    # prod() == 1e6 / 8

    set_Zarr_realization_chunk_maxsize(12000)

    x_dim <- c(2500, 2500, 3750)
    chunkdim <- get_Zarr_realization_auto_chunkdim(x_dim, "raw")
    expect_identical(chunkdim, c(20L, 20L, 30L))     # prod() == 12000
    chunkdim <- get_Zarr_realization_auto_chunkdim(x_dim, "double")
    expect_identical(chunkdim, c(10L, 10L, 15L))     # prod() == 12000 / 8

    x_dim <- c(6000, 4500, 1500)
    chunkdim <- get_Zarr_realization_auto_chunkdim(x_dim, "raw")
    expect_identical(chunkdim, c(40L, 30L, 10L))     # prod() == 12000
    chunkdim <- get_Zarr_realization_auto_chunkdim(x_dim, "double")
    expect_identical(chunkdim, c(20L, 15L, 5L))      # prod() == 12000 / 8

    chunkdim <- get_Zarr_realization_auto_chunkdim(c(35, 5, 30), "raw")
    expect_identical(chunkdim, c(35L, 5L, 30L))      # prod() < 12000

    set_Zarr_realization_chunk_shape("hypercube")
    set_Zarr_realization_chunk_maxsize(125000)

    x_dim <- c(1500, 6000, 3000)
    chunkdim <- get_Zarr_realization_auto_chunkdim(x_dim, "raw")
    expect_identical(chunkdim, c(50L, 50L, 50L))     # prod() == 125000
    chunkdim <- get_Zarr_realization_auto_chunkdim(x_dim, "double")
    expect_identical(chunkdim, c(25L, 25L, 25L))     # prod() == 125000 / 8

    chunkdim <- get_Zarr_realization_auto_chunkdim(c(50, 500, 10), "raw")
    expect_identical(chunkdim, c(50L, 250L, 10L))    # prod() == 125000

    chunkdim <- get_Zarr_realization_auto_chunkdim(c(10, 99, 40), "raw")
    expect_identical(chunkdim, c(10L, 99L, 40L))     # prod() < 125000
})

test_that("get/set_Zarr_realization_dump_dir()", {
    set_Zarr_realization_dump_dir()  # reset to default

    dir0 <- get_Zarr_realization_dump_dir()
    expect_true(isSingleString(dir0))
    expect_true(dir.exists(dir0))

    dir1 <- tempfile("my_zarr_collection_")
    prev_dir <- set_Zarr_realization_dump_dir(dir1)
    expect_identical(
        normalizePath(get_Zarr_realization_dump_dir()),
        normalizePath(dir1)
    )
    expect_identical(
        normalizePath(prev_dir),
        normalizePath(dir0)
    )

    prev_dir <- set_Zarr_realization_dump_dir()  # reset to default
    expect_identical(get_Zarr_realization_dump_dir(), dir0)
    expect_identical(
        normalizePath(prev_dir),
        normalizePath(dir1)
    )
})

test_that("get/set_Zarr_realization_chunk_maxsize()", {
    set_Zarr_realization_chunk_maxsize()  # reset to default

    maxsize0 <- get_Zarr_realization_chunk_maxsize()
    expect_true(isSingleNumber(maxsize0))

    prev_maxsize <- set_Zarr_realization_chunk_maxsize(125000)
    expect_identical(get_Zarr_realization_chunk_maxsize(), 125000)
    expect_identical(prev_maxsize, maxsize0)

    prev_maxsize <- set_Zarr_realization_chunk_maxsize()  # reset to default
    expect_identical(get_Zarr_realization_chunk_maxsize(), maxsize0)
    expect_identical(prev_maxsize, 125000)
})

test_that("get_Zarr_realization_chunk_maxlen()", {
    maxsize <- get_Zarr_realization_chunk_maxsize()
    expect_equal(get_Zarr_realization_chunk_maxlen("integer"), maxsize / 4L)
    expect_equal(get_Zarr_realization_chunk_maxlen("double"), maxsize / 8L)
    expect_equal(get_Zarr_realization_chunk_maxlen("raw"), maxsize)
})

test_that("get/set_Zarr_realization_chunk_shape()", {
    set_Zarr_realization_chunk_shape()  # reset to default

    shape0 <- get_Zarr_realization_chunk_shape()
    expect_identical(shape0, "scale")

    prev_shape <- set_Zarr_realization_chunk_shape("hypercube")
    expect_identical(get_Zarr_realization_chunk_shape(), "hypercube")
    expect_identical(prev_shape, shape0)

    prev_shape <- set_Zarr_realization_chunk_shape()  # reset to default
    expect_identical(get_Zarr_realization_chunk_shape(), shape0)
    expect_identical(prev_shape, "hypercube")
})

