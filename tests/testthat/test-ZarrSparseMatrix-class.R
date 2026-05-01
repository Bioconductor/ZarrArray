library(Rarr)
library(anndataR)
library(h5mread)
library(ZarrArray)

# zarr file
zarr_dir <- system.file("extdata", "example_v2.zarr.zip", package = "anndataR")
td <- tempdir(check = TRUE)
unzip(zarr_dir, exdir = td)
store <- file.path(td, "example_v2.zarr")

filepath <- store
name <- "/layers/csc_counts/indices"
start <- list(c( 1, 45,   87,  130,  171, 4099, 4144, 4190, 4235, 4279))
count <- list(c(44, 42, 43, 41, 42, 45, 46, 45, 44, 39))
as.integer <- TRUE
zarr_mread(filepath, name, starts=start, counts=count,
           as.vector=TRUE, as.integer=as.integer)

filepath <- system.file("extdata", "example.h5ad", package = "anndataR")
h5mread(filepath, name, starts=start, counts=count,
        as.vector=TRUE, as.integer=as.integer)

# # read sparse matrix
# name <- "layers/csc_counts"
# ZarrSparseMatrix(store, name)

# test_that("read sparse", {
#   
#   # read sparse matrix
#   name <- "layers/csc_counts"
#   ZarrSparseMatrix(store, name)
#   
#   expect_equal(1,1)
# })