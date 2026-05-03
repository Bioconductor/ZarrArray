\name{ZarrADMatrix-class}
\docType{class}

\alias{class:ZarrADMatrix}
\alias{ZarrADMatrix-class}
\alias{ZarrADMatrix}

\alias{DelayedArray,ZarrADMatrixSeed-method}

\alias{nzcount,ZarrADMatrix-method}
\alias{extractNonzeroDataByCol,ZarrADMatrix-method}
\alias{extractNonzeroDataByRow,ZarrADMatrix-method}

\title{anndata-zarr central matrices (or matrices in the /layers group)
       as DelayedMatrix objects}

\description{
  \code{anndata-zarr} stores are Zarr stores used for on-disk representation
  of AnnData Python objects. At the very minimum, they contain a central
  data matrix, named \code{X}, of shape #observations x #variables, and
  possibly additional data matrices (stored in the Zarr group \code{/layers})
  that share the shape and dimnames of \code{X}.
  See \url{https://anndata.readthedocs.io/} for more information.

  The ZarrADMatrix class is a \link[DelayedArray]{DelayedMatrix} subclass
  for representing and operating on the central matrix of an \code{anndata-zarr}
  store, or any matrix in its \code{/layers} group.

  All the operations available for \link[DelayedArray]{DelayedMatrix}
  objects work on ZarrADMatrix objects.
}

\usage{
## Constructor function:
ZarrADMatrix(filepath, layer=NULL)
}

\arguments{
  \item{filepath}{
    The path (as a single string) to the \code{anndata-zarr} store.
  }
  \item{layer}{
    \code{NULL} (the default) or the name of a matrix in the \code{/layers}
    group. By default (i.e. when \code{layer} is not specified)
    \code{ZarrADMatrix()} returns the central matrix (\code{X}).
  }
}

\value{
  \code{ZarrADMatrix()} returns an ZarrADMatrix object of shape #variables x
  #observations. Note that in Python and Zarr the shape of this matrix is
  considered to be #observations x #variables, but in R it is transposed.
  This follows the widely adopted convention of transposing Zarr matrices
  when they get loaded into R.
}

\references{
  \url{https://anndata.readthedocs.io/} for AnnData Python objects
  and the \code{anndata-zarr} format.
}

\seealso{
  \itemize{
    \item \link{ZarrArray} objects for representing conventional (a.k.a.
          dense) Zarr datasets as \link[DelayedArray]{DelayedArray} objects.

    \item \link{ZarrSparseMatrix} objects for representing Zarr sparse matrices
          as \link[DelayedArray]{DelayedMatrix} objects.

    \item \link[DelayedArray]{DelayedMatrix} objects in the \pkg{DelayedArray}
          package.

    \item The \link{ZarrADMatrixSeed} helper class.

    \item \code{\link[anndataR]{read_zarr}} and
          \code{\link[anndataR]{write_zarr}} in
          the \pkg{anndataR} package for
          importing/exporting an \code{anndata-zarr} store as/from a
          \link[SingleCellExperiment]{SingleCellExperiment} object.

    \item \link[SparseArray]{SparseArray} objects in the \pkg{SparseArray}
          package.
  }
}

\examples{
library(anndataR)
zarr_zip <- system.file("extdata", 
                        paste0("example_v2.zarr.zip"), 
                        package = "anndataR")
td <- tempdir(check = TRUE)
unzip(zarr_zip, exdir = td)
zarr_store <- file.path(td, paste0("example_v2.zarr"))

X <- ZarrADMatrix(zarr_store)
X

class(X)  # ZarrADMatrix
is(X, "DelayedMatrix")  # TRUE

class(seed(X))  # Dense_ZarrADMatrixSeed

dim(X)
path(X)
is_sparse(X)  # FALSE

## Use coercion to load the full dataset into memory:
as.matrix(X)          # as ordinary array (usually not recommended)

\dontrun{
  ## Works only if ZarrADMatrix object is sparse!
  as(X, "dgCMatrix")    # as dgCMatrix
  as(X, "SparseArray")  # as SparseArray object (most efficient)
  SparseArray(X)        # equivalent to 'as(X, "SparseArray")'
}
}
\keyword{classes}
\keyword{methods}
