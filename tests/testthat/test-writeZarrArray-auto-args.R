
test_that("get_writeZarrArray_auto_*()", {
    path <- get_writeZarrArray_auto_path()
    expect_true(isSingleString(path))
    expect_identical(dirname(path), get_writeZarrArray_dump_dir())

    set_writeZarrArray_chunk_shape("scale")  # the default

    set_writeZarrArray_chunk_maxlen(1e6)  # the default
    chunkdim <- get_writeZarrArray_auto_chunkdim(c(2800, 2800, 2800))
    expect_identical(chunkdim, c(100L, 100L, 100L))  # prod() == 1e6
    chunkdim <- get_writeZarrArray_auto_chunkdim(c(1500, 6000, 3000))
    expect_identical(chunkdim, c(50L, 200L, 100L))  # prod() == 1e6

    set_writeZarrArray_chunk_maxlen(12000)
    chunkdim <- get_writeZarrArray_auto_chunkdim(c(2500, 2500, 3750))
    expect_identical(chunkdim, c(20L, 20L, 30L))  # prod() == 12000
    chunkdim <- get_writeZarrArray_auto_chunkdim(c(6000, 4500, 1500))
    expect_identical(chunkdim, c(40L, 30L, 10L))  # prod() == 12000
    chunkdim <- get_writeZarrArray_auto_chunkdim(c(35, 5, 30))
    expect_identical(chunkdim, c(35L, 5L, 30L))   # prod() < 12000

    set_writeZarrArray_chunk_shape("hypercube")

    set_writeZarrArray_chunk_maxlen(125000)
    chunkdim <- get_writeZarrArray_auto_chunkdim(c(1500, 6000, 3000))
    expect_identical(chunkdim, c(50L, 50L, 50L))   # prod() == 125000
    chunkdim <- get_writeZarrArray_auto_chunkdim(c(50, 500, 10))
    expect_identical(chunkdim, c(50L, 250L, 10L))  # prod() == 125000
    chunkdim <- get_writeZarrArray_auto_chunkdim(c(10, 99, 40))
    expect_identical(chunkdim, c(10L, 99L, 40L))   # prod() < 125000
})

test_that("get/set_writeZarrArray_dump_dir()", {
    set_writeZarrArray_dump_dir()  # reset to default

    dir0 <- get_writeZarrArray_dump_dir()
    expect_true(isSingleString(dir0))
    expect_true(dir.exists(dir0))

    dir1 <- tempfile("my_zarr_collection_")
    prev_dir <- set_writeZarrArray_dump_dir(dir1)
    expect_identical(
        normalizePath(get_writeZarrArray_dump_dir()), 
        normalizePath(dir1)
    )
    expect_identical(
        normalizePath(prev_dir), 
        normalizePath(dir0)
    )

    prev_dir <- set_writeZarrArray_dump_dir()  # reset to default
    expect_identical(get_writeZarrArray_dump_dir(), dir0)
    expect_identical(
        normalizePath(prev_dir), 
        normalizePath(dir1)
    )
})

test_that("get/set_writeZarrArray_chunk_maxlen()", {
    set_writeZarrArray_chunk_maxlen()  # reset to default

    maxlen0 <- get_writeZarrArray_chunk_maxlen()
    expect_true(isSingleNumber(maxlen0))

    prev_maxlen <- set_writeZarrArray_chunk_maxlen(125000)
    expect_identical(get_writeZarrArray_chunk_maxlen(), 125000)
    expect_identical(prev_maxlen, maxlen0)

    prev_maxlen <- set_writeZarrArray_chunk_maxlen()  # reset to default
    expect_identical(get_writeZarrArray_chunk_maxlen(), maxlen0)
    expect_identical(prev_maxlen, 125000)
})

test_that("get/set_writeZarrArray_chunk_shape()", {
    set_writeZarrArray_chunk_shape()  # reset to default

    shape0 <- get_writeZarrArray_chunk_shape()
    expect_identical(shape0, "scale")

    prev_shape <- set_writeZarrArray_chunk_shape("hypercube")
    expect_identical(get_writeZarrArray_chunk_shape(), "hypercube")
    expect_identical(prev_shape, shape0)

    prev_shape <- set_writeZarrArray_chunk_shape()  # reset to default
    expect_identical(get_writeZarrArray_chunk_shape(), shape0)
    expect_identical(prev_shape, "hypercube")
})

