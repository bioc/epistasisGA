#' A function to create permuted datasets for permutation based hypothesis
#' testing.
#'
#' This function creates permuted datasets for permutation based hypothesis
#' testing of GADGETS fitness scores.
#'
#' @param preprocessed.list The output list from \code{preprocess.genetic.data}
#' for the original genetic data.
#' @param permutation.data.file.path  If running GADGETS for GxG interactions,
#' this argument specifies a directory where each permuted dataset will be saved
#' on disk. If searching  for GxE interactions, permuted versions of the
#' exposure matrix will be saved to this directory.
#' @param n.permutations The number of permuted datasets to create.
#' @param bp.param The BPPARAM argument to be passed to bplapply.
#' See \code{BiocParallel::bplapply} for more details.
#' @return If genetic data are specified, a total of \code{n.permutations}
#' datasets containing pairs of case and complement data, where the observed
#' case/complement status has been randomly flipped or not flipped, will be
#' saved to \code{permutation.data.file.path}. If exposure data are specified, a
#' total of \code{n.permutations} exposure matrices, where the observed
#' exposures have been randomly re-assigned across the permuted 'families'.
#' @examples
#'
#' data(case)
#' case <- as.matrix(case)
#' data(dad)
#' dad <- as.matrix(dad)
#' data(mom)
#' mom <- as.matrix(mom)
#' pp.list <- preprocess.genetic.data(case[, 1:10],
#'                                father.genetic.data = dad[ , 1:10],
#'                                mother.genetic.data = mom[ , 1:10],
#'                                ld.block.vec = c(10))
#' set.seed(15)
#' perm.data.list <- permute.dataset(pp.list, "tmp_perm", n.permutations = 1)
#' unlink("tmp_perm", recursive = TRUE)
#'
#' @importFrom BiocParallel bplapply bpparam
#' @importFrom stats rbinom
#' @export

permute.dataset <- function(preprocessed.list, permutation.data.file.path,
                            n.permutations = 100,
                            bp.param = bpparam()) {

    if (!dir.exists(permutation.data.file.path)){

        dir.create(permutation.data.file.path, recursive = TRUE)

    }
    permutation.data.file.path <- normalizePath(permutation.data.file.path)

    # grab input genetic data
    case.genetic.data <- preprocessed.list$case.genetic.data
    complement.genetic.data <- preprocessed.list$complement.genetic.data

    ### permute the data ###
    n.families <- nrow(case.genetic.data)
    if (!preprocessed.list$E_GADGETS){

        permuted.data.list <- bplapply(seq_len(n.permutations),
                                       function(permute, n.families,
                                                case.genetic.data,
                                                complement.genetic.data) {

            # flip the case/complement status for these families
            flip.these <- seq_len(n.families)[as.logical(
                rbinom(n.families, 1, 0.5))]
            case.perm <- case.genetic.data
            comp.perm <- complement.genetic.data
            case.perm[flip.these, ] <- complement.genetic.data[flip.these, ]
            comp.perm[flip.these, ] <- case.genetic.data[flip.these, ]
            case.out.file <- file.path(permutation.data.file.path,
                                       paste0("case.permute", permute, ".rds"))
            comp.out.file <- file.path(permutation.data.file.path,
                                       paste0("complement.permute",
                                              permute, ".rds"))

            #account for missing vals
            case.perm[case.perm == -9] <- NA
            comp.perm[comp.perm == -9] <- NA
            saveRDS(case.perm, case.out.file)
            saveRDS(comp.perm, comp.out.file)

        }, n.families = n.families, case.genetic.data = case.genetic.data,
        complement.genetic.data = complement.genetic.data,
        BPPARAM = bp.param)

    } else {

        exposure <- preprocessed.list$exposure.mat
        n.fams <- nrow(exposure)
        permuted.data.list <- lapply(seq_len(n.permutations), function(permute) {

            shuffled.order <- sample(seq_len(n.fams), n.fams)
            exposure.perm <- exposure[shuffled.order, , drop = FALSE]
            out.file <- file.path(permutation.data.file.path,
                                  paste0("exposure.permute", permute, ".rds"))
            saveRDS(exposure.perm, out.file)

        })

    }

}
