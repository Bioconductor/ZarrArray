
test_that("ZarrArraySeed()", {
    zarr_path <- system.file(package="Rarr", "extdata",
                         "zarr_examples", "column-first", "int32.zarr")
    seed <- ZarrArraySeed(zarr_path)
    expect_true(is(seed, "ZarrArraySeed"))
    expect_true(is(seed, "Array"))
    expect_true(is(seed, "OutOfMemoryObject"))

    expect_error(ZarrArraySeed(matrix(11:70, ncol=5)),
                 regexp="must be a single string")
    zarr_path <- tempfile()
    expect_error(ZarrArraySeed(zarr_path),
                 regexp="must be the path to an existing directory")
    file.create(zarr_path)
    expect_error(ZarrArraySeed(zarr_path),
                 regexp="must be the path to an existing directory, not a file")

    ## --- ZarrArraySeed() works on (most) Zarr examples in Rarr ---

    zarr_examples <- system.file(package="Rarr", "extdata", "zarr_examples")
    dirs <- list.dirs(zarr_examples, recursive=FALSE)
    dirs <- dirs[!(basename(dirs) %in% c("metadata", "structured"))]
    ## Some Zarr datasets are not supported at the moment:
    ## - The metadata in <zarr_examples>/column-first/vlenUTF8.zarr,
    ##   <zarr_examples>/compression/zstd_vlen.zarr, and
    ##   <zarr_examples>/row-first/other.zarr has metadata$datatype$base_type
    ##   set to "py_object" which ZarrArraySeed() does not handle.
    EXCLUDE_LIST <- c("vlenUTF8.zarr", "zstd_vlen.zarr", "other.zarr")
    for (dir in dirs) {
        zarr_paths <- list.dirs(dir, recursive=FALSE)
        zarr_paths <- zarr_paths[!(basename(zarr_paths) %in% EXCLUDE_LIST)]
        for (zarr_path in zarr_paths) {
            seed <- ZarrArraySeed(zarr_path)
            expect_true(is(seed, "ZarrArraySeed"))
            path(seed)
            dim(seed)
            type(seed)
            chunkdim(seed)
        }
    }
})

test_that("ZarrArraySeed methods", {
    zarr_path <- system.file(package="Rarr", "extdata",
                         "zarr_examples", "column-first", "int32.zarr")
    seed <- ZarrArraySeed(zarr_path)
    expect_identical(tools::file_path_as_absolute(path(seed)), zarr_path)
    expect_identical(dim(seed), c(30L, 20L, 10L))
    expect_identical(type(seed), "integer")
    expect_identical(extract_array(seed, list(1L, NULL, 1L)),
                     array(1:20, dim=c(1L, 20L, 1L)))
    expect_identical(chunkdim(seed), c(10L, 10L, 5L))
})

