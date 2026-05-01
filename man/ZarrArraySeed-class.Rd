\name{ZarrArraySeed-class}
\docType{class}

\alias{class:ZarrArraySeed}
\alias{ZarrArraySeed-class}
\alias{ZarrArraySeed}

\alias{path,ZarrArraySeed-method}
\alias{dim,ZarrArraySeed-method}
\alias{type,ZarrArraySeed-method}
\alias{extract_array,ZarrArraySeed-method}
\alias{chunkdim,ZarrArraySeed-method}
\alias{show,ZarrArraySeed-method}

\title{ZarrArraySeed objects}

\description{
  ZarrArraySeed is a low-level helper class for representing a
  pointer to a Zarr dataset.

  Note that a ZarrArraySeed object is not intended to be used directly.
  Most end users will typically create and manipulate a higher-level
  \link{ZarrArray} object instead. See \code{?\link{ZarrArray}} for
  more information.
}

\usage{
## --- Constructor function ---

ZarrArraySeed(zarr_path, s3_client=NULL)

## --- Accessors --------------

\S4method{path}{ZarrArraySeed}(object)

\S4method{dim}{ZarrArraySeed}(x)

\S4method{type}{ZarrArraySeed}(x)

\S4method{chunkdim}{ZarrArraySeed}(x)

## --- Data extraction --------

\S4method{extract_array}{ZarrArraySeed}(x, index)
}

\arguments{
  \item{zarr_path, s3_client}{
    See \code{?\link{ZarrArray}} for a description of these arguments.
  }
  \item{object, x}{
    A ZarrArraySeed object.
  }
  \item{index}{
    See \code{?\link[S4Arrays]{extract_array}} in the \pkg{S4Arrays}
    package.
  }
}

\details{
  ZarrArraySeed objects only support a limited set of methods:
  \itemize{
    \item \code{path()}: Returns the path to the Zarr dataset.
          Note that the \code{\link[BiocGenerics]{path}()} generic
          is defined and documented in the \pkg{BiocGenerics} package.

    \item \code{dim()}, \code{type()}, \code{chunkdim()}. Note that
          the \code{\link[BiocGenerics]{type}()} generic is defined and
          documented in the \pkg{BiocGenerics} package, and the
          \code{\link[DelayedArray]{chunkdim}()} generic is defined and
          documented in the \pkg{DelayedArray} package.

    \item \code{extract_array()}, \code{as.array()}, \code{is_sparse()}:
          Note that these generics are defined and documented
          in other packages e.g. in \pkg{S4Arrays} for
          \code{\link[S4Arrays]{extract_array}()} and
          \code{\link[S4Arrays]{is_sparse}()}, and in \pkg{base}
          for \code{\link[base]{as.array}()}.
  }

  In order to access the full set of operations that are available
  for \link[DelayedArray]{DelayedArray} objects, one needs to wrap
  a ZarrArraySeed object in a \link[DelayedArray]{DelayedArray} object,
  typically by calling the \code{\link[DelayedArray]{DelayedArray}()}
  constructor on it.

  Note that this is exactly what the \code{\link{ZarrArray}()} constructor
  function does.

  The result of this wrapping is a \link{ZarrArray} object, a
  \link[DelayedArray]{DelayedArray} derivative that simply represents
  a ZarrArraySeed object wrapped in a \link[DelayedArray]{DelayedArray}
  object.
}

\value{
  \code{ZarrArraySeed()} returns a ZarrArraySeed object.
}

\seealso{
  \itemize{
    \item \link{ZarrArray} objects.

    \item \code{\link[S4Arrays]{type}}, \code{\link[S4Arrays]{extract_array}},
          and \code{\link[S4Arrays]{is_sparse}}, in the \pkg{S4Arrays}
          package.

    \item \code{\link[DelayedArray]{chunkdim}} in the \pkg{DelayedArray}
          package.
  }
}

\examples{
zarr_path <- system.file(package="Rarr", "extdata",
                         "zarr_examples", "column-first", "int32.zarr")
seed <- ZarrArraySeed(zarr_path)
seed  # ZarrArraySeed object

path(seed)
dim(seed)
type(seed)
chunkdim(seed)

DelayedArray(seed)  # ZarrArray object

## Sanity checks:
stopifnot(class(seed) == "ZarrArraySeed",
          class(DelayedArray(seed)) == "ZarrArray")
}
\keyword{classes}
\keyword{methods}
