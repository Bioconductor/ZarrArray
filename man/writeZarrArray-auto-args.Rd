\name{writeZarrArray-auto-args}

\alias{writeZarrArray-auto-args}
\alias{writeZarrArray_auto_args}

\alias{get_writeZarrArray_dump_dir}
\alias{set_writeZarrArray_dump_dir}
\alias{get_writeZarrArray_auto_path}
\alias{get_writeZarrArray_chunk_maxlen}
\alias{set_writeZarrArray_chunk_maxlen}
\alias{get_writeZarrArray_chunk_shape}
\alias{set_writeZarrArray_chunk_shape}
\alias{get_writeZarrArray_auto_chunkdim}

\title{Control writeZarrArray's automatic argument values}

\description{
  IMPORTANT NOTE: Starting with Bioconductor 3.25, all the functions
  documented in this man page are deprecated in favor of the new
  functions documented in \code{?\link{Zarr_realization_settings}}.
  Please do NOT use them. They will become defunct in Bioconductor 3.26!

  \code{get_writeZarrArray_auto_path()} and
  \code{get_writeZarrArray_auto_chunkdim()} are used internally by
  \code{\link{writeZarrArray}()} and \code{\link{ZarrRealizationSink}()}
  to obtain \emph{automatic values} for their \code{zarr_path}
  and \code{chunkdim} arguments when those arguments are not supplied.
}

\usage{
## Used internally by writeZarrArray() to obtain "automatic values" for
## arguments 'zarr_path' and 'chunkdim':
get_writeZarrArray_auto_path()
get_writeZarrArray_auto_chunkdim(dim)

## Control the value returned by get_writeZarrArray_auto_path():
set_writeZarrArray_dump_dir(dir)

## Control the value returned by get_writeZarrArray_auto_chunkdim():
set_writeZarrArray_chunk_maxlen(maxlen=250000L)
set_writeZarrArray_chunk_shape(shape="scale")

## The "get" functions that correspond to the "set" functions above:
get_writeZarrArray_dump_dir()
get_writeZarrArray_chunk_maxlen()
get_writeZarrArray_chunk_shape()
}

\arguments{
  \item{dim}{
    The dimensions (as an integer vector) of the array-like object to be
    realized to disk in Zarr format.
  }
  \item{dir}{
    The path (as a single string) to the "realization dump", that is, to
    the directory where realization of array-like objects in Zarr format
    should happen by default.
    If \code{dir} is missing, then the "realization dump" is set
    back to its default which is some directory under \code{tempdir()}.
  }
  \item{maxlen}{
    The "maximum chunk length", that is, the maximum number of array
    elements per physical chunk when realizing an array-like object to
    disk in Zarr format.
  }
  \item{shape}{
    A string describing the shape of the physical chunks to use by
    default when realizing an array-like object to disk in Zarr format.
    See \code{\link[DelayedArray]{makeCappedVolumeBox}} in the
    \pkg{DelayedArray} package for the supported shapes.
  }
}

\details{
  Here's how \code{\link{writeZarrArray}()} obtains its \emph{automatic
  argument values}:
  \itemize{
    \item The automatic value for \code{zarr_path} is obtained with
          \code{get_writeZarrArray_auto_path()}.
    \item The automatic value for \code{chunkdim} is obtained with
          \code{chunkdim(x)} where \code{x} is the array-like object
          passed to \code{\link{writeZarrArray}}.
          If \code{chunkdim(x)} returns \code{NULL} (which can happen if
          \code{x} is an in-memory object or if the dimensions of its
          physical chunks cannot be determined), then \code{chunkdim}
          is obtained with \code{get_writeZarrArray_auto_chunkdim(dim(x))}.
  }

  The \pkg{ZarrArray} package provides a set of utility functions to
  control the values returned by \code{get_writeZarrArray_auto_path()}
  and \code{get_writeZarrArray_auto_chunkdim()}:
  \itemize{
    \item The value returned by \code{get_writeZarrArray_auto_path()}
          is controlled by \code{set_writeZarrArray_dump_dir()}.

    \item The value returned by \code{get_writeZarrArray_auto_chunkdim()}
          is controlled by \code{set_writeZarrArray_chunk_maxlen()} and
          \code{set_writeZarrArray_chunk_shape()}.
  }

  In other words, the \code{set_writeZarrArray_*()} utility functions
  provide some control over the behavior of \code{\link{writeZarrArray}()}
  and \code{\link{ZarrRealizationSink}()} when the latter are called with
  their first argument only, like in:
  \preformatted{    a <- array(101:160, dim=5:3)
    A <- writeZarrArray(a)}
  or in:
  \preformatted{    ZarrRealizationSink(dim(a))}

  Consequently, they also provide some control over the behavior of
  coercion of an arbitrary array-like object to \link{ZarrArray} (i.e.
  on \code{as(a, "ZarrArray")}), since this coercion simply calls
  \code{\link{writeZarrArray}()} on the supplied object.
}

\value{
  \code{get_writeZarrArray_auto_path()} returns a single string
  containing the automatic path used by \code{\link{writeZarrArray}()}
  when its \code{zarr_path} argument is not specified.
  Note that the function is used internally by \code{\link{writeZarrArray}()}
  and is not meant to be used directly by the user.

  \code{get_writeZarrArray_auto_chunkdim()} returns an integer vector
  containing the automatic chunk dimensions used by
  \code{\link{writeZarrArray}()} when its \code{chunkdim} argument is
  not specified.
  Note that the function is used internally by \code{\link{writeZarrArray}()}
  and is not meant to be used directly by the user.

  \code{get_writeZarrArray_dump_dir()} returns a single string containing
  the path to the "realization dump".
  \code{set_writeZarrArray_dump_dir()} returns an invisible single string
  containing the previous path to the "realization dump". In other words,
  \preformatted{    prev_dir <- set_writeZarrArray_dump_dir(dir)}
  is equivalent to
  \preformatted{    prev_dir <- get_writeZarrArray_dump_dir()
    set_writeZarrArray_dump_dir(dir)}

  \code{get_writeZarrArray_chunk_maxlen()} returns the "maximum chunk length"
  (i.e. maximum number of array elements) of the physical chunks to use by
  default when realizing an array-like object to disk in Zarr format.
  \code{set_writeZarrArray_chunk_maxlen()} returns an invisible number
  that is the previous "maximum chunk length". In other words,
  \preformatted{    prev_maxlen <- set_writeZarrArray_chunk_maxlen(maxlen)}
  is equivalent to
  \preformatted{    prev_maxlen <- get_writeZarrArray_chunk_maxlen()
    set_writeZarrArray_chunk_maxlen(maxlen)}

  \code{get_writeZarrArray_chunk_shape()} returns a single string describing
  the "chunk shape", that is, the shape of the physical chunks to use by
  default when realizing an array-like object to disk in Zarr format.
  \code{set_writeZarrArray_chunk_shape()} returns an invisible string
  describing the previous "chunk shape". In other words,
  \preformatted{    prev_shape <- set_writeZarrArray_chunk_shape(shape)}
  is equivalent to
  \preformatted{    prev_shape <- get_writeZarrArray_chunk_shape()
    set_writeZarrArray_chunk_shape(shape)}
}

\seealso{
  \itemize{
    \item \code{\link{writeZarrArray}} for writing an array-like object
          to disk in Zarr format.

    \item \link{ZarrArray} objects.

    \item \code{\link[DelayedArray]{makeCappedVolumeBox}} in the
          \pkg{DelayedArray} package.
  }
}

\examples{
## IMPORTANT NOTE: Starting with Bioconductor 3.25, all the functions
## documented in this man page are deprecated in favor of the new
## functions documented in '?Zarr_realization_settings'. Please do NOT
## use them. They will become defunct in Bioconductor 3.26!
\dontrun{
a <- array(101:160, dim=5:3)

get_writeZarrArray_dump_dir()  # default "Zarr realization dump"
A1 <- writeZarrArray(a)
path(A1)

## Take control of where writeZarrArray() should write Zarr datasets
## by default:
my_zarr_dump <- file.path(tempdir(), "my_zarr_dump")
set_writeZarrArray_dump_dir(my_zarr_dump)
A2 <- writeZarrArray(a)
path(A2)

m <- matrix(101:140, ncol=8)
M <- as(m, "ZarrArray")  # equivalent to writeZarrArray(m)
path(M)

## Reset "Zarr realization dump" to its default:
set_writeZarrArray_dump_dir()
}
}
\keyword{utilities}
