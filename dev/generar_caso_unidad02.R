# Regenera los datos del caso con el formato integral nativo de la aplicacion.
# Los valores sanitarios son simulados; no es la base original del aula virtual.
pkgload::load_all(".")
salainmunizaciones:::write_template(
  "entregables/Caso_Unidad02_8_distritos.xlsx",
  dataset=salainmunizaciones:::unit02_dataset()
)
