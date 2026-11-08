# The checked-out project is authoritative even if an older version is installed.
if (!requireNamespace("pkgload",quietly=TRUE)) stop("Ejecute source('instalar.R') antes de iniciar")
pkgload::load_all(".",quiet=TRUE)
run_app()
