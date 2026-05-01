### =========================================================================
### ZarrSparseMatrix objects
### -------------------------------------------------------------------------
###


setClass("ZarrSparseMatrix",
    contains="DelayedMatrix",
    representation(seed="ZarrSparseMatrixSeed")
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Constructor
###

setMethod("DelayedArray", "ZarrSparseMatrixSeed",
    function(seed) new_DelayedArray(seed, Class="ZarrSparseMatrix")
)

### Works directly on an ZarrSparseMatrixSeed derivative, in which case it must
### be called with a single argument.
ZarrSparseMatrix <- function(filepath, group)
{
    if (is(filepath, "ZarrSparseMatrixSeed")) {
        if (!missing(group))
            stop(wmsg("ZarrSparseMatrix() must be called with a single argument ",
                      "when passed an ZarrSparseMatrixSeed object"))
        seed <- filepath
    } else {
        seed <- ZarrSparseMatrixSeed(filepath, group)
    }
    DelayedArray(seed)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Taking advantage of sparsity
###

setMethod("nzcount", "ZarrSparseMatrix", function(x) nzcount(x@seed))

# setMethod("extractNonzeroDataByCol", "ZarrSparseMatrix",
#     function(x, j) extractNonzeroDataByCol(x@seed, j)
# )
# 
# setMethod("extractNonzeroDataByRow", "ZarrSparseMatrix",
#     function(x, i) extractNonzeroDataByCol(x@seed, i)
# )
