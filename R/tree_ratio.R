
#' @title Decomsition of hierarchical data indicators
#' @description Convert data.table with numerator and denominator values to data.tree.
#' @details
#' \code{dt_to_tree_ratio()} converts relational data into \code{data.tree} suitable for drilldown of ratio values.
#' @rdname ratio_decomp
#' @examples
#' tree <- dt2tree_ratio(DT,
#'                       tree_name       = "Total",
#'                       numerator_name  = "cost",
#'                       denomiator_name = "income",
#'                       dim_names       = c("region", "name"))
#' @export
dt2tree_ratio <- function(
  data,
  tree_name,
  numerator_name,
  denomiator_name,
  dim_names,
  mode = c("diff", "lag"),
  diff_postfix = "_diff",
  lag_postfix  = "_lag",
  na.rm = TRUE
) {

  mode <- match.arg(mode)

  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("Package 'data.table' needed for this function to work. Please install it.",
         call. = FALSE)
  }

  if (mode == "diff") {
    object <-
      data.tree::FromDataFrameTable(
        data[,
             .(tree_name        = tree_name,
               numerator_curr   = sum(get(numerator_name),                        na.rm = na.rm),
               denominator_curr = sum(get(denomiator_name),                       na.rm = na.rm),
               numerator_diff   = sum(get(paste0(numerator_name,  diff_postfix)), na.rm = na.rm),
               denominator_diff = sum(get(paste0(denomiator_name, diff_postfix)), na.rm = na.rm)),
             by = dim_names
             ][,
               .(pathString      = pathstr_from_mat(as.matrix(.SD)),
                 numerator_lag   = numerator_curr - numerator_diff,
                 numerator_curr,
                 numerator_diff,
                 denominator_lag = denominator_curr - denominator_diff,
                 denominator_curr,
                 denominator_diff),
               .SDcols = c("tree_name", dim_names)],
        pathDelimiter = "|||")
  } else {
    object <-
      data.tree::FromDataFrameTable(
        data[,
             .(tree_name        = tree_name,
               numerator_curr   = sum(get(numerator_name),                       na.rm = na.rm),
               denominator_curr = sum(get(denomiator_name),                      na.rm = na.rm),
               numerator_lag    = sum(get(paste0(numerator_name,  lag_postfix)), na.rm = na.rm),
               denominator_lag  = sum(get(paste0(denomiator_name, lag_postfix)), na.rm = na.rm)),
             by = dim_names
             ][,
               .(pathString       = pathstr_from_mat(as.matrix(.SD)),
                 numerator_lag,
                 numerator_curr,
                 numerator_diff   = numerator_curr - numerator_lag,
                 denominator_lag,
                 denominator_curr,
                 denominator_diff = denominator_curr - denominator_lag),
               .SDcols = c("tree_name", dim_names)],
        pathDelimiter = "|||")
  }

  # flag for decomposition methods
  object$type = "ratio"

  # compute features for inner nodes
  agg_tree(object)

  return(object)
}

#' @export
agg_tree.Node <- function(object) {
  switch (object$type,
    ratio = object$Do(agg_tree_ratios, filterFun = isNotLeaf)
  )
}

#' @export
agg_tree <- function(object, ...) {
  UseMethod("agg_tree")
}


#' @export
#' @rdname ratio_decomp
agg_tree_ratios <- function(node) {

  node$numerator_lag    <-  sum(node$Get("numerator_lag",    filterFun = isLeaf), na.rm = TRUE)
  node$numerator_curr   <-  sum(node$Get("numerator_curr",   filterFun = isLeaf), na.rm = TRUE)
  node$numerator_diff   <-  sum(node$Get("numerator_diff",   filterFun = isLeaf), na.rm = TRUE)

  node$denominator_lag  <-  sum(node$Get("denominator_lag",  filterFun = isLeaf), na.rm = TRUE)
  node$denominator_curr <-  sum(node$Get("denominator_curr", filterFun = isLeaf), na.rm = TRUE)
  node$denominator_diff <-  sum(node$Get("denominator_diff", filterFun = isLeaf), na.rm = TRUE)

}


#' @rdname ratio_decomp
#' @export
decomp_ratios_parent <- function(n, multipl = 100) {

  n$ratio_curr <- multipl * n$numerator_curr / n$denominator_curr
  n$ratio_lag  <- multipl * n$numerator_lag / n$denominator_lag
  n$ratio_diff <- n$ratio_curr - n$ratio_lag

  n$weight_curr <- if (isNotRoot(n)) n$denominator_curr / n$parent$denominator_curr else 1
  n$weight_lag  <- if (isNotRoot(n)) n$denominator_lag / n$parent$denominator_lag else 1
  n$weight_diff <- n$weight_curr - n$weight_lag

  n$ratio_effect  <- n$weight_lag * n$ratio_diff
  n$weight_effect <- n$weight_diff * n$ratio_curr

}



#' @rdname ratio_decomp
#' @details \code{decomp_ratios_parent} and \code{decomp_ratios_parent_full} relats nodes' data relative to immediate parent node
#' @export
decomp_ratios_parent_full <- function(n, multipl = 100) {

  n$ratio_curr <- multipl * n$numerator_curr / n$denominator_curr
  n$ratio_lag  <- multipl * n$numerator_lag / n$denominator_lag
  n$ratio_diff <- n$ratio_curr - n$ratio_lag

  n$weight_curr <- if (isNotRoot(n)) n$denominator_curr / n$parent$denominator_curr else 1
  n$weight_lag  <- if (isNotRoot(n)) n$denominator_lag / n$parent$denominator_lag else 1
  n$weight_diff <- n$weight_curr - n$weight_lag

  n$ratio_effect    <- n$weight_lag  * n$ratio_diff
  n$weight_effect   <- n$weight_diff * n$ratio_lag
  n$residual_effect <- n$weight_diff * n$ratio_diff

}



#' @rdname ratio_decomp
#' @details \code{decomp_ratios_root} and \code{decomp_ratios_root_full} relats nodes' data relative to root of the tree
#' @export
decomp_ratios_root <- function(
  n,
  root_denominator_curr,
  root_denominator_lag,
  multipl = 100
) {

  n$ratio_curr <- multipl * n$numerator_curr / n$denominator_curr
  n$ratio_lag  <- multipl * n$numerator_lag / n$denominator_lag
  n$ratio_diff <- n$ratio_curr - n$ratio_lag

  n$weight_curr <- n$denominator_curr / root_denominator_curr
  n$weight_lag  <- n$denominator_lag / root_denominator_lag
  n$weight_diff <- n$weight_curr - n$weight_lag

  n$ratio_effect  <- n$weight_lag * n$ratio_diff
  n$weight_effect <- n$weight_diff * n$ratio_curr

}





#' @rdname ratio_decomp
#' @examples
#'
#' tree$Do(decomp_ratios_root_full,
#'         root_denominator_curr = tree$denominator_curr,
#'         root_denominator_lag  = tree$denominator_lag,
#'         multipl = 1)
#'
#' @export
decomp_ratios_root_full <- function(
  n,
  root_denominator_curr,
  root_denominator_lag,
  multipl = 100
) {

  n$ratio_curr <- multipl * n$numerator_curr / n$denominator_curr
  n$ratio_lag  <- multipl * n$numerator_lag / n$denominator_lag
  n$ratio_diff <- n$ratio_curr - n$ratio_lag

  n$weight_curr <- n$denominator_curr / root_denominator_curr
  n$weight_lag  <- n$denominator_lag / root_denominator_lag
  n$weight_diff <- n$weight_curr - n$weight_lag

  n$ratio_effect    <- n$weight_lag  * n$ratio_diff
  n$weight_effect   <- n$weight_diff * n$ratio_lag
  n$residual_effect <- n$weight_diff * n$ratio_diff

}


# todo: option to drop some facets

#' Plot additive effects as result of change decomposition for ratio indicators
#' @param tree a tree object with all decomposed effect precomputed
#'
#' @param facet_labels custom user-defined labels for chart columns
#' @param eff_labels custom user-defined labels for guide
#' @param root_num_denom logical on/off switch for ploting root node's numerator and denominator
#' @param col_pal custom user-defined collor pallette
#' @param ... args passed to data.tree::ToDataFrameTree
#' @details `plot_tree_ratio()` requires `ggplot2` package
#' @examples
#' plot_tree_ratio(tree)
#' @export
plot_tree_ratio <- function(
  tree,
  facet_labels = c("Additive effects", "Ratio", "Numerator", "Denominator"),
  eff_labels = c("Total effect", "Weight effect", "Ratio effect", "Residual effect"),
  root_num_denom = FALSE,
  col_pal = NULL,
  ...
) {

  # require ggplot2 namespace
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' needed for this function to work. Please install it.",
      call. = FALSE)
  }

  dt <-
    data.tree::ToDataFrameTree(
      tree,
      ...,
      format = TRUE,
      "weight_effect", "ratio_effect", "residual_effect",
      "ratio_curr", "ratio_lag",
      "numerator_curr", "numerator_lag",
      "denominator_curr", "denominator_lag"
    )

  setDT(dt)
  dt[, levelName      := reorder(levelName,  -.I)]
  dt[, total_effect   := weight_effect + ratio_effect + residual_effect]

  dt[, ratio_value_low      := pmin(ratio_lag, ratio_curr)]
  dt[, ratio_value_increase := pmax(0, ratio_curr - ratio_lag)]
  dt[, ratio_value_decrease := pmax(0, ratio_lag - ratio_curr)]
  dt[, c("ratio_curr", "ratio_lag") := NULL]

  dt[, numerator_low      := pmin(numerator_lag, numerator_curr)     /1e6]
  dt[, numerator_increase := pmax(0, numerator_curr - numerator_lag) /1e6]
  dt[, numerator_decrease := pmax(0, numerator_lag  - numerator_curr)/1e6]
  dt[, c("numerator_curr", "numerator_lag") := NULL]

  dt[, denominator_low      := pmin(denominator_lag, denominator_curr    )/1e6]
  dt[, denominator_increase := pmax(0, denominator_curr - denominator_lag)/1e6]
  dt[, denominator_decrease := pmax(0, denominator_lag - denominator_curr)/1e6]
  dt[, c("denominator_curr", "denominator_lag") := NULL]

  if (!root_num_denom) {
    dt[1, c("numerator_low",   "numerator_increase",   "numerator_decrease")   := NA]
    dt[1, c("denominator_low", "denominator_increase", "denominator_decrease") := NA]
  }

  # unpivot
  dtl <- melt(dt, id = "levelName", variable.factor = FALSE)
  dtl[, panel := regmatches(variable, regexpr("effect|ratio_value|numerator|denominator", variable))]
  dtl[, panel := factor(panel, levels = c("effect", "ratio_value", "numerator", "denominator"), labels = facet_labels)]

  level_names <- c("ratio_value_increase",
                   "ratio_value_decrease",
                   "ratio_value_low",
                   "numerator_increase",
                   "numerator_decrease",
                   "numerator_low",
                   "denominator_increase",
                   "denominator_decrease",
                   "denominator_low",
                   "total_effect",
                   "weight_effect",
                   "ratio_effect",
                   "residual_effect")

  dtl[, variable := factor(variable,
                           levels = level_names)]

  # colors
  if (is.null(col_pal)) {
    col_pal <- c("#000000", "#AAAAAA", "#BEBEBE", scales::hue_pal(h = c(0, 360) + 15, c = 100, l = 65, h.start = 0, direction = 1)(5))
    names(col_pal) <- c("total_effect", "low", "residual_effect", "decrease", "", "increase", "weight_effect", "ratio_effect")
  }

  rexp <- regexpr(pattern = "(low)|(increase)|(decrease)|(total_effect)|(weight_effect)|(ratio_effect)|(residual_effect)", text = level_names)
  color_pal <- col_pal[regmatches(x = level_names, m = rexp)]
  names(color_pal) <- level_names

  # plot
  ggplot(data = dtl[variable != "total_effect"],
         aes(y = value,
             x = levelName)) +
    geom_col(aes(fill = variable)) +
    geom_point(data = dtl[variable == "total_effect"],
               aes(x = levelName,
                   y = value,
                   color = variable),
               size = 2) +
    coord_flip() +
    facet_grid( ~ panel, scales = "free_x") +
    scale_fill_manual(breaks = c("weight_effect", "ratio_effect", "residual_effect"),
                      values = color_pal,
                      labels = eff_labels[-1],
                      name  = NULL) +
    scale_color_manual(breaks = c("total_effect"),
                       values = color_pal,
                       name = NULL,
                       labels = eff_labels[1]) +
    ylab(label = NULL) +
    theme(legend.position = "bottom",
          axis.text.y = element_text(family = "mono",
                                     face   = "bold",
                                     # size = 8,
                                     hjust = 0,
                                     vjust = 0),
          legend.text = element_text(size = 7))
}
