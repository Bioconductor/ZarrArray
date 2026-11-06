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

### Works directly on a ZarrSparseMatrixSeed derivative, in which case it must
### be called with a single argument.
ZarrSparseMatrix <- function(zarr_store, group="/")
{
    if (is(zarr_store, "ZarrSparseMatrixSeed")) {
        if (!missing(group))
            stop(wmsg("ZarrSparseMatrix() must be called with a single ",
                      "argument when passed a ZarrSparseMatrixSeed object"))
        seed <- zarr_store
    } else {
        seed <- ZarrSparseMatrixSeed(zarr_store, group)
    }
    DelayedArray(seed)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Taking advantage of sparsity
###

setMethod("nzcount", "ZarrSparseMatrix", function(x) nzcount(x@seed))

