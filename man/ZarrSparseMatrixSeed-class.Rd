\name{ZarrSparseMatrixSeed-class}
\docType{class}

\alias{class:ZarrSparseMatrixSeed}
\alias{ZarrSparseMatrixSeed-class}
\alias{ZarrSparseMatrixSeed}

\alias{class:CSC_ZarrSparseMatrixSeed}
\alias{CSC_ZarrSparseMatrixSeed-class}
\alias{CSC_ZarrSparseMatrixSeed}

\alias{class:CSR_ZarrSparseMatrixSeed}
\alias{CSR_ZarrSparseMatrixSeed-class}
\alias{CSR_ZarrSparseMatrixSeed}

\alias{t.CSC_ZarrSparseMatrixSeed}
\alias{t,CSC_ZarrSparseMatrixSeed-method}
\alias{t.CSR_ZarrSparseMatrixSeed}
\alias{t,CSR_ZarrSparseMatrixSeed-method}

\alias{path,ZarrSparseMatrixSeed-method}
\alias{path<-,ZarrSparseMatrixSeed-method}
\alias{dim,ZarrSparseMatrixSeed-method}
\alias{dimnames,ZarrSparseMatrixSeed-method}
\alias{chunkdim,CSC_ZarrSparseMatrixSeed-method}
\alias{chunkdim,CSR_ZarrSparseMatrixSeed-method}
\alias{is_sparse,ZarrSparseMatrixSeed-method}
\alias{nzcount,ZarrSparseMatrixSeed-method}

\alias{extract_sparse_array,CSC_ZarrSparseMatrixSeed-method}
\alias{extract_sparse_array,CSR_ZarrSparseMatrixSeed-method}
\alias{extract_array,ZarrSparseMatrixSeed-method}

\alias{show,ZarrSparseMatrixSeed-method}

% OLD STUFF
\alias{extractNonzeroDataByCol}
\alias{extractNonzeroDataByCol,CSC_ZarrSparseMatrixSeed-method}
\alias{extractNonzeroDataByRow}
\alias{extractNonzeroDataByRow,CSR_ZarrSparseMatrixSeed-method}

\title{ZarrSparseMatrixSeed objects}

\description{
  ZarrSparseMatrixSeed is a low-level helper class for representing a
  pointer to a sparse matrix stored in an HDF5 file and compressed
  using the CSC or CSR layout.

  It is a virtual class with two concrete subclasses: CSC_ZarrSparseMatrixSeed
  for the \emph{Compressed Sparse Column} layout, and CSR_ZarrSparseMatrixSeed
  for the \emph{Compressed Sparse Row} layout.
  The former is used by 10x Genomics (e.g. "1.3 Million Brain Cell Dataset").
  \code{anndata-zarr} store can use one or the other layout to store a 
  sparse matrix.

  Note that an ZarrSparseMatrixSeed derivative is not intended to be used
  directly. Most end users will typically create and manipulate a
  higher-level \link{ZarrSparseMatrix} object instead.
  See \code{?\link{ZarrSparseMatrix}} for more information.
}

\usage{
## --- Constructor function ---

ZarrSparseMatrixSeed(filepath, group, subdata=NULL,
                   dim=NULL, sparse.layout=NULL)

## --- Accessors --------------

\S4method{path}{ZarrSparseMatrixSeed}(object)

\S4method{dim}{ZarrSparseMatrixSeed}(x)

\S4method{dimnames}{ZarrSparseMatrixSeed}(x)

\S4method{chunkdim}{CSC_ZarrSparseMatrixSeed}(x)
\S4method{chunkdim}{CSR_ZarrSparseMatrixSeed}(x)

## --- Data extraction --------

\S4method{extract_array}{ZarrSparseMatrixSeed}(x, index)

\S4method{extract_sparse_array}{CSC_ZarrSparseMatrixSeed}(x, index)
\S4method{extract_sparse_array}{CSR_ZarrSparseMatrixSeed}(x, index)

\S4method{extractNonzeroDataByCol}{CSC_ZarrSparseMatrixSeed}(x, j)
\S4method{extractNonzeroDataByRow}{CSR_ZarrSparseMatrixSeed}(x, i)

## --- Other methods ----------

\S4method{is_sparse}{ZarrSparseMatrixSeed}(x)

\S4method{nzcount}{ZarrSparseMatrixSeed}(x)
}

\arguments{
  \item{filepath, group}{
    See \code{?\link{ZarrSparseMatrix}} for a description of these arguments.
  }
  \item{subdata}{
    Experimental. Don't use!
  }
  \item{dim, sparse.layout}{
    The \code{ZarrSparseMatrixSeed()} constructor should be able to
    automatically detect the dimensions and layout of the sparse matrix
    stored in the HDF5 file, so the user shouldn't need to specify these
    arguments.

    See Details section below for some rare situations where the user might
    need to specify them.
  }
  \item{object, x}{
    An ZarrSparseMatrixSeed derivative.
  }
  \item{index}{
    See \code{?\link[S4Arrays]{extract_array}} in the \pkg{S4Arrays}
    package.
  }
  \item{j}{
    An integer vector containing valid column indices.
  }
  \item{i}{
    An integer vector containing valid row indices.
  }
}

\details{
  *** Layout in R vs physical layout ***

  The implementation of CSC_ZarrSparseMatrixSeed and
  CSR_ZarrSparseMatrixSeed objects follows the usual convention of
  transposing the matrix stored in the HDF5 file when loading it into R.
  This means that a CSC_ZarrSparseMatrixSeed object represents a
  sparse matrix stored physically in the CSR layout (Compressed Sparse Row)
  at the HDF5 level, and a CSR_ZarrSparseMatrixSeed object represents a
  sparse matrix stored physically in the CSC layout (Compressed Sparse Column)
  at the HDF5 level.

  *** Automatic detection of the dimensions and layout ***

  The \code{ZarrSparseMatrixSeed()} constructor should be able to
  automatically detect the dimensions and layout of the sparse matrix
  stored in the HDF5 file. However, in some rare situations, the user
  might want to bypass the detection mechanism, or they might be dealing
  with a sparse matrix stored in an HDF5 group that doesn't provide this
  information (e.g. the group only contains the \code{data}, \code{indices},
  and \code{indptr} components). In which case, they can supply the
  \code{dim} and \code{sparse.layout} arguments:
  \itemize{
    \item \code{dim} must be an integer vector of length 2.
    \item \code{sparse.layout} must be \code{"CSC"} or \code{"CSR"}.
  }
  Note that both values must describe the dimensions and layout of the
  R object that will be returned, that is, \emph{after} transposition
  from the physical layout used at the HDF5 level. Also be aware that the
  supplied values will take precedence over whatever the HDF5 file says,
  which means that bad things will happen if they don't reflect the actual
  dimensions and layout of the sparse matrix. Use these arguments only if
  you know what you are doing!

  *** ZarrSparseMatrixSeed object vs ZarrSparseMatrix object ***

  Note that ZarrSparseMatrixSeed derivatives support a very limited set
  of methods:
  \itemize{
    \item \code{path()}: Returns the path to the HDF5 file where the sparse
          matrix is located.
    \item \code{dim()}, \code{dimnames()}.
    \item \code{extract_array()}, \code{is_sparse()},
          \code{extract_sparse_array()}, \code{chunkdim()}:
          These generics are defined and documented in other packages e.g.
          in \pkg{S4Arrays} for \code{\link[S4Arrays]{extract_array}()}
          and \code{\link[S4Arrays]{is_sparse}()}, in \pkg{SparseArray}
          for \code{\link[SparseArray]{extract_sparse_array}()}, and in
          \pkg{DelayedArray} for \code{\link[DelayedArray]{chunkdim}()}.
    \item \code{nzcount()}: Returns the number of nonzero values in the
          object.
    \item \code{extractNonzeroDataByCol()}: Works on CSC_ZarrSparseMatrixSeed
          objects only. Returns a \link[IRanges]{NumericList} or
          \link[IRanges]{IntegerList} object \emph{parallel} to \code{j},
          that is, with one list element per column index in \code{j}.
          The row indices of the values are not returned. Furthermore, the
          values within a given list element can be returned in **any order**.
          In particular, do NOT assume that they are ordered by ascending
          row index.
    \item \code{extractNonzeroDataByRow()}: Works on CSR_ZarrSparseMatrixSeed
          objects only. Returns a \link[IRanges]{NumericList} or
          \link[IRanges]{IntegerList} object \emph{parallel} to \code{i},
          that is, with one list element per row index in \code{i}.
          The column indices of the values are not returned. Furthermore, the
          values within a given list element can be returned in **any order**.
          In particular, do NOT assume that they are ordered by ascending
          column index.
  }
  In order to have access to the full set of operations that
  are available for \link[DelayedArray]{DelayedMatrix} objects,
  an ZarrSparseMatrixSeed derivative would first need to be wrapped in
  a \link[DelayedArray]{DelayedMatrix} object, typically by calling
  the \code{\link[DelayedArray]{DelayedArray}()} constructor on it.
}

\value{
  \code{ZarrSparseMatrixSeed()} returns an ZarrSparseMatrixSeed derivative
  (CSC_ZarrSparseMatrixSeed or CSR_ZarrSparseMatrixSeed object).
}

\references{
  \url{https://en.wikipedia.org/wiki/Sparse_matrix} for a description
  of the CSR/CSC/Yale format (section "Compressed sparse row (CSR, CRS
  or Yale format)").
}

\seealso{
  \itemize{
    \item \link{ZarrSparseMatrix} objects.
  }
}

\examples{
showClass("ZarrSparseMatrixSeed")
}
\keyword{classes}
\keyword{methods}
