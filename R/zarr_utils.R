### =========================================================================
### Some low-level HDF5 utilities
### -------------------------------------------------------------------------
###
### Nothing in this file is exported.
###

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### zarrexists()
###

zarrexists <- function(filepath, name)
{
  dir.exists(file.path(filepath, name))
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### zarrtype()
###

zarrtype <- function(filepath, name)
{
  loc <- file.path(filepath, name)
  if(file.exists(file.path(loc, ".zarray")))
    return("array")
    
  if(file.exists(file.path(loc, ".zgroup")))
    return("group")
  
  zarrjson <- file.path(loc, "zarr.json")
  if(file.exists(zarrjson)){
    zarrmeta <- jsonlite::read_json(zarrjson)
    if(zarrmeta[["node_type"]] == "group") {
      return("group") 
    } else {
      return("array") 
    }
  } 
  stop("Zarr node type cannot be determined!")
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### zarrisgroup()
###

zarrisgroup <- function(filepath, name)
{
  zarrtype(filepath, name) == "group"
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### zarrisdataset()
###

zarrisdataset <- function(filepath, name)
{
  zarrtype(filepath, name) == "array"
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### zarrdim() and zarrchunkdim()
###

zarrdim <- function(filepath, name, as.integer = TRUE)
{
  overview <- zarr_overview(file.path(filepath, name), 
                                  as_data_frame = TRUE)
  dim <- overview$dim[[1]]
  if (as.integer) 
    dim <- dim_as_integer(dim, filepath, name)
  dim
}

zarrchunkdim <- function(filepath, name, adjust=FALSE)
{
  overview <- zarr_overview(file.path(filepath, name), 
                                  as_data_frame = TRUE)
  chunkdim <- overview$chunk_dim[[1]]
  if (adjust) {
    dim <- overview$dim[[1]]
    stopifnot(length(chunkdim) == length(dim))
    chunkdim <- as.integer(pmin(dim, chunkdim))
  }
  chunkdim
}

# TODO: is this needed ?
dim_as_integer <- function(dim, filepath, name, what = "Zarr dataset") 
{
  if (is.integer(dim)) 
    return(dim)
  if (any(dim > .Machine$integer.max)) {
    dim_in1string <- paste0(dim, collapse = " x ")
    stop(wmsg("Dimensions of ", what, " are too big: ", dim_in1string), 
         "\n\n  ", wmsg("(This error is about Zarr dataset '", 
                        name, "' ", "from file '", filepath, "'.)"), 
         "\n\n  ", wmsg("Please note that the ZarrArray package only ", 
                        "supports datasets where each dimension is ", 
                        "<= '.Machine$integer.max' (= 2**31 - 1)."))
  }
  as.integer(dim)
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### normarg_zarr_filepath() and normarg_zarr_name()
###

normarg_zarr_filepath <- function(path, what1="'filepath'", what2="the dataset")
{
  if (!isSingleString(path))
    stop(wmsg(what1, " must be a single string specifying the path ",
              "to the Zarr directory where ", what2, " is located"))
  tools::file_path_as_absolute(path)  # return absolute path in canonical form
}

normarg_zarr_name <- function(name, what1="'name'",
                            what2="the name of a dataset",
                            what3="")
{
  if (!isSingleString(name))
    stop(wmsg(what1, " must be a single string specifying ",
              what2, " in the Zarr directory", what3))
  if (name == "")
    stop(wmsg(what1, " cannot be the empty string"))
  if (substr(name, start=1L, stop=1L) == "/") {
    name <- sub("^/*", "/", name)  # only keep first leading slash
  } else {
    name <- paste0("/", name)
  }
  name
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Used in validity methods
###

### 'path' is expected to be the **absolute** path to a local zarr array.
validate_zarr_absolute_path <- function(path, what="'path'")
{
  if (!(isSingleString(path) && nzchar(path)))
    return(paste0(what, " must be a single non-empty string"))
  
  ## Check that 'path' points to an Zarr directory that is accessible.
  if (!file.exists(path))
    return(paste0(what, " (\"", path, "\") must be the path to ",
                  "an existing zarr array"))
  if (!grepl(".zarr$", path))
    return(paste0(what, " (\"", path, "\") doesn't seem to be ",
                  "the path to a valid zarr array"))
  if (path != tools::file_path_as_absolute(path))
    return(paste0(what, " (\"", path, "\") must be the absolute ",
                  "canonical path the Zarr array"))
  TRUE
}

validate_zarr_dataset_name <- function(path, name, what="'name'")
{
  if (!(isSingleString(name) && nzchar(name)))
    return(paste0(what, " must be a single non-empty string"))
  
  if (!zarrexists(path, name))
    return(paste0(what, " (\"", name, "\") doesn't exist ",
                  "in Zarr directory \"", path, "\""))
  if (!zarrisdataset(path, name))
    return(paste0(what, " (\"", name, "\") is not a dataset ",
                  "in Zarr directory \"", path, "\""))
  zarr_dim <- try(zarrdim(path, name), silent=TRUE)
  if (inherits(zarr_dim, "try-error"))
    return(paste0(what, " (\"", name, "\") is a dataset with ",
                  "no dimensions in Zarr directory \"", path, "\""))
  TRUE
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Manipulate one-dimensional HDF5 datasets
###

### Length of a one-dimensional HDF5 dataset.
### Return the length as a single integer (if < 2^31) or numeric (if >= 2^31).
zarrlength <- function(filepath, name)
{
  len <- zarrdim(filepath, name, as.integer=FALSE)
  stopifnot(length(len) == 1L)
  len
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### ZarrCreateDataset()
###

compute_max_string_size <- function(x)
{
  if (type(x) != "character")
    return(NULL)
  if (length(x) == 0L)
    return(0L)
  max(nchar(x, type="bytes", keepNA=FALSE))
}

ZarrCreateDataset <- function(filepath, 
                              name, 
                              dim, 
                              maxdim=dim,
                              type="double", 
                              size=NULL,
                              chunkdim=dim, 
                              level=6L)
{
  stopifnot(is.numeric(dim),
            is.numeric(maxdim), length(maxdim) == length(dim))
  if (!is.null(chunkdim)) {
    stopifnot(is.numeric(chunkdim), length(chunkdim) == length(dim))
    chunkdim <- pmin(chunkdim, maxdim)
  }
  create_empty_zarr_array(file.path(filepath,name), 
                          dim = dim, 
                          chunk_dim = chunkdim, 
                          data_type = type, 
                          nchar = size)
}