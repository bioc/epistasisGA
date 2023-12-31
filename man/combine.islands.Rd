% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/combine.islands.R
\name{combine.islands}
\alias{combine.islands}
\title{A function to combine GADGETS results for individual islands into a single
dataset.}
\usage{
combine.islands(
  results.dir,
  annotation.data,
  preprocessed.list,
  n.top.chroms.per.island = 1
)
}
\arguments{
\item{results.dir}{The directory in which individual island results from
\code{run.gadgets} are saved.}

\item{annotation.data}{A data frame containing columns 'RSID', 'REF' and
'ALT'. Column 'RSID' gives the RSIDs for the input SNPs, with the rows
ordered such that the first RSID entry corresponds to the first SNP
column in the data passed to function \code{preprocess.genetic.data}, the
second RSID corresponds to the second SNP column, etc.}

\item{preprocessed.list}{The initial list produced by function
\code{preprocess.genetic.data}.}

\item{n.top.chroms.per.island}{The number of top chromosomes per island to
save in the final combined list. Defaults to the single top chromosome.}
}
\value{
A data.table containing the results aggregated across islands. Note
these results be written to \code{results.dir} as
combined.island.unique.chromosome.results.rds'. See the package vignette for
more detailed descriptions of the content of each output column. Secondarily,
this will concatenate all individual island results files and store them
in a single file, called "all.island.results.concatenated.rds".
}
\description{
This function combines GADGETS results for individual islands into a single
dataset.
}
\examples{

data(case)
data(dad)
data(mom)
data(snp.annotations)

pp.list <- preprocess.genetic.data(as.matrix(case[, 1:10]),
                               father.genetic.data = as.matrix(dad[ , 1:10]),
                               mother.genetic.data = as.matrix(mom[ , 1:10]),
                               ld.block.vec = c(10))

run.gadgets(pp.list, n.chromosomes = 4, chromosome.size = 3,
       results.dir = 'tmp',
       cluster.type = 'interactive',
       registryargs = list(file.dir = 'tmp_reg', seed = 1500),
       generations = 2, n.islands = 2, island.cluster.size = 1,
       n.migrations = 0)

combined.res <- combine.islands('tmp', snp.annotations[ 1:10, ], pp.list)

unlink("tmp", recursive = TRUE)
unlink("tmp_reg", recursive = TRUE)

}
