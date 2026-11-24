\name{Zarr-realization-settings}

\alias{Zarr-realization-settings}
\alias{Zarr_realization_settings}

\alias{get_Zarr_realization_dump_dir}
\alias{set_Zarr_realization_dump_dir}
\alias{get_Zarr_realization_auto_path}
\alias{get_Zarr_realization_chunk_maxsize}
\alias{set_Zarr_realization_chunk_maxsize}
\alias{get_Zarr_realization_chunk_maxlen}
\alias{get_Zarr_realization_chunk_shape}
\alias{set_Zarr_realization_chunk_shape}
\alias{get_Zarr_realization_auto_chunkdim}
\alias{get_Zarr_realization_auto_version}
\alias{set_Zarr_realization_auto_version}

\alias{get_Zarr_realization_auto_group}
\alias{set_Zarr_realization_auto_group}
\alias{get_Zarr_realization_auto_layout}
\alias{set_Zarr_realization_auto_layout}

\title{Control Zarr realization settings}

\description{
  \code{get_Zarr_realization_auto_path()} is used internally by
  \code{\link{writeZarrArray}()} and \code{\link{writeZarrSparseMatrix}()}
  to obtain the \emph{automatic value} of their \code{zarr_path} and
  \code{zarr_store} arguments when those arguments are not supplied.

  \code{get_Zarr_realization_auto_chunkdim()} is used internally by
  \code{\link{writeZarrArray}()} to obtain the \emph{automatic value}
  of its \code{chunkdim} argument when this argument is not supplied.

  \code{get_Zarr_realization_auto_version()} is used internally by
  \code{\link{writeZarrArray}()} and \code{\link{writeZarrSparseMatrix}()}
  to obtain the \emph{automatic value} of their \code{zarr_version}
  argument when this argument is not supplied.

  \code{get_Zarr_realization_auto_group()} and
  \code{get_Zarr_realization_auto_layout()} are used internally by
  \code{\link{writeZarrSparseMatrix}()} to obtain the \emph{automatic values}
  of its \code{group} and \code{sparse.layout} arguments when these arguments
  are not supplied.
}

\usage{
## Used internally by writeZarrArray() or writeZarrSparseMatrix()
## when 'zarr_path' or 'zarr_store' is set to "auto":
get_Zarr_realization_auto_path()

## Used internally by writeZarrArray() when 'chunkdim' is set to "auto":
get_Zarr_realization_auto_chunkdim(dim, type)

## Used internally by writeZarrArray() or writeZarrSparseMatrix()
## when 'zarr_version' is set to "auto":
get_Zarr_realization_auto_version()

## Used internally by writeZarrSparseMatrix() when 'group'
## or 'sparse.layout' is set to "auto":
get_Zarr_realization_auto_group()
get_Zarr_realization_auto_layout()

## Controls the value returned by get_Zarr_realization_auto_path():
set_Zarr_realization_dump_dir(dir)

## Controls the value returned by get_Zarr_realization_auto_chunkdim():
set_Zarr_realization_chunk_maxsize(maxsize=1000000L)
set_Zarr_realization_chunk_shape(shape="scale")

## Controls the value returned by get_Zarr_realization_auto_version():
set_Zarr_realization_auto_version(zarr_version=3)

## Control the values returned by get_Zarr_realization_auto_group()
## and get_Zarr_realization_auto_layout():
set_Zarr_realization_auto_group(group="/")
set_Zarr_realization_auto_layout(sparse.layout="tenx")

## The "get" functions that correspond to the "set" functions above:
get_Zarr_realization_dump_dir()
get_Zarr_realization_chunk_maxsize()
get_Zarr_realization_chunk_maxlen(type)
get_Zarr_realization_chunk_shape()
}

\arguments{
  \item{dim}{
    The dimensions (as an integer vector) of the array-like object to be
    realized to disk in Zarr format.
  }
  \item{type}{
    The type (a.k.a. storage mode) of the array-like object to be
    realized to disk in Zarr format. Can be obtained by calling
    \code{\link[S4Arrays]{type}()} on the array-like object.
    See \code{?S4Arrays::\link[S4Arrays]{type}} in the \pkg{S4Arrays}
    package for more information.
  }
  \item{dir}{
    The path (as a single string) to the "Zarr realization dump", that is,
    to the directory where realization of array-like objects in Zarr format
    should happen by default.

    If \code{dir} is missing, then the "Zarr realization dump" is set
    back to its default which is some directory under \code{tempdir()}.
  }
  \item{maxsize}{
    The "maximum chunk size", that is, the size in bytes and before
    compression of the physical chunks to use by default when realizing
    an array-like object to disk in Zarr format.
  }
  \item{shape}{
    A string describing the shape of the physical chunks to use by
    default when realizing an array-like object to disk in Zarr format.
    See \code{\link[DelayedArray]{makeCappedVolumeBox}} in the
    \pkg{DelayedArray} package for the supported shapes.
  }
  \item{zarr_version}{
    The version of the Zarr specification (i.e. 2 or 3) to use by
    default when realizing an array-like object to disk in Zarr format.
  }
  \item{group}{
    The name of the group node in the "Zarr realization dump" where to
    write the matrix data in "Zarr sparse" format.
  }
  \item{sparse.layout}{
    The sparse layout to use to write the matrix data in "Zarr sparse" format.
    See \code{?\link{writeZarrSparseMatrix}} for the layouts that are
    currently supported.
  }
}

\details{
  Here's how \code{\link{writeZarrArray}()} obtains its \emph{automatic
  argument values}:
  \itemize{
    \item The automatic value for \code{zarr_path} is obtained with
          \code{get_Zarr_realization_auto_path()}.
    \item The automatic value for \code{chunkdim} is obtained with
          \code{chunkdim(x)} where \code{x} is the array-like object
          passed to \code{\link{writeZarrArray}}.
          If \code{chunkdim(x)} returns \code{NULL} (which can happen
          if \code{x} is an in-memory object or if the dimensions of
          its physical chunks cannot be determined), then
          \code{chunkdim} is obtained with:
          \preformatted{    get_Zarr_realization_auto_chunkdim(dim(x), type(x))}
    \item The automatic value for \code{zarr_version} is obtained with
          \code{get_Zarr_realization_auto_version()}.
  }

  The \pkg{ZarrArray} package provides a set of utilities to control
  the values returned by \code{get_Zarr_realization_auto_path()},
  \code{get_Zarr_realization_auto_chunkdim()}, and
  \code{get_Zarr_realization_auto_version()}:
  \itemize{
    \item The value returned by \code{get_Zarr_realization_auto_path()}
          is controlled by \code{set_Zarr_realization_dump_dir()}.

    \item The value returned by \code{get_Zarr_realization_auto_chunkdim()}
          is controlled by \code{set_Zarr_realization_chunk_maxsize()} and
          \code{set_Zarr_realization_chunk_shape()}.

    \item The value returned by \code{get_Zarr_realization_auto_version()}
          is controlled by \code{set_Zarr_realization_auto_version()}.
  }

  In other words, the \code{set_Zarr_realization_*()} utility functions
  provide some control over the behavior of \code{\link{writeZarrArray}()}
  (and \code{\link{writeZarrSparseMatrix}()}) when the latter is called with
  its first argument only, like in:
  \preformatted{    a <- array(101:160, dim=5:3)
    A <- writeZarrArray(a)}
  or in:
  \preformatted{    sm <- poissonSparseMatrix(20, 15)
    ZSM <- writeZarrSparseMatrix(m)}

  Consequently, they also provide some control over the behavior of
  coercion of an arbitrary array-like object to \link{ZarrArray} (i.e.
  on \code{as(a, "ZarrArray")}), since this coercion simply calls
  \code{\link{writeZarrArray}()} on the supplied object.
}

\value{
  \code{get_Zarr_realization_auto_path()} returns a single string
  containing the automatic path used by \code{\link{writeZarrArray}()}
  (or \code{\link{writeZarrSparseMatrix}()}) when its \code{zarr_path}
  (or \code{zarr_store}) argument is not specified.
  Note that the function is used \emph{internally} by
  \code{\link{writeZarrArray}()} (or \code{\link{writeZarrSparseMatrix}()})
  and is not meant to be used directly by the user.

  \code{get_Zarr_realization_auto_chunkdim()} returns an integer vector
  containing the automatic chunk dimensions used by
  \code{\link{writeZarrArray}()} when its \code{chunkdim} argument is
  not specified.
  Note that the function is used \emph{internally} by
  \code{\link{writeZarrArray}()} and is not meant to be used
  directly by the user.

  \code{get_Zarr_realization_auto_version()} returns the automatic
  Zarr version used by \code{\link{writeZarrArray}()}
  (or \code{\link{writeZarrSparseMatrix}()}) when its \code{zarr_version}
  argument is not specified.
  Note that the function is used \emph{internally} by
  \code{\link{writeZarrArray}()} (or \code{\link{writeZarrSparseMatrix}()})
  and is not meant to be used directly by the user.

  \code{get_Zarr_realization_auto_group()} and
  \code{get_Zarr_realization_auto_layout()} return the automatic
  group and sparse layout used by \code{\link{writeZarrSparseMatrix}()}
  when its \code{group} or \code{sparse.layout} argument is not specified.
  Note that the functions are used \emph{internally} by
  \code{\link{writeZarrSparseMatrix}()} and are not meant to be used
  directly by the user.

  \code{get_Zarr_realization_dump_dir()} returns a single string containing
  the path to the "Zarr realization dump".

  \code{get_Zarr_realization_chunk_maxsize()} returns the "maximum chunk size"
  in bytes and before compression of the physical chunks to use by default
  when realizing an array-like object to disk in Zarr format.

  \code{get_Zarr_realization_chunk_maxlen(type)} returns the "maximum chunk
  length" (i.e. the maximum number of array elements) of the physical chunks
  to use by default when realizing an array-like object to disk in Zarr format.
  This is the "maximum chunk size" divided by the size of an array element of
  type \code{type} (which can be obtained with \code{get_type_size(type)}).

  \code{get_Zarr_realization_chunk_shape()} returns a single string describing
  the "chunk shape", that is, the shape of the physical chunks to use by
  default when realizing an array-like object to disk in Zarr format.

  All the \code{set_Zarr_realization_*()} functions return the previous
  value of the corresponding setting invisibly.
  For example \code{set_Zarr_realization_dump_dir()} returns an invisible
  string containing the previous path to the "Zarr realization dump". More
  precisely:
  \preformatted{    prev_dir <- set_Zarr_realization_dump_dir(dir)}
  is equivalent to:
  \preformatted{    prev_dir <- get_Zarr_realization_dump_dir()
    set_Zarr_realization_dump_dir(dir)}
}

\seealso{
  \itemize{
    \item \code{\link{writeZarrArray}} for writing an array-like object
          to disk in Zarr format.

    \item \code{\link{writeZarrSparseMatrix}} for writing a matrix-like
          object to disk in "Zarr sparse" format.

    \item \link{ZarrArray} objects.

    \item \code{\link[DelayedArray]{makeCappedVolumeBox}} in the
          \pkg{DelayedArray} package.
  }
}

\examples{
a <- array(101:160, dim=5:3)

get_Zarr_realization_dump_dir()  # default "Zarr realization dump"
A1 <- writeZarrArray(a)
path(A1)

## Take control of where writeZarrArray() should write Zarr datasets
## by default:
my_zarr_dump <- file.path(tempdir(), "my_zarr_dump")
set_Zarr_realization_dump_dir(my_zarr_dump)
A2 <- writeZarrArray(a)
path(A2)

m <- matrix(101:140, ncol=8)
M <- as(m, "ZarrArray")  # equivalent to writeZarrArray(m)
path(M)

## Reset "Zarr realization dump" to its default:
set_Zarr_realization_dump_dir()
}
\keyword{utilities}
