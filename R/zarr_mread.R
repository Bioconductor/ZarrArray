
### =========================================================================
### zarr_mread()
### -------------------------------------------------------------------------
###

### The R type returned by zarr_mread() is determined by arguments 'filepath',
### 'name', and 'as.integer'.
get_zarrmread_returned_type <- function(filepath, name, as.integer=FALSE)
{
  name <- normarg_zarr_name(name)
  
  .Call2("C_get_zarrmread_returned_type", filepath, name, as.integer,
         PACKAGE="HDF5Array")
}

### When both 'starts' and 'counts' are specified, the selection must be
### strictly ascending along each dimension.
### By default the user-supplied selection is checked and reduced (if it
### can be).
### Set 'noreduce' to TRUE to skip the reduction step.
### Set 'as.integer' to TRUE to force returning the result as an integer array.
zarr_mread <- function(filepath, name, starts=NULL, counts=NULL, noreduce=FALSE,
                    as.vector=NA, as.integer=FALSE, as.sparse=FALSE)
{
  # check name
  # name <- normarg_zarr_name(name)
  
  if (!isTRUEorFALSE(as.sparse))
    stop(wmsg("'as.sparse' must be TRUE or FALSE"))
  if (is.null(starts)) {
    if (!is.null(counts))
      stop(wmsg("'counts' must be NULL when 'starts' is NULL"))
  } else if (is.list(starts)) {
    order_starts <- is.null(counts) &&
      !all(S4Vectors:::sapply_isNULL(starts))
    if (order_starts) {
      ## Round the 'starts'.
      starts0 <- lapply(starts,
                        function(start) {
                          if (is.null(start))
                            return(NULL)
                          if (!is.numeric(start))
                            stop(wmsg("each list element in 'starts' must ",
                                      "be NULL or a numeric vector"))
                          if (!is.integer(start))
                            start <- round(start)
                          start
                        })
      ok <- vapply(starts0,
                   function(start0) is.null(start0) || isStrictlySorted(start0),
                   logical(1))
      order_starts <- !all(ok)
      if (order_starts) {
        if (length(ok) != 1L && isTRUE(as.vector))
          stop(wmsg("when using 'as.vector=TRUE' on a ",
                    "multidimensional dataset, list elements ",
                    "in 'starts' must be strictly sorted"))
        starts <- lapply(seq_along(starts0),
                         function(i) {
                           start0 <- starts0[[i]]
                           if (ok[[i]])
                             return(start0)
                           start0 <- sort(start0)
                           start <- unique(start0)
                           if (as.sparse && length(start) != length(start0))
                             stop(wmsg("when using 'as.sparse=TRUE', list ",
                                       "elements in 'starts' are not allowed ",
                                       "to contain duplicates"))
                           start
                         })
      } else {
        starts <- starts0
      }
    }
  } else {
    stop(wmsg("'starts' must be a list (or NULL)"))
  }

  # read zarr
  if(is.null(starts)){
    # TODO: is this necessary
    ndim <- length(zarrdim(filepath, name))
    index <- vector("list", ndim)
  } else {
    index <- starts
  }
  ans <- read_zarr_array(file.path(filepath, name), index = index)
  
  if (as.sparse)
    ans <- COO_SparseArray(ans[[1L]], ans[[2L]], ans[[3L]], check=FALSE)
  if (is.null(starts) || !order_starts)
    return(ans)
  index <- lapply(seq_along(starts0),
                  function(i) {
                    if (ok[[i]])
                      return(NULL)
                    match(starts0[[i]], starts[[i]])
                  })
  if (as.sparse) {
    extract_sparse_array(ans, index)
  } else if (is.array(ans)) {
    extract_array(ans, index)
  } else if (length(index) == 1L) {
    ans[index[[1L]]]
  } else {
    ## Sanity check (should never happen).
    stop(wmsg(".Call entry point C_zarrmread returned an unexpected object"))
  }
}