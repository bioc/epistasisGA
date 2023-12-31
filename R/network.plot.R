#' A function to plot a network of SNPs with potential multi-SNP effects.
#'
#' This function plots a network of SNPs with potential multi-SNP effects.
#'
#' @param graphical.score.list The list returned by function
#' \code{compute.graphical.scores}, or a subset of it, if there are too many
#' returned SNP-pairs to plot without the figure becoming too crowded.
#' By default, the SNPs will be labeled with their RSIDs, listed in columns 3
#' and 4. Users can create custom labels by changing the values in these
#' two columns.
#' @param preprocessed.list The initial list produced by function
#' \code{preprocess.genetic.data}.
#' @param n.top.scoring.pairs An integer indicating the number of top scoring
#' SNP-pairs to plot. Defaults to, NULL, which plots all pairs.
#' For large networks, plotting a subset of the top scoring pairs can improve
#' the appearance of the graph.
#' @param node.shape The desired node shape. See
#' \code{names(igraph:::.igraph.shapes)} for available shapes. Defaults to
#' circle. If both maternal and child SNPs are to be plotted, this argument
#' should be a vector of length 2, whose first element is the desired child SNP
#' shape, and second SNP is the desired mother SNP shape.
#' @param repulse.rad A scalar affecting the graph shape. Decrease to reduce
#' overlapping nodes, increase to move nodes closer together.
#' @param node.size A scalar affecting the size of the graph nodes.
#' Increase to increase size.
#' @param graph.area A scalar affecting the size of the graph area.
#' Increase to increase graph area.
#' @param vertex.label.cex A scalar controlling the size of the vertex label.
#' Increase to increase size.
#' @param edge.width.cex A scalar controlling the width of the graph edges.
#' Increase to make edges wider.
#' @param plot A logical indicating whether the network should be plotted.
#' If set to false, this function will return an igraph object to be used for
#' manual plotting.
#' @param edge.color.ramp A character vector of colors. The coloring of the
#' network edges will be shown on a gradient, with the lower scoring edge
#' weights closer to the first color specified in \code{edge.color.ramp}, and
#' higher scoring weights closer to the last color specified. By default, the
#' low scoring edges are light blue, and high scoring edges are dark blue.
#' @param node.color.ramp A character vector of colors. The coloring of the
#' network nodes will be shown on a gradient, with the lower scoring nodes
#' closer to the first color specified in \code{node.color.ramp}, and higher
#' scoring nodes closer to the last color specified. By default, the low
#' scoring nodes are whiter, and high scoring edges are redder.
#' @param plot.legend A boolean indicating whether a legend should be plotted.
#' Defaults to TRUE.
#' @param high.ld.threshold A numeric value between 0 and 1, indicating the r^2
#'  threshold in complements (or unaffected siblings)
#' above which a pair of SNPs in the same LD block
#' (as specified in \code{preprocessed.list}) should be considered in high LD.
#' Connections between these high LD SNPs will be dashed instead of solid lines.
#' Defaults to 0.1. If both maternal and child SNPs are among the input variants
#' in \code{preprocessed.list}, dashed lines can only appear between SNPs of the
#' same type, i.e., between two maternal SNPs, or between two child SNPs.
#' @param plot.margins A vector of length 4 passed to \code{par(mar = )}.
#' Defaults to c(2, 1, 2, 1).
#' @param legend.title.cex A numeric value controlling the size of the legend
#' titles. Defaults to 1.75. Increase to increase font size, decrease to decrease
#' font size.
#' @param legend.axis.cex A numeric value controlling the size of the legend
#' axis labels. Defaults to 1.75. Increase to increase font size, decrease to
#' decrease font size.
#' @param ... Additional arguments to be passed to \code{plot.igraph}.
#' @return An igraph object, if \code{plot} is set to FALSE.
#' @examples
#'
#' data(case)
#' data(dad)
#' data(mom)
#' case <- as.matrix(case)
#' dad <- as.matrix(dad)
#' mom <- as.matrix(mom)
#' data(snp.annotations)
#' set.seed(1400)
#'
#' # preprocess data
#' target.snps <- c(1:3, 30:32, 60:62, 85)
#' pp.list <- preprocess.genetic.data(case[, target.snps],
#'                                    father.genetic.data = dad[ , target.snps],
#'                                    mother.genetic.data = mom[ , target.snps],
#'                                    ld.block.vec = c(3, 3, 3, 1))
#' ## run GA for observed data
#'
#' #observed data chromosome size 2
#' run.gadgets(pp.list, n.chromosomes = 5, chromosome.size = 2,
#'        results.dir = 'tmp_2',
#'        cluster.type = 'interactive',
#'        registryargs = list(file.dir = 'tmp_reg', seed = 1500),
#'        generations = 2, n.islands = 2, island.cluster.size = 1,
#'        n.migrations = 0)
#'  combined.res2 <- combine.islands('tmp_2', snp.annotations[ target.snps, ],
#'                                    pp.list, 2)
#'  unlink('tmp_reg', recursive = TRUE)
#'
#'  #observed data chromosome size 3
#'  run.gadgets(pp.list, n.chromosomes = 5, chromosome.size = 3,
#'        results.dir = 'tmp_3',
#'        cluster.type = 'interactive',
#'        registryargs = list(file.dir = 'tmp_reg', seed = 1500),
#'        generations = 2, n.islands = 2, island.cluster.size = 1,
#'        n.migrations = 0)
#'  combined.res3 <- combine.islands('tmp_3', snp.annotations[ target.snps, ],
#'                                    pp.list, 2)
#'  unlink('tmp_reg', recursive = TRUE)
#'
#' ## create list of results
#' final.results <- list(combined.res2[1:3, ], combined.res3[1:3, ])
#'
#'  ## compute edge scores
#'  set.seed(20)
#'  graphical.list <- compute.graphical.scores(final.results, pp.list,
#'                                             pval.thresh = 0.5)
#'
#' ## plot
#' set.seed(10)
#' network.plot(graphical.list, pp.list)
#'
#' lapply(c("tmp_2", "tmp_3"), unlink, recursive = TRUE)
#'
#' @import igraph
#' @importFrom qgraph qgraph.layout.fruchtermanreingold
#' @importFrom grDevices adjustcolor colorRampPalette as.raster
#' @importFrom data.table melt
#' @importFrom stats cor
#' @importFrom graphics rasterImage axis layout par
#' @export

network.plot <- function(graphical.score.list, preprocessed.list,
                         n.top.scoring.pairs = NULL, node.shape = "circle",
                         repulse.rad = 1000, node.size = 25, graph.area = 100,
                         vertex.label.cex = 0.5,
                         edge.width.cex = 12, plot = TRUE,
                         edge.color.ramp = c("lightblue", "blue"),
                         node.color.ramp = c("white", "red"),
                         plot.legend = TRUE,
                         high.ld.threshold = 0.1, plot.margins = c(2, 1, 2, 1),
                         legend.title.cex = 1.75,
                         legend.axis.cex = 1.75, ...) {

    # pick out the pieces of the graphical.score.list
    edge.dt <- graphical.score.list[["pair.scores"]]
    node.dt <- graphical.score.list[["snp.scores"]]

    # if plotting a subset of pairs, subset input data
    if (!is.null(n.top.scoring.pairs)) {
        edge.dt <- edge.dt[seq_len(n.top.scoring.pairs), ]
        snp1 <- edge.dt$SNP1
        snp2 <- edge.dt$SNP2
        snps <- c(snp1, snp2)
        node.dt <- node.dt[node.dt$SNP %in% snps, ]
    }

    #compute r2 vals for snps in the same ld block, assign 0 otherwise
    r2.vals <- vapply(seq(1, nrow(edge.dt)), function(x){

        # pick out the snp pair in the preprocessed list
        target.snps <- as.vector(t(edge.dt[x, c(1, 2)]))

        # check to see if they are of the same type (both child or both mom)
        s1 <- target.snps[1]
        s2 <- target.snps[2]
        s1.type <- ifelse(s1 %in% preprocessed.list$mother.snps, 1, 0)
        s2.type <- ifelse(s2 %in% preprocessed.list$mother.snps, 1, 0)
        if (s1.type != s2.type){

          return(0.0)

        } else {

          # check if snps are located in same ld block
          cs.ld.block.vec <- preprocessed.list$ld.block.vec
          same.ld.block <- NA
          for (upper.limit in cs.ld.block.vec){

            if (all(target.snps <= upper.limit)){

              same.ld.block <- TRUE
              break

            } else if (any(target.snps <= upper.limit)){

              same.ld.block <- FALSE
              break

            }

          }

          # if on same ld block, compute r2
          if (!same.ld.block){

            return(0.0)

          } else {

            if (preprocessed.list$E_GADGETS){
                
                snp1 <- preprocessed.list$mother.genetic.data[ , s1] +
                                preprocessed.list$father.genetic.data[ , s1] -
                                preprocessed.list$case.genetic.data[ , s1]
                
                snp2 <- preprocessed.list$mother.genetic.data[ , s2] +
                                preprocessed.list$father.genetic.data[ , s2] -
                                preprocessed.list$case.genetic.data[ , s2]
                
            } else {
                
                snp1 <- preprocessed.list$complement.genetic.data[ , s1]
                snp2 <- preprocessed.list$complement.genetic.data[ , s2]
                
            }
            
            # missing are coded as -9
            snp1[snp1 == -9] <- NA
            snp2[snp2 == -9] <- NA

            r2 <- cor(snp1, snp2, use = "complete.obs")^2
            return(r2)

          }

        }
    }, 1.0)

    # subset to target cols
    edge.dt <- edge.dt[, c(1, 2, 5)]

    # get node labels
    node.labels <- as.character(node.dt$rsid)
    names(node.labels) <- as.character(node.dt$SNP)

    # convert to data.frames and scale the edge and node scores
    edge.df <- as.data.frame(edge.dt)
    max.edge.widths <- max(edge.df$pair.score)
    edge.widths <- edge.df$pair.score / max(edge.df$pair.score)
    raw.edge.widths <- edge.df$pair.score
    node.df <- as.data.frame(node.dt[, c(1, 3)])
    colnames(node.df) <- c("name", "size")
    max.node.size <- max(node.df$size)
    node.size.raw <- node.df$size
    node.df$size <- node.size * (node.df$size / max(node.df$size))

    # prepare for plotting
    colnames(edge.df)[seq_len(2)] <- c("from", "to")
    network <- graph.data.frame(edge.df[, seq_len(2)], directed = FALSE,
                                vertices = node.df)
    E(network)$weight <- edge.df$pair.score
    E(network)$width <- edge.width.cex * edge.widths
    color_fun_e <- colorRampPalette(edge.color.ramp)
    edge.required.colors <- as.integer(as.factor(E(network)$weight))
    raw.edge.colors <- color_fun_e(length(unique(edge.required.colors)))
    edge.colors <- vapply(seq_len(length(edge.widths)),
                          function(x) adjustcolor(raw.edge.colors[
                              edge.required.colors][x],
                                                  alpha.f = edge.widths[x]),
                          "#0")
    E(network)$color <- edge.colors

    color_fun_n <- colorRampPalette(node.color.ramp)
    node.required.colors <- as.integer(as.factor(V(network)$size))
    node.colors <- color_fun_n(length(unique(node.required.colors)))
    V(network)$color <- node.colors[node.required.colors]
    if (length(node.shape) == 1){

        V(network)$shape <- node.shape

    } else {

        mom.snps <- preprocessed.list$mother.snps
        child.snps <- preprocessed.list$child.snps
        all.snps <- node.dt$SNP
        child.node.shape <- node.shape[1]
        mom.node.shape <- node.shape[2]
        node.shapes <- rep(child.node.shape, length(all.snps))
        node.shapes[all.snps %in% mom.snps] <- mom.node.shape
        V(network)$shape <- node.shapes

    }

    V(network)$label.cex <- vertex.label.cex*node.df$size/node.size
    V(network)$label <- node.labels[V(network)$name]

    E(network)$lty <- ifelse(r2.vals >= high.ld.threshold, 3, 1)

    # if desired, plot
    if (plot) {
        net.edges <- get.edgelist(network, names = FALSE)
        coords <- qgraph.layout.fruchtermanreingold(net.edges,
                                                    vcount = vcount(network),
                                                    repulse.rad = repulse.rad *
            vcount(network), area = graph.area * (vcount(network)^2))

        if (length(unique(edge.colors)) > 1 & plot.legend){

            par(mar = plot.margins)
            layout(matrix(c(1, 1, 2, 3), ncol = 2, byrow = FALSE), widths =
                       c(3.5,0.5), heights = c(1,1))
            plot(network, layout = coords, asp = 0, ...)

            node_legend <- as.raster(matrix(rev(node.colors), ncol = 1))
            plot(c(0,2),c(0,1),type = 'n', axes = FALSE, xlab = '', ylab = '',
                 main = 'SNP-Score',
                 cex.main = legend.title.cex)
            rasterImage(node_legend, 0.75, 0, 1, 1)
            n.legend.labels <- round(seq(min(node.size.raw),
                                         max(node.size.raw), length.out = 5),
                                     digits = 1)
            axis(side = 4, at = seq(0, 1, length.out = 5),
                 labels = n.legend.labels, pos = 1, cex.axis = legend.axis.cex)

            edge_legend <- as.raster(matrix(rev(raw.edge.colors), ncol=1))
            plot(c(0,2),c(0,1),type = 'n', axes = FALSE,xlab = '', ylab = '',
                 main = 'Pair-Score',
                 cex.main = legend.title.cex)
            rasterImage(edge_legend, 0.75, 0, 1, 1)
            e.legend.labels <- round(seq(min(raw.edge.widths),
                                         max(raw.edge.widths), length.out = 5),
                                     digits = 1)
            axis(side = 4, at = seq(0, 1, length.out = 5),
                 labels = e.legend.labels, pos = 1, cex.axis = legend.axis.cex)


        } else {
            plot(network, layout = coords, asp = 0, ...)
        }

        # otherwise, return igraph object
    } else {
        return(network)
    }
}
