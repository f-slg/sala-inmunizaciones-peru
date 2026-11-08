# Pure helpers: no shell commands, global working directory or network access.
`%||%` <- function(x, y) if (is.null(x) || !length(x)) y else x
assert_columns <- function(x, required, name = "tabla") {
  missing <- setdiff(required, names(x))
  if (length(missing)) stop(name, ": faltan columnas ", paste(missing, collapse=", "), call.=FALSE)
  invisible(x)
}
assert_number <- function(x, name, min = 0, max = Inf, integer = FALSE) {
  if (!is.numeric(x) || any(!is.finite(x)) || any(x < min | x > max) ||
      (integer && any(x != floor(x)))) stop(name, ": valor numerico fuera de rango", call.=FALSE)
  invisible(x)
}
safe_pct <- function(n, d) ifelse(is.finite(d) & d > 0 & is.finite(n), n/d*100, NA_real_)
fmt_pct <- function(x) ifelse(is.na(x), "Sin dato", paste0(formatC(x, digits=1, format="f", decimal.mark=","), " %"))
empty_frame <- function(cols) as.data.frame(stats::setNames(rep(list(character()), length(cols)), cols), stringsAsFactors=FALSE)
add_months <- function(date, months) as.Date(lubridate::`%m+%`(as.Date(date), lubridate::period(month=months)))
normalise_names <- function(x) {
  x <- chartr("\u00e1\u00e9\u00ed\u00f3\u00fa\u00f1\u00fc", "aeiounu", tolower(trimws(x)))
  x <- gsub("[^a-z0-9]+", "_", x); x <- gsub("^_|_$", "", x)
  x[x %in% c("ano","year")] <- "anio"; x
}
read_resource_csv <- function(name) utils::read.csv(app_sys("extdata", name), stringsAsFactors=FALSE, na.strings=c("", "NA"), fileEncoding="UTF-8", check.names=FALSE)
dataset_fingerprint <- function(data) {
  # Reproducibility checksum, not an anonymisation or security mechanism.
  file<-tempfile(fileext=".json");on.exit(unlink(file),add=TRUE)
  jsonlite::write_json(data,file,auto_unbox=TRUE,na="null",Date="ISO8601",digits=NA)
  unname(tools::md5sum(file))
}

utils::globalVariables(c("distrito","cobertura","alerta","producto_id","pedido_neto","mes","dosis"))
