\name{writeZarrArray}

\alias{class:ZarrRealizationSink}
\alias{ZarrRealizationSink-class}
\alias{ZarrRealizationSink}

\alias{type,ZarrRealizationSink-method}
\alias{chunkdim,ZarrRealizationSink-method}
\alias{write_block,ZarrRealizationSink-method}

\alias{coerce,ZarrRealizationSink,ZarrArraySeed-method}
\alias{coerce,ZarrRealizationSink,ZarrArray-method}
\alias{coerce,ZarrRealizationSink,DelayedArray-method}

\alias{writeZarrArray}

\alias{coerce,ANY,ZarrArray-method}
\alias{coerce,DelayedArray,ZarrArray-method}
\alias{coerce,DelayedMatrix,ZarrMatrix-method}

\title{Write an array-like object to disk in Zarr format}

\description{
  A function for writing an array-like object to disk in Zarr format.
}

\usage{
writeZarrArray(x, zarr_path=NULL, chunkdim=NULL,
               nchar=NULL, zarr_version=3, verbose=NA)
}

\arguments{
  \item{x}{
    The array-like object to write to disk in Zarr format.

    If \code{x} is a \link{DelayedArray} object or derivative, then
    \code{writeZarrArray()} \emph{realizes} it on disk, that is, all
    the delayed operations carried by the object are executed on the
    fly while the object is written to disk.
    See "On-disk realization of a DelayedArray object as a Zarr dataset"
    section below for more information.
  }
  \item{zarr_path}{
    \code{NULL} or the path (as a single string) to the directory where
    to write the data in Zarr format.
    If \code{NULL}, then \code{writeZarrArray()} will obtain this path
    by calling \code{\link{get_writeZarrArray_auto_path}()} internally.
    See \code{?\link{writeZarrArray_auto_args}} for more information.
  }
  \item{chunkdim}{
    The dimensions of the physical chunks to use when writing the data
    to disk. See \code{?\link{writeZarrArray_auto_args}} for how this is
    automatically determined when \code{chunkdim} is set to \code{NULL}.
  }
  \item{nchar}{
    When \code{x} is of type \code{character}, this argument
    specifies the maximum length of the stored strings. By default
    \code{writeZarrArray()} will use \code{max(nchar(x)) + 1}.
    You can override this by supplying your own value as a single
    positive integer but only if you know what you are doing.
  }
  \item{zarr_version}{
    The version of the Zarr specification to use. Currently,
    either \code{2} or \code{3}. The default is \code{3}.
  }
  \item{verbose}{
    Whether block processing progress should be displayed or not.
    If set to \code{NA} (the default), verbosity is controlled
    by \code{DelayedArray:::get_verbose_block_processing()}.
    Setting \code{verbose} to \code{TRUE} or \code{FALSE} overrides this.
  }
}

\details{
  \code{writeZarrArray()} leverages lower-level functionality implemented
  in the \pkg{Rarr} package like \code{create_empty_zarr_array()} and
  \code{update_zarr_array()}.

  Please note that, depending on the size of the data to write to disk
  and the performance of the disk, \code{writeZarrArray()} can take a
  long time to complete. Use \code{verbose=TRUE} to see its progress.
}

\value{
  A \link{ZarrArray} object that points to the newly written Zarr dataset
  on disk.

  IMPORTANT NOTE: The dimnames on \code{x} are NOT propagated to the
  returned \link{ZarrArray} object at the moment! This is a temporary
  situation that will be addressed in future versions of the
  \pkg{ZarrArray} package.
}

\section{On-disk realization of a DelayedArray object as a Zarr dataset}{
  When passed a \link{DelayedArray} object, \code{writeZarrArray()}
  \emph{realizes} it on disk, that is, all the delayed operations carried
  by the object are executed on the fly while the object is written to disk.
  This uses a block-processing strategy so that the full object is not
  realized at once in memory. Instead the object is processed block by block
  i.e. the blocks are realized in memory and written to disk one at a time.

  In other words, \code{writeZarrArray(x, ...)} is semantically equivalent
  to \code{writeZarrArray(as.array(x), ...)}, except that \code{as.array(x)}
  is not called because this would realize the full object at once in memory.

  See \code{?\link{DelayedArray}} for general information about
  \link{DelayedArray} objects.
}

\seealso{
  \itemize{
    \item \link{writeZarrArray_auto_args} to control \code{writeZarrArray}'s
    \emph{automatic argument values} like \code{zarr_path} and \code{chunkdim}.

    \item \link{ZarrArray} objects.
  }
}

\examples{
## ---------------------------------------------------------------------
## Write an ordinary matrix to disk in Zarr format
## ---------------------------------------------------------------------
m0 <- matrix(runif(180, min=-1), ncol=9)

path <- tempfile(fileext=".zarr")
M1 <- writeZarrArray(m0, path)
M1  # ZarrMatrix object

path(M1)
chunkdim(M1)

as(m0, "ZarrArray")  # equivalent to writeZarrArray(m0)

## ---------------------------------------------------------------------
## Transform a Zarr dataset and write it back in Zarr format
## ---------------------------------------------------------------------
M2 <- log(t(M1) + 1)  # DelayedMatrix object

M3 <- writeZarrArray(M2)
M3  # ZarrMatrix object

as(M2, "ZarrArray")  # equivalent to writeZarrArray(M2)

## ---------------------------------------------------------------------
## Use writeZarrArray() to convert an HDF5 dataset to Zarr format
## ---------------------------------------------------------------------

## The HDF5Array package includes an HDF5 file with some toy HDF5
## datasets:
library(HDF5Array)
h5_path <- system.file(package="HDF5Array", "extdata", "toy.h5")
h5ls(h5_path)

## Let's convert the M1 dataset to Zarr:
M1 <- HDF5Array(h5_path, "M1")
zarr_path <- file.path(tempdir(), "M1.zarr")
writeZarrArray(M1, zarr_path)

## Note that writeZarrArray() uses a block-processing strategy so that
## the original HDF5 dataset is not loaded at once in memory. Instead
## the object is loaded block by block and the blocks are written to
## disk one at a time. In other words writeZarrArray() can operate with
## a limited amount of memory regardless of the size of the original
## dataset. This amount of memory depends on the size of the blocks which
## can be controlled with setAutoBlockSize(). See '?setAutoBlockSize' in
## the DelayedArray package for more information.
}
\keyword{methods}
