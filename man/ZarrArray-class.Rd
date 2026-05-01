\name{ZarrArray-class}
\docType{class}

\alias{class:ZarrArray}
\alias{ZarrArray-class}
\alias{ZarrArray}

\alias{DelayedArray,ZarrArraySeed-method}

\alias{class:ZarrMatrix}
\alias{ZarrMatrix-class}
\alias{ZarrMatrix}

\alias{matrixClass,ZarrArray-method}
\alias{coerce,ZarrArray,ZarrMatrix-method}
\alias{coerce,ZarrMatrix,ZarrArray-method}

\title{Zarr datasets as DelayedArray objects}

\description{
  The ZarrArray class is a \link[DelayedArray]{DelayedArray} extension
  for representing and operating on a Zarr dataset.

  All the operations available for \link[DelayedArray]{DelayedArray}
  objects work on ZarrArray objects.
}

\usage{
## Constructor function:
ZarrArray(zarr_path, s3_client=NULL)
}

\arguments{
  \item{zarr_path}{
    The path (as a single string) to the Zarr dataset.
  }
  \item{s3_client}{
    Object created by \code{paws.storage::\link[paws.storage]{s3}()}.
    Only required for a Zarr dataset on a non-public S3 bucket. Leave
    as \code{NULL} for a Zarr dataset on local storage or on a public
    S3 bucket.
  }
}

\value{
  A ZarrArray (or ZarrMatrix) object. (Note that ZarrMatrix extends
  ZarrArray.)
}

\seealso{
  \itemize{
    \item \link[DelayedArray]{DelayedArray} objects in the \pkg{DelayedArray}
          package.

    \item \code{\link[paws.storage]{s3}} in the \pkg{paws.storage} package
          for how to create a client for the S3 service.

    \item \code{\link{writeZarrArray}} for writing an array-like object
          to disk in Zarr format.

    \item The \link{ZarrArraySeed} helper class.
  }
}

\examples{
zarr_path <- system.file(package="Rarr", "extdata",
                         "zarr_examples", "column-first", "int32.zarr")
A <- ZarrArray(zarr_path)
A  # 3D ZarrArray object

path(A)
dim(A)
type(A)
chunkdim(A)

aperm(A)  # multidimensional transposition
chunkdim(aperm(A))

A[ , , 1]
log1p(t(A[ , , 1]))
rowSums(log1p(t(A[ , , 1])))

## Sanity check:
stopifnot(
  identical(dim(aperm(A)), rev(dim(A))),
  identical(chunkdim(aperm(A)), rev(chunkdim(A))),
  identical(rowSums(log1p(t(A[ , , 1]))),
            rowSums(log1p(t(as.array(A)[ , , 1]))))
)
}
\keyword{classes}
\keyword{methods}
