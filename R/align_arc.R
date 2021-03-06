##' Match/align arhetypes
##' @rdname align_arc
##' @name align_arc
##' @description \code{align_arc()} matches archetypes in arc2 to arc1 by solving a bipartite matching problem on euclidian distances between archetypes.
##' @param arc1 reference matrix of archetype positions dim(dimensions, archetypes)
##' @param arc2 matrix of archetype positions dim(dimensions, archetypes) to be aligned with arc1
##' @param type method for finding matching vertices. Linear programming (lpsolve) or exhaustive search (do not use for more than 10 vertices)
##' @return \code{align_arc()} list containing: total distance between archetypes in arc1 and arc2 (dist), integer vector specifying indices of archetypes in arc2 that match archetypes in arc1 (ind)
##' @export align_arc
##' @examples
##' # Generate data
##' set.seed(4355)
##' archetypes = generate_arc(arc_coord = list(c(5, 0), c(-10, 15), c(-30, -20)),
##'                           mean = 0, sd = 1)
##' data = generate_data(archetypes$XC, N_examples = 1e4, jiiter = 0.04, size = 0.9)
##' dim(data)
##' # fit polytopes to 2 subsamples of the data
##' arc_data = fit_pch_bootstrap(data, n = 2, sample_prop = 0.65, seed = 2543,
##'                         order_type = "align", noc = as.integer(6),
##'                         delta = 0, type = "s")
##' # align archetypes
##' align_arc(arc_data$pch_fits$XC[[1]], arc_data$pch_fits$XC[[2]])
align_arc = function(arc1, arc2, type = c("lpsolve", "exhaustive")[1]) {

  if(!isTRUE(all.equal(dim(arc1), dim(arc2)))) stop("align_arc() trying to match different number of archetypes")

  arc_distance = arch_dist(arc1, arc2)

  if(type == "lpsolve") {

    # find matches using linear programming minimisation
    res = lpSolve::lp.assign(arc_distance, "min")
    dist = res$objval
    # extract matching vertices
    ind = apply(res$solution, 1, which.max)

  } else if(type == "exhaustive") {

    arc2_combs = gen_permut(nrow(arc_distance))
    distances = vapply(seq(1, nrow(arc_distance)), function(i, arc2_combs){
      arc_distance[i, arc2_combs[,i]]
    }, FUN.VALUE = numeric(nrow(arc2_combs)), arc2_combs)
    distances = rowSums(distances)
    ind = arc2_combs[which.min(distances),]
    dist = min(distances)

  } else {
    stop("type should be one of align_arc(type = c(\"lpsolve\", \"exhaustive\"))")
  }

  list(dist = dist, ind = ind)
}

##' @rdname align_arc
##' @name gen_permut
##' @description \code{gen_permut()} used for exhaustive search generates a matrix of all possible permutations of n elements. Each row is a different permutation.
##' @param n number of element to permute
##' @details \code{gen_permut()} function is taken from https://stackoverflow.com/questions/11095992/generating-all-distinct-permutations-of-a-list-in-r
##' @return \code{gen_permut()} a matrix of all possible gen_permut (in rows)
##' @export gen_permut
gen_permut = function(n){
  if(n==1){
    return(matrix(1))
  } else {
    sp = gen_permut(n-1)
    p = nrow(sp)
    A = matrix(nrow=n*p,ncol=n)
    for(i in 1:n){
      A[(i-1)*p+1:p,] = cbind(i,sp+(sp>=i))
    }
    return(A)
  }
}
