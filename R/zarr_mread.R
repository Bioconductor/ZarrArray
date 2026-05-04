
### =========================================================================
### zarr_mread()
### -------------------------------------------------------------------------
###

### When both 'starts' and 'counts' are specified, the selection must be
### strictly ascending along each dimension.
### By default the user-supplied selection is checked and reduced (if it
### can be).
### Set 'as.integer' to TRUE to force returning the result as an integer array.
zarr_mread <- function(filepath, name, starts=NULL, counts=NULL, 
                       as.integer=FALSE)
{
  # check name
  # name <- normarg_zarr_name(name)
  
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
        # if (length(ok) != 1L && isTRUE(as.vector))
        if (length(ok) != 1L)
          stop(wmsg("when using multidimensional dataset, list elements ",
                    "in 'starts' must be strictly sorted"))
        starts <- lapply(seq_along(starts0),
                         function(i) {
                           start0 <- starts0[[i]]
                           if (ok[[i]])
                             return(start0)
                           start0 <- sort(start0)
                           start <- unique(start0)
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
  # This block mimics .Call2("C_h5mread", ...) from h5mread package
  # TODO: are we using all .Call2("C_h5mread") arguments ? 
  if(is.null(starts)){
    # TODO: is this necessary
    ndim <- length(zarrdim(filepath, name))
    index <- vector("list", ndim)
  } else {
    index <- mapply(function(x,y){
      if(length(x) < 1)
        return(numeric(0))
      unlist(
        mapply(function(xx,yy){
          seq(xx, xx+yy-1)
        }, x, y) 
      )
    }, starts, counts, SIMPLIFY = FALSE)
  }
  if(as.integer)
    index <- lapply(index, as.integer)
  ans <- read_zarr_array(file.path(filepath, name), index = index)
  
  if (is.null(starts) || !order_starts)
    return(ans)
  index <- lapply(seq_along(starts0),
                  function(i) {
                    if (ok[[i]])
                      return(NULL)
                    match(starts0[[i]], starts[[i]])
                  })
  if (is.array(ans)) {
    extract_array(ans, index)
  } else if (length(index) == 1L) {
    ans[index[[1L]]]
  } else {
    ## Sanity check (should never happen).
    stop(wmsg(".Call entry point C_zarrmread returned an unexpected object"))
  }
}