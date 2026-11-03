### =========================================================================
### ZarrADMatrixSeed objects
### -------------------------------------------------------------------------


setClass("ZarrADMatrixSeed",
         contains=c("Array", "OutOfMemoryObject"),
         representation("VIRTUAL")
)

setClass("Dense_ZarrADMatrixSeed",
         contains=c("ZarrADMatrixSeed", "ZarrArraySeed"),
         representation(dimnames="list"),
         prototype(dimnames=list(NULL, NULL))
)
setClass("CSC_ZarrADMatrixSeed",
         contains=c("ZarrADMatrixSeed", "CSC_ZarrSparseMatrixSeed")
)
setClass("CSR_ZarrADMatrixSeed",
         contains=c("ZarrADMatrixSeed", "CSR_ZarrSparseMatrixSeed")
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### dimnames() method for Dense_ZarrADMatrixSeed objects
###

### We overwrite the method for ZarrArraySeed objects with a method that
### accesses the slot, not the store
setMethod("dimnames", "Dense_ZarrADMatrixSeed",
          function(x) S4Arrays:::simplify_NULL_dimnames(x@dimnames)
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Transposition
###

### S3/S4 combo for t.CSC_ZarrADMatrixSeed
t.CSC_ZarrADMatrixSeed <- function(x)
{
  new2("CSR_ZarrADMatrixSeed", callNextMethod())
}
setMethod("t", "CSC_ZarrADMatrixSeed", t.CSC_ZarrADMatrixSeed)

### S3/S4 combo for t.CSR_ZarrADMatrixSeed
t.CSR_ZarrADMatrixSeed <- function(x)
{
  new2("CSC_ZarrADMatrixSeed", callNextMethod())
}
setMethod("t", "CSR_ZarrADMatrixSeed", t.CSR_ZarrADMatrixSeed)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Constructor
###

.load_zarr_ad_rownames <- function(zarr_store, name="var")
{
  ok <- try(zarr_node_is_group(zarr_store, name), silent=TRUE)
  if (!isTRUE(ok))
    return(NULL)
  ROWNAMES_DATASET <- file.path(name, "_index")
  ok <- try(zarr_node_is_dataset(zarr_store, ROWNAMES_DATASET), silent=TRUE)
  if (!isTRUE(ok))
    return(NULL)
  read_zarr_array(file.path(zarr_store, ROWNAMES_DATASET))
}

### Must return a list of length 2.
.load_zarr_ad_dimnames <- function(zarr_store)
{
  ans_rownames <- .load_zarr_ad_rownames(zarr_store)
  ans_colnames <- .load_zarr_ad_rownames(zarr_store, name="obs")
  if (is.null(ans_rownames) && is.null(ans_colnames))
    warning(wmsg("could not find dimnames in this anndata-zarr store"))
  list(ans_rownames, ans_colnames)
}

### Returns an ZarrADMatrixSeed derivative (can be either a Dense_ZarrADMatrixSeed,
### or a CSC_ZarrSparseMatrixSeed, or a CSR_ZarrSparseMatrixSeed object).
ZarrADMatrixSeed <- function(zarr_store, layer=NULL)
{
  if (!isSingleString(zarr_store))
    stop(wmsg("'zarr_store' must be a single string specifying the ",
              "path to the anndata-zarr store"))
  zarr_store <- file_path_as_absolute(zarr_store)
  if (is.null(layer)) {
    name <- "X"
  } else {
    if (!isSingleString(layer) || !nzchar(layer))
      stop(wmsg("'layer' must be NULL or a single non-empty string"))
    name <- file.path("layers", layer)
  }
  if (!zarr_exists(zarr_store, name)) {
    msg <- c("Zarr object \"", name, "\" does not exist ",
             "in this Zarr store")
    if (is.null(layer))
      msg <- c(msg, " Is this a valid anndata-zarr store?")
    stop(wmsg(msg))
  }
  dimnames <- .load_zarr_ad_dimnames(zarr_store)
  
  if (zarr_node_is_dataset(zarr_store, name)) {
    ans0 <- ZarrArraySeed(zarr_store, name)
    if (length(dim(ans0)) != 2L)
      stop(wmsg("Zarr dataset \"", name, "\" in store \"", zarr_store, "\" ",
                "does not have exactly 2 dimensions. Please consider ",
                "using the ZarrArray() constructor to access this ",
                "dataset."))
    ans <- new2("Dense_ZarrADMatrixSeed", ans0, dimnames=dimnames)
  } else if (zarr_node_is_group(zarr_store, name)) {
    ans0 <- ZarrSparseMatrixSeed(zarr_store, name)
    if (is(ans0, "CSC_ZarrSparseMatrixSeed"))
      ans_class <- "CSC_ZarrADMatrixSeed"
    else
      ans_class <- "CSR_ZarrADMatrixSeed"
    ans <- new2(ans_class, ans0, dimnames=dimnames)
  } else {
    stop(wmsg("Zarr object \"", name, "\" in store \"", zarr_store, "\" ",
              "is neither a dataset or a group. Is this a valid ",
              "anndata-zarr store?"))
  }
  ans
}