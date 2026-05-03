### =========================================================================
### ZarrADMatrix objects
### -------------------------------------------------------------------------
###

setClass("ZarrADMatrix",
         contains="DelayedMatrix",
         representation(seed="ZarrADMatrixSeed")
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Constructor
###

setMethod("DelayedArray", "ZarrADMatrixSeed",
          function(seed) new_DelayedArray(seed, Class="ZarrADMatrix")
)

### Works directly on an ZarrADMatrixSeed derivative, in which case it must
### be called with a single argument.
ZarrADMatrix <- function(filepath, layer=NULL)
{
  if (is(filepath, "ZarrADMatrixSeed")) {
    if (!is.null(layer))
      stop(wmsg("ZarrADMatrix() must be called with a single argument ",
                "when passed an ZarrADMatrixSeed derivative"))
    seed <- filepath
  } else {
    seed <- ZarrADMatrixSeed(filepath, layer=layer)
  }
  DelayedArray(seed)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Taking advantage of sparsity
###

### Will work only if the seed is an H5SparseMatrixSeed derivative, that is,
### if it's a CSC_ZarrADMatrixSeed or CSR_ZarrADMatrixSeed object.
setMethod("nzcount", "ZarrADMatrix", function(x) nzcount(x@seed))

### Will work only if the seed is a CSC_ZarrADMatrixSeed object.
setMethod("extractNonzeroDataByCol", "ZarrADMatrix",
          function(x, j) extractNonzeroDataByCol(x@seed, j)
)

### Will work only if the seed is a CSR_ZarrADMatrixSeed object.
setMethod("extractNonzeroDataByRow", "ZarrADMatrix",
          function(x, i) extractNonzeroDataByCol(x@seed, i)
)