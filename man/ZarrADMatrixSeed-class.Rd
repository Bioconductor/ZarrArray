\name{ZarrADMatrixSeed-class}
\docType{class}

\alias{class:ZarrADMatrixSeed}
\alias{ZarrADMatrixSeed-class}
\alias{ZarrADMatrixSeed}

\alias{class:Dense_ZarrADMatrixSeed}
\alias{Dense_ZarrADMatrixSeed-class}
\alias{Dense_ZarrADMatrixSeed}

\alias{class:CSC_ZarrADMatrixSeed}
\alias{CSC_ZarrADMatrixSeed-class}
\alias{CSC_ZarrADMatrixSeed}

\alias{class:CSR_ZarrADMatrixSeed}
\alias{CSR_ZarrADMatrixSeed-class}
\alias{CSR_ZarrADMatrixSeed}

\alias{dimnames,Dense_ZarrADMatrixSeed-method}

\alias{t.CSC_ZarrADMatrixSeed}
\alias{t,CSC_ZarrADMatrixSeed-method}
\alias{t.CSR_ZarrADMatrixSeed}
\alias{t,CSR_ZarrADMatrixSeed-method}

\title{ZarrADMatrixSeed objects}

\description{
  ZarrADMatrixSeed is a low-level helper class used to represent a pointer
  to the central matrix stored of an \code{anndata-zarr} store, or to one of the
  matrices in the \code{/layers} group.

  It is a virtual class with three concrete subclasses: Dense_ZarrADMatrixSeed,
  CSC_ZarrADMatrixSeed, and CSR_ZarrADMatrixSeed:
  \itemize{
    \item The Dense_ZarrADMatrixSeed class is used when the matrix is stored
          as a conventional Zarr dataset in the \code{anndata-zarr} store. It is
          a direct entension of the \link{ZarrArraySeed} class.

    \item The CSC_ZarrADMatrixSeed or CSR_ZarrADMatrixSeed classes is used
          when the matrix is stored in the \emph{Compressed Sparse Column}
          or \emph{Compressed Sparse Row} format in the \code{anndata-zarr} 
          store. CSC_ZarrADMatrixSeed is a direct entension of
          \link{CSC_ZarrSparseMatrixSeed}, and CSR_ZarrADMatrixSeed a
          direct entension of \link{CSR_ZarrSparseMatrixSeed}.
  }

  Note that an ZarrADMatrixSeed derivative is not intended to be used directly.
  Most end users will typically create and manipulate a higher-level
  \link{ZarrADMatrix} object instead. See \code{?\link{ZarrADMatrix}} for
  more information.
}

\usage{
## Constructor function:
ZarrADMatrixSeed(zarr_store, layer=NULL)
}

\arguments{
  \item{zarr_store, layer}{
    See \code{?\link{ZarrADMatrix}} for a description of these arguments.
  }
}

\details{
  Dense_ZarrADMatrixSeed objects support the same limited set of methods as
  \link{ZarrArraySeed} objects, and CSC_ZarrADMatrixSeed and CSR_ZarrADMatrixSeed
  objects support the same limited set of methods as \link{ZarrSparseMatrixSeed}
  objects.
  See \code{?\link{ZarrArraySeed}} and \code{?\link{ZarrSparseMatrixSeed}}
  for the details.
}

\value{
  \code{ZarrADMatrixSeed()} returns an ZarrADMatrixSeed derivative
  (Dense_ZarrADMatrixSeed or CSC_ZarrADMatrixSeed or CSR_ZarrADMatrixSeed)
  of shape #variables x #observations.
}

\section{ZarrADMatrixSeed vs ZarrADMatrix objects}{
  In order to have access to the full set of operations that are available
  for \link[DelayedArray]{DelayedMatrix} objects, an ZarrADMatrixSeed
  derivative first needs to be wrapped in a \link[DelayedArray]{DelayedMatrix}
  object, typically by calling the \code{\link[DelayedArray]{DelayedArray}()}
  constructor on it.

  This is what the \code{\link{ZarrADMatrix}()} constructor function does.

  Note that the result of this wrapping is an \link{ZarrADMatrix} object,
  which is just an ZarrADMatrixSeed derivative wrapped in a
  \link[DelayedArray]{DelayedMatrix} object.
}

\references{
  \url{https://anndata.readthedocs.io/} for AnnData Python objects
  and the \code{ZarrAD} format.
}

\seealso{
  \itemize{
    \item \link{ZarrADMatrix} objects.

    \item \link{ZarrArraySeed} and \link{ZarrSparseMatrixSeed} objects.

    \item \code{\link[zellkonverter]{readZarrAD}} and
          \code{\link[zellkonverter]{writeZarrAD}} in
          the \pkg{zellkonverter} package for
          importing/exporting an \code{anndata-zarr} store as/from a
          \link[SingleCellExperiment]{SingleCellExperiment} object.
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

seed <- ZarrADMatrix(zarr_store)
seed
path(seed)
dim(seed)
is_sparse(seed)

DelayedArray(seed)
stopifnot(class(DelayedArray(seed)) == "ZarrADMatrix")
}
\keyword{classes}
\keyword{methods}
