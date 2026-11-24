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
writeZarrSparseMatrix(x, zarr_store="auto", group="auto",
                         sparse.layout="auto",
                         zarr_version="auto", verbose=NA)
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
    \code{"auto"} or the path (as a single string) to the (new or existing)
    directory where to write the matrix data in "Zarr sparse" format.

    If \code{"auto"}, then \code{writeZarrSparseMatrix()} will obtain
    this path by calling \code{\link{get_Zarr_realization_auto_path}()}
    internally.
    See \code{?\link{Zarr_realization_settings}} for more information.
  }
  \item{group}{
    \code{"auto"} or the name of the group node in the Zarr store where
    to write the matrix data in "Zarr sparse" format.

    If \code{"auto"}, then \code{writeZarrSparseMatrix()} will obtain
    the group node by calling \code{\link{get_Zarr_realization_auto_group}()}
    internally. See \code{?\link{Zarr_realization_settings}} for more
    information.
  }
  \item{sparse.layout}{
    \code{"auto"} or the sparse layout to use. Only the \code{"tenx"} layout
    is supported at the moment.

    If \code{"auto"}, then \code{writeZarrSparseMatrix()} will obtain the
    layout to use by calling \code{\link{get_Zarr_realization_auto_layout}()}
    internally. See \code{?\link{Zarr_realization_settings}} for more
    information.
  }
  \item{zarr_version}{
    \code{"auto"} or the version of the Zarr specification (i.e. 2 or 3) to
    use for writing the data to disk.

    If \code{"auto"}, then \code{writeZarrSparseMatrix()} will obtain the
    Zarr version by calling \code{\link{get_Zarr_realization_auto_version}()}
    internally. See \code{?\link{Zarr_realization_settings}} for more
    information.
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

    \item \link{Zarr_realization_settings} to control
          \code{writeZarrSparseMatrix}'s automatic \code{zarr_store},
          \code{group}, \code{sparse.layout}, and \code{zarr_version}
          values.

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
