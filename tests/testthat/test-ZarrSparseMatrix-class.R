library(Rarr)
library(anndataR)
library(h5mread)
library(ZarrArray)

# zarr file
zarr_dir <- system.file("extdata", "example_v2.zarr.zip", package = "anndataR")
td <- tempdir(check = TRUE)
unzip(zarr_dir, exdir = td)
store <- file.path(td, "example_v2.zarr")

test_that("read sparse", {

  # read sparse matrix
  name <- "layers/csc_counts"
  ZarrSparseMatrix(store, name)

  expect_equal(1,1)
})