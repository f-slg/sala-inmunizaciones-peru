# Publish only an explicitly reviewed aggregated project. No credentials in code.
# Run from the project root after installing the package with R CMD INSTALL .
# 1. Configure your account interactively in RStudio or rsconnect::setAccountInfo.
# 2. Review the aggregated deployment dataset; no persons/events/eligibility.
# 3. In a SEPARATE deployment folder create app.R:
#    salainmunizaciones::run_app(public_mode=TRUE, data=readRDS('datos_agregados.rds'))
# 4. Install the package from an accessible source (private repository or package
#    repository) on the hosting service. Do not deploy nominal workbooks or tokens.
# 5. Call rsconnect::deployApp on that deployment folder only.
# Nothing is published automatically by this script.
message("Revise las instrucciones de publicacion y configure una carpeta agregada independiente.")
