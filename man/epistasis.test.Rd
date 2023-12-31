% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/epistasis.test.R
\name{epistasis.test}
\alias{epistasis.test}
\title{A function to run a test of the null hypothesis that a collection of SNPs do
not exhibit epistasis, conditional
upon observed marginal SNP-disease associations.}
\usage{
epistasis.test(
  snp.cols,
  preprocessed.list,
  n.permutes = 10000,
  n.different.snps.weight = 2,
  n.both.one.weight = 1,
  weight.function.int = 2,
  recessive.ref.prop = 0.75,
  recode.test.stat = 1.64,
  maternal.fetal.test = FALSE
)
}
\arguments{
\item{snp.cols}{An integer vector specifying the columns in the input data
containing the SNPs to be tested.}

\item{preprocessed.list}{The initial list produced by function
\code{preprocess.genetic.data}.}

\item{n.permutes}{The number of permutations on which to base the test.
Defaults to 10000.}

\item{n.different.snps.weight}{The number by which the number of different
SNPs between a case and complement/unaffected sibling is multiplied in
computing the family weights. Defaults to 2.}

\item{n.both.one.weight}{The number by which the number of SNPs equal to 1 in
both the case and complement/unaffected sibling is multiplied in computing
the family weights. Defaults to 1.}

\item{weight.function.int}{An integer used to assign family weights.
Specifically, we use \code{weight.function.int} in a function that takes the
weighted sum of the number of different SNPs and SNPs both equal to one as an
argument, denoted as x, and returns a family weight equal to
\code{weight.function.int}^x. Defaults to 2.}

\item{recessive.ref.prop}{The proportion to which the observed proportion of
informative cases with the provisional risk genotype(s) will be compared
to determine whether to recode the SNP as recessive. Defaults to 0.75.}

\item{recode.test.stat}{For a given SNP, the minimum test statistic required
to recode and recompute the fitness score using recessive coding. Defaults to
 1.64.}

\item{maternal.fetal.test}{A boolean indicating whether the test specifically
for a maternal-fetal interaction should be run. Defaults to FALSE.}
}
\value{
A list of thee elements:
\describe{
 \item{pval}{The p-value of the test. (In GADGETS papers, these are instead
 referred to as h-values)}
 \item{obs.fitness.score}{The fitness score from the observed data}
 \item{perm.fitness.scores}{A vector of fitness scores for the
  permuted datasets.}
}
}
\description{
This function runs a permutation based test of the null hypothesis that a
 collection of SNPs do not exhibit epistasis,
conditional upon observed marginal SNP-disease associations.
}
\examples{

data(case)
data(dad)
data(mom)
data(snp.annotations)

pp.list <- preprocess.genetic.data(as.matrix(case),
                               father.genetic.data = as.matrix(dad),
                               mother.genetic.data = as.matrix(mom),
                               ld.block.vec = rep(25, 4))

run.gadgets(pp.list,
    n.chromosomes = 5, chromosome.size = 3,
    results.dir = "tmp", cluster.type = "interactive",
    registryargs = list(file.dir = "tmp_reg", seed = 1300),
    n.islands = 8, island.cluster.size = 4,
    n.migrations = 2
)

combined.res <- combine.islands("tmp", snp.annotations, pp.list, 2)

top.snps <- as.vector(t(combined.res[1, 1:3]))
set.seed(10)
epi.test.res <- epistasis.test(top.snps, pp.list)

unlink('tmp', recursive = TRUE)
unlink('tmp_reg', recursive = TRUE)
}
