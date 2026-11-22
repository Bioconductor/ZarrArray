\name{ZarrSparseMatrix-class}
\docType{class}

\alias{class:ZarrSparseMatrix}
\alias{ZarrSparseMatrix-class}
\alias{ZarrSparseMatrix}

\alias{DelayedArray,ZarrSparseMatrixSeed-method}

\alias{nzcount,ZarrSparseMatrix-method}

\title{Zarr-based sparse matrices as DelayedMatrix objects}

\description{
  A ZarrSparseMatrix object is a \link[DelayedArray]{DelayedMatrix}
  derivative that represents a Zarr-based sparse matrix. The object
  allows easy and intuitive matrix-like manipulation of a sparse matrix
  stored on disk in "Zarr sparse" format.

  Note that the "Zarr sparse" format follows the traditional CSR/CSC/Yale
  convention of using several Zarr datasets grouped together inside a Zarr
  group node to organize the sparse data on disk.

  All the operations available for \link[DelayedArray]{DelayedMatrix}
  objects work on ZarrSparseMatrix objects.
}

\usage{
## Constructor function:
ZarrSparseMatrix(zarr_store, group="/")
}

\arguments{
  \item{zarr_store}{
    The path (as a single string) to the "Zarr store" (i.e. the top-level
    Zarr directory) under which the sparse matrix is located.
  }
  \item{group}{
    The name of the group node in the Zarr store where the sparse matrix
    is located.
  }
}

\details{
  The implementation of the ZarrSparseMatrix class leverages lower-level
  functionality implemented in the \pkg{Rarr} package like
  \code{Rarr::read_zarr_array()} and \code{Rarr::read_zarr_attributes()}.
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

## The anndataR package contains 3 AnnData-style files that contain the
## same data stored in 3 different formats:
library(anndataR)
anndataR_extdata <- system.file(package="anndataR", "extdata")
list.files(anndataR_extdata)

## The 3 files are:
##   1. example.h5ad:        HDF5-based AnnData-style file;
##   2. example_v2.zarr.zip: Zarr-v2-based AnnData-style file;
##   3. example_v3.zarr.zip: Zarr-v3-based AnnData-style file.
##
## Each file contains a collection of datasets organized in a complex
## hierarchy of groups and subgroups that follow the AnnData convention.
## The following groups in each of these files represent a sparse matrix
## stored in CSR/CSC/Yale format:
##   group                      dim  type
##   /X                    100 x 50  double
##   /layers/counts        100 x 50  double
##   /layers/csc_counts    100 x 50  double
##   /obsp/connectivities   50 x 50  double
##   /obsp/distances        50 x 50  double
##   /uns/Sparse1D           6 x  1  integer
## Each of these groups contains a small standardized set of datasets
## that achieves efficient representation of the sparse data, and can
## therefore be represented as a ZarrSparseMatrix object in R.

## Unzip example_v3.zarr.zip:
zad_basename <- "example_v3.zarr"  # zad: Zarr-based AnnData
zad_zip <- paste0(zad_basename, ".zip")
zad_zip_path <- file.path(anndataR_extdata, zad_zip)
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
