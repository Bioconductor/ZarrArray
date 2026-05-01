### =========================================================================
### ZarrArray objects
### -------------------------------------------------------------------------
###
### Note that we could just wrap a ZarrArraySeed object in a DelayedArray
### object to represent and manipulate a Zarr dataset as a DelayedArray
### object. So, strictly speaking, we don't really need the ZarrArray and
### ZarrMatrix classes. However, we define these classes mostly for cosmetic
### reasons, that is, to hide the DelayedArray and DelayedMatrix classes
### from the user. So the user will see and manipulate ZarrArray and
### ZarrMatrix objects instead of DelayedArray and DelayedMatrix objects.
###


setClass("ZarrArray",
    contains="DelayedArray",
    slots=c(seed="ZarrArraySeed")
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Constructor
###

setMethod("DelayedArray", "ZarrArraySeed",
    function(seed) new_DelayedArray(seed, Class="ZarrArray")
)

### Can take a ZarrArraySeed object.
ZarrArray <- function(zarr_path, s3_client=NULL)
{
    if (is(zarr_path, "ZarrArraySeed")) {
        if (!missing(s3_client))
            stop(wmsg("ZarrArray() must be called with a single argument ",
                      "when passed a ZarrArraySeed object"))
        seed <- zarr_path
    } else {
        seed <- ZarrArraySeed(zarr_path, s3_client=s3_client)
    }
    DelayedArray(seed)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### ZarrMatrix objects
###

setClass("ZarrMatrix", contains=c("ZarrArray", "DelayedMatrix"))

### Required for DelayedArray internal business.
setMethod("matrixClass", "ZarrArray", function(x) "ZarrMatrix")

### Automatic coercion method from ZarrArray to ZarrMatrix silently returns
### a broken object (unfortunately these dummy automatic coercion methods
### don't bother to validate the object they return). So we overwrite it.
setAs("ZarrArray", "ZarrMatrix", function(from) new("ZarrArray", from))

### The user should not be able to degrade a ZarrMatrix object to
### a ZarrArray object so 'as(x, "ZarrArray", strict=TRUE)' should
### fail or be a no-op when 'x' is a ZarrMatrix object. Making this
### coercion a no-op seems to be the easiest (and safest) way to go.
setAs("ZarrMatrix", "ZarrArray", function(from) from)  # no-op

