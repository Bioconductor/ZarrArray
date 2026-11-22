
test_that("append_zarr_array()", {
    append_zarr_array <- ZarrArray:::append_zarr_array

    ## --- data_type: "int32" ---

    zarr_path <- tempfile(fileext=".zarr")
    ## Rarr::create_empty_zarr_array() will emit a "Chunk dimensions are
    ## larger than array dimensions" warning, except when 'dim' is 0.
    ZarrArray:::create_empty_zarr_array2(zarr_path, dim=0L, chunkdim=10L,
                                         type="integer")
    x1 <- -10:100
    append_zarr_array(zarr_path, x1)
    expect_identical(Rarr::read_zarr_array(zarr_path), array(x1))
    x2 <- 1001:1005
    append_zarr_array(zarr_path, x2)
    expect_identical(Rarr::read_zarr_array(zarr_path), array(c(x1, x2)))
    append_zarr_array(zarr_path, integer(0))
    expect_identical(Rarr::read_zarr_array(zarr_path), array(c(x1, x2)))
    x3 <- 2001:2222
    append_zarr_array(zarr_path, x3)
    expect_identical(Rarr::read_zarr_array(zarr_path), array(c(x1, x2, x3)))

    zarr_path <- tempfile(fileext=".zarr")
    ## Suppress "Chunk dimensions are larger than array dimensions" warning.
    suppressWarnings(
        ZarrArray:::create_empty_zarr_array2(zarr_path, dim=2L, chunkdim=15L,
                                             type="integer", fill_value=-9L)
    )
    for (i in 3:15) {
        append_zarr_array(zarr_path, i)
        expected <- array(c(-9L, -9L, 3:i))
        expect_identical(Rarr::read_zarr_array(zarr_path), expected)
    }

    ## --- data_type: "float64" ---

    zarr_path <- tempfile(fileext=".zarr")
    ## Suppress "Chunk dimensions are larger than array dimensions" warning.
    suppressWarnings(
        ZarrArray:::create_empty_zarr_array2(zarr_path, dim=0L, chunkdim=50L,
                                             type="double", fill_value=-22)
    )
    x1 <- runif(22)
    append_zarr_array(zarr_path, x1)
    expect_identical(Rarr::read_zarr_array(zarr_path), array(x1))
    x2 <- runif(15)
    append_zarr_array(zarr_path, x2)
    expect_identical(Rarr::read_zarr_array(zarr_path), array(c(x1, x2)))
    append_zarr_array(zarr_path, double(0))
    expect_identical(Rarr::read_zarr_array(zarr_path), array(c(x1, x2)))
    x3 <- runif(300)
    append_zarr_array(zarr_path, x3)
    expect_identical(Rarr::read_zarr_array(zarr_path), array(c(x1, x2, x3)))

    ## --- data_type: "uint8" ---

    zarr_path <- tempfile(fileext=".zarr")
    ## WARNING: We're populating the original array below with small
    ## non-negative integers so Rarr::write_zarr_array() automatically decides
    ## to store them in an array of type "uint8". This means that any data
    ## that we append later to the array must "fit" in that data type. Values
    ## that don't (i.e. values < 0 or > 255) will **silently** be altered
    ## by Rarr::update_zarr_array(), the workhorse behind append_zarr_array().
    ## See IMPORTANT NOTE in R/append_zarr_array.R for more information.
    x0 <- array(11:18)
    suppressWarnings(Rarr::write_zarr_array(x0, zarr_path, chunk_dim=10L))
    x1 <- 19:25
    append_zarr_array(zarr_path, x1)
    expect_identical(Rarr::read_zarr_array(zarr_path), array(c(x0, x1)))
    append_zarr_array(zarr_path, integer(0))
    expect_identical(Rarr::read_zarr_array(zarr_path), array(c(x0, x1)))
    x2 <- 26:100
    append_zarr_array(zarr_path, x2)
    expect_identical(Rarr::read_zarr_array(zarr_path), array(c(x0, x1, x2)))
    x3 <- 101:122
    append_zarr_array(zarr_path, x3)
    expect_identical(Rarr::read_zarr_array(zarr_path), array(c(x0, x1, x2, x3)))
})

