\name{ZarrSparseMatrix-class}
\docType{class}

\alias{class:ZarrSparseMatrix}
\alias{ZarrSparseMatrix-class}
\alias{ZarrSparseMatrix}

\alias{DelayedArray,ZarrSparseMatrixSeed-method}

\alias{nzcount,ZarrSparseMatrix-method}

\title{HDF5 sparse matrices as DelayedMatrix objects}

\description{
  The ZarrSparseMatrix class is a \link[DelayedArray]{DelayedMatrix} subclass
  for representing and operating on a Zarr-based sparse matrix stored in
  CSR/CSC/Yale format.

  All the operations available for \link[DelayedArray]{DelayedMatrix}
  objects work on ZarrSparseMatrix objects.
}

\usage{
## Constructor function:
ZarrSparseMatrix(zarr_store, group)
}

\arguments{
  \item{zarr_store}{
    The path (as a single string) to the Zarr store where the sparse matrix
    is located.
  }
  \item{group}{
    The name of the group node in the Zarr store where the sparse matrix
    is located.
  }
}

\value{
  A ZarrSparseMatrix object.
}

\seealso{
  \itemize{
    \item \link{ZarrArray} objects for representing conventional (a.k.a.
          dense) Zarr datasets as \link[DelayedArray]{DelayedArray} objects.

    \item \link{ZarrADMatrix} objects for representing a matrix from an
          AnnData-style Zarr store as a \link[DelayedArray]{DelayedMatrix}
          object.

    \item \link[DelayedArray]{DelayedMatrix} objects in the \pkg{DelayedArray}
          package.

    \item The \link{ZarrSparseMatrixSeed} helper class.

    \item \link[SparseArray]{SparseArray} objects in the \pkg{SparseArray}
          package.
  }
}

\examples{
## ---------------------------------------------------------------------
## BASIC EXAMPLE
## ---------------------------------------------------------------------

## The anndataR package contains 3 AnnData-style ondisk data structures
## that contain the same data stored in different formats:
##   1. example.h5ad:        HDF5-based AnnData-style data structure;
##   2. example_v2.zarr.zip: Zarr-v2-based AnnData-style data structure;
##   3. example_v3.zarr.zip: Zarr-v3-based AnnData-style data structure.
##
## In each data structure the following groups contain sparse matrices:
##   group                      dim  type
##   /X                    100 x 50  double
##   /layers/counts        100 x 50  double
##   /layers/csc_counts    100 x 50  double
##   /obsp/connectivities   50 x 50  double
##   /obsp/distances        50 x 50  double
##   /uns/Sparse1D           6 x  1  integer

library(anndataR)

## Unzip example_v3.zarr.zip:
zad_basename <- "example_v3.zarr"  # zad: Zarr-based AnnData
zad_zip <- paste0(zad_basename, ".zip")
zad_zip_path <- system.file(package="anndataR", "extdata", zad_zip)
exdir <- tempdir()
unzip(zad_zip_path, exdir=exdir)
zad_store <- file.path(exdir, zad_basename)

## Represent /obsp/connectivities group as ZarrSparseMatrix object:
ZSM <- ZarrSparseMatrix(zad_store, "/obsp/connectivities")
ZSM

class(ZSM)  # ZarrSparseMatrix
is(ZSM, "DelayedMatrix")  # TRUE

seed(ZSM)
class(seed(ZSM))  # CSC_H5SparseMatrixSeed

dim(ZSM)
path(ZSM)
group(ZSM)
is_sparse(ZSM)  # TRUE

## Use coercion to load the full dataset into memory:
as.matrix(ZSM)          # as ordinary array (usually not recommended)
as(ZSM, "dgCMatrix")    # as dgCMatrix
as(ZSM, "SparseArray")  # as SparseArray object (most efficient)
SparseArray(ZSM)        # equivalent to 'as(ZSM, "SparseArray")'

## ---------------------------------------------------------------------
## ZarrSparseMatrix objects vs H5SparseMatrix objects
## ---------------------------------------------------------------------

## ZarrSparseMatrix and H5SparseMatrix objects are equivalent in terms
## of functionality. As a sanity check, we're going to compare the
## ZarrSparseMatrix objects obtained from example_v3.zarr with the
## corresponding H5SparseMatrix objects obtained from example.h5ad:

library(HDF5Array)
h5ad_path <- system.file(package="anndataR", "extdata", "example.h5ad")

groups <- c("/X", "/layers/counts", "/layers/csc_counts",
            "/obsp/connectivities", "/obsp/distances")
for (group in groups) {
    ZSM <- ZarrSparseMatrix(zad_store, group)
    HSM <- H5SparseMatrix(h5ad_path, group)
    stopifnot(identical(SparseArray(ZSM), SparseArray(HSM)))
}
}
\keyword{classes}
\keyword{methods}
