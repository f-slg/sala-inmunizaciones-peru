#' Ejecutar la sala situacional de inmunizaciones
#' @param public_mode Deshabilitar carga y seguimiento nominal para publicacion.
#' @param data Datos iniciales con el contrato del paquete, o NULL para demostracion.
#' @param options Opciones de shinyApp.
#' @param ... Opciones adicionales de golem.
#' @return Aplicacion Shiny.
#' @export
run_app <- function(public_mode=get_golem_config("public_mode"),data=NULL,options=list(),...) {
  golem::with_golem_options(shiny::shinyApp(ui=app_ui,server=app_server,options=options,onStart=function() {
      previous<-base::options(shiny.maxRequestSize=get_golem_config("max_upload_mb")*1024^2)
      shiny::onStop(function() base::options(previous))
    }),
    golem_opts=list(public_mode=public_mode,data=data,...))
}
