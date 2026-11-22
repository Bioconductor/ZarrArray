\name{writeZarrSparseMatrix}

\alias{class:ZarrSparseMatrixRealizationSink}
\alias{ZarrSparseMatrixRealizationSink-class}
\alias{ZarrSparseMatrixRealizationSink}

\alias{dimnames,ZarrSparseMatrixRealizationSink-method}
\alias{type,ZarrSparseMatrixRealizationSink-method}
\alias{chunkdim,ZarrSparseMatrixRealizationSink-method}
\alias{write_block,ZarrSparseMatrixRealizationSink-method}
\alias{close,ZarrSparseMatrixRealizationSink-method}

\alias{coerce,ZarrSparseMatrixRealizationSink,ZarrSparseMatrixSeed-method}
\alias{coerce,ZarrSparseMatrixRealizationSink,ZarrSparseMatrix-method}
\alias{coerce,ZarrSparseMatrixRealizationSink,DelayedArray-method}

\alias{writeZarrSparseMatrix}

\alias{coerce,ANY,ZarrSparseMatrix-method}
\alias{coerce,DelayedArray,ZarrSparseMatrix-method}
\alias{coerce,DelayedMatrix,ZarrSparseMatrix-method}

\title{Write a matrix-like object as a Zarr-based sparse matrix}

\description{
  Realize a matrix-like object (typically sparse) as a \link{ZarrSparseMatrix}
  object.

  The \code{writeZarrSparseMatrix()} function is the Zarr equivalent
  of \code{\link[HDF5]{writeTENxMatrix}()} from the \pkg{HDF5Array} package,

  IMPORTANT NOTE: Only use \code{writeZarrSparseMatrix()} if the
  matrix-like object to write is sparse, that is, if most of its elements
  are zero. Using it on dense data is very inefficient!
  If your matrix is dense, use \code{\link{writeZarrArray}()} instead.
}

\usage{
writeZarrSparseMatrix(x, zarr_store=NULL, group="/",
                         sparse.layout="tenx", verbose=NA)
}

\arguments{
  \item{x}{
    The matrix-like object to write to disk in "Zarr sparse" format.

    The object to write should typically be sparse, that is, most of its
    elements should be zero.

    If \code{x} is a \link[DelayedArray]{DelayedMatrix} object that carries
    delayed operations, then \code{writeZarrSparseMatrix()} will \emph{realize}
    them \emph{on the fly} and \emph{block by block} right before writing
    each block of data to disk.

    See "On-disk Zarr realization of a DelayedArray object" section in
    the \code{\link{writeZarrArray}} man page for more information.
  }
  \item{zarr_store}{
    \code{NULL} or the path (as a single string) to the (new or existing)
    directory where to write the matrix data in "Zarr sparse" format.

    If \code{NULL}, then \code{writeZarrSparseMatrix()} will obtain this path
    by calling \code{\link{get_writeZarrArray_auto_path}()} internally.
    See \code{?\link{writeZarrArray_auto_args}} for more information.
  }
  \item{group}{
    The name of the group node in the Zarr store where to write the
    matrix data in "Zarr sparse" format.
  }
  \item{sparse.layout}{
    The sparse layout to use. Only the \code{"tenx"} layout is supported
    at the moment.
  }
  \item{verbose}{
    Whether block processing progress should be displayed or not.
    If set to \code{NA} (the default), verbosity is controlled
    by \code{DelayedArray:::get_verbose_block_processing()}.
    Setting \code{verbose} to \code{TRUE} or \code{FALSE} overrides this.
  }
}

\details{
  \code{writeZarrSparseMatrix()} leverages lower-level functionality
  implemented in the \pkg{Rarr} package like \code{Rarr::write_zarr_group()},
  \code{Rarr::create_empty_zarr_array()}, and \code{Rarr::update_zarr_array()}.

  Please note that, depending on the size of the data to write to disk
  and the performance of the disk, \code{writeZarrSparseMatrix()} can take
  a long time to complete. Use \code{verbose=TRUE} to see its progress.
}

\value{
  A \link{ZarrSparseMatrix} object that points to the newly written
  on disk Zarr-based sparse matrix.
}

\seealso{
  \itemize{
    \item \link{ZarrSparseMatrix} objects.

    \item \link{writeZarrArray_auto_args} to control
          \code{writeZarrSparseMatrix}'s \emph{automatic argument values}
          like \code{zarr_store}.

    \item \link{writeZarrArray} to realize a matrix-like or array-like
          object (typically dense) as a \link{ZarrArray} object.
  }
}

\examples{
m0 <- matrix(0L, nrow=25, ncol=12,
             dimnames=list(letters[1:25], LETTERS[1:12]))
m0[cbind(2:24, c(12:1, 2:12))] <- 100L + sample(55L, 23, replace=TRUE)

zarr_store <- tempfile(fileext=".zarr")
M0 <- writeZarrSparseMatrix(m0, zarr_store)
M0

sparsity(M0)

path(M0)  # same as 'zarr_store'
}
\keyword{methods}
