% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tree_ratio.R
\name{dt2tree_ratio}
\alias{dt2tree_ratio}
\alias{agg_tree_ratios}
\alias{decomp_ratios_parent}
\alias{decomp_ratios_parent_full}
\alias{decomp_ratios_root}
\alias{decomp_ratios_root_full}
\title{Decomsition of hierarchical data indicators}
\usage{
dt2tree_ratio(data, tree_name, numerator_name, denomiator_name, dim_names,
  mode = c("diff", "lag"), diff_postfix = "_diff",
  lag_postfix = "_lag", na.rm = TRUE)

agg_tree_ratios(node)

decomp_ratios_parent(n, multipl = 100)

decomp_ratios_parent_full(n, multipl = 100)

decomp_ratios_root(n, root_denominator_curr, root_denominator_lag,
  multipl = 100)

decomp_ratios_root_full(n, root_denominator_curr, root_denominator_lag,
  multipl = 100)
}
\description{
Convert data.table with numerator and denominator values to data.tree.
}
\details{
\code{dt_to_tree_ratio()} converts relational data into \code{data.tree} suitable for drilldown of ratio values.

\code{decomp_ratios_parent} and \code{decomp_ratios_parent_full} relats nodes' data relative to immediate parent node

\code{decomp_ratios_root} and \code{decomp_ratios_root_full} relats nodes' data relative to root of the tree
}
\examples{
tree <- dt2tree_ratio(DT,
                      tree_name       = "Total",
                      numerator_name  = "cost",
                      denomiator_name = "income",
                      dim_names       = c("region", "name"))

tree$Do(decomp_ratios_root_full,
        root_denominator_curr = tree$denominator_curr,
        root_denominator_lag  = tree$denominator_lag,
        multipl = 1)

}
