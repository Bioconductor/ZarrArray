library(Rarr)
library(ZarrArray)
skip_if_not_installed("anndataR")

# test on both v2 and v3
for(v in c("v2", "v3")){
  
  # unpack zarr
  zarr_dir <- system.file("extdata", 
                          paste0("example_", v, ".zarr.zip"), 
                          package = "anndataR")
  td <- tempdir(check = TRUE)
  unzip(zarr_dir, exdir = td)
  zarr_path <- file.path(td, paste0("example_", v, ".zarr"))
  
  test_that("read sparse", {
    
    # read sparse matrix
    A <- ZarrADMatrix(zarr_path)
    expect_true(is(A, "ZarrADMatrix"))
    expect_true(is(A, "DelayedArray"))
    expect_true(is(seed(A), "ZarrADMatrixSeed"))
    expect_identical(tools::file_path_as_absolute(path(A)), zarr_path)
    expect_identical(dim(A), c(100L, 50L))
    expect_identical(type(A), "double")
    expect_identical(chunkdim(A), c(100L, 1L))
    
    expect_equal(1,1)
  }) 
}