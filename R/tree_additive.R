
#' @export
dt2tree <- function(
  data,
  tree_name,
  value_name,
  dim_names
) {
  FromDataFrameTable(
    data[,
         .(tree_name = tree_name,
           value = sum(eval(parse(text = value_name)), na.rm = TRUE)),
         by = dim_names
         ][,
           .(pathString = pathstr_from_mat(as.matrix(.SD)),
             value),
           .SDcols = c("tree_name", dim_names)],
    pathDelimiter = "|||")
}
