# Abrir salainmunizaciones.Rproj y ejecutar source("dev/iniciar_unidad02.R").
# Se carga el libro editable del caso, con datos sanitarios simulados.
local({
  archivo_caso <- file.path("entregables", "Caso_Unidad02_8_distritos.xlsx")
  if (!file.exists("DESCRIPTION") || !file.exists(archivo_caso)) {
    stop("Abra salainmunizaciones.Rproj antes de ejecutar este archivo.", call. = FALSE)
  }
  source("instalar.R", local = TRUE)
  pkgload::load_all(".", quiet = TRUE)
  caso <- salainmunizaciones::import_workbook(archivo_caso)
  if (!isTRUE(caso$exito)) {
    stop("No se pudo cargar el caso: ", paste(caso$informe$detalle, collapse = "; "), call. = FALSE)
  }
  message("Caso Unidad 02: ocho distritos simulados, cierre diciembre 2026.")
  shiny::runApp(salainmunizaciones::run_app(data = caso$datos), launch.browser = interactive())
})
