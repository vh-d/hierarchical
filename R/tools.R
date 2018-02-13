# tree creation -----------------------------------------------------------

#' @export
pathstr_from_mat <- function(mat) {
  return(apply(as.matrix(mat), 1, paste, collapse = "|||"))
}

