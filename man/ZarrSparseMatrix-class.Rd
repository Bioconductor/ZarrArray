\name{ZarrSparseMatrix-class}
\docType{class}

\alias{class:ZarrSparseMatrix}
\alias{ZarrSparseMatrix-class}
\alias{ZarrSparseMatrix}

\alias{DelayedArray,ZarrSparseMatrixSeed-method}

\alias{nzcount,ZarrSparseMatrix-method}
\alias{extractNonzeroDataByCol,ZarrSparseMatrix-method}
\alias{extractNonzeroDataByRow,ZarrSparseMatrix-method}

\title{Zarr sparse matrices as DelayedMatrix objects}

\description{
  The ZarrSparseMatrix class is a \link[DelayedArray]{DelayedMatrix} subclass
  for representing and operating on an Zarr sparse matrix stored in
  CSR/CSC/Yale format.

  All the operations available for \link[DelayedArray]{DelayedMatrix}
  objects work on ZarrSparseMatrix objects.
}

\usage{
## Constructor function:
ZarrSparseMatrix(filepath, group)
}

\arguments{
  \item{filepath}{
    The path (as a single string) to the anndata-zarr store (\code{.zarr} where 
    the sparse matrix is located.
  }
  \item{group}{
    The name of the group in the Zarr store where the sparse matrix is stored.
  }
}

\value{
  An ZarrSparseMatrix object.
}

\seealso{
  \itemize{
    \item \link{ZarrArray} objects for representing conventional (a.k.a.
          dense) Zarr datasets as \link[DelayedArray]{DelayedArray} objects.

    \item \link{ZarrADMatrix} objects for representing anndata-zarr central
          matrices (or matrices in the \code{/layers} group)
          as \link[DelayedArray]{DelayedMatrix} objects.

    \item \link[DelayedArray]{DelayedMatrix} objects in the \pkg{DelayedArray}
          package.

    \item The \link{ZarrSparseMatrixSeed} helper class.

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

M <- ZarrSparseMatrix(zarr_store, "/obsp/connectivities")
M

class(M)  # ZarrSparseMatrix
is(M, "DelayedMatrix")  # TRUE

seed(M)
class(seed(M))  # CSC_ZarrSparseMatrixSeed

dim(M)
path(M)
is_sparse(M)  # TRUE

## Use coercion to load the full dataset into memory:
as.matrix(M)          # as ordinary array (usually not recommended)
as(M, "dgCMatrix")    # as dgCMatrix
as(M, "SparseArray")  # as SparseArray object (most efficient)
SparseArray(M)        # equivalent to 'as(M, "SparseArray")'
}
\keyword{classes}
\keyword{methods}
