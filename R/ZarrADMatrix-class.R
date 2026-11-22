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
ZarrADMatrix <- function(zarr_store, layer=NULL)
{
  if (is(zarr_store, "ZarrADMatrixSeed")) {
    if (!is.null(layer))
      stop(wmsg("ZarrADMatrix() must be called with a single argument ",
                "when passed an ZarrADMatrixSeed derivative"))
    seed <- zarr_store
  } else {
    seed <- ZarrADMatrixSeed(zarr_store, layer=layer)
  }
  DelayedArray(seed)
}