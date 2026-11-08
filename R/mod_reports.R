mod_reports_ui <- function(id) {
  ns<-shiny::NS(id)
  shiny::tagList(module_card("Informe tecnico y resultados",
    shiny::p("Exportaciones agregadas con fuentes, fecha de corte, parametros y version. El informe HTML es autonomo y puede imprimirse desde el navegador."),
    shiny::downloadButton(ns("excel"),"Resultados agregados \u00b7 Excel"),shiny::downloadButton(ns("html"),"Informe tecnico \u00b7 HTML")),
    mod_table_ui(ns("rubric"),"Ruta individual de aprendizaje y evaluacion"))
}
mod_reports_server <- function(id,tables,state,filters) shiny::moduleServer(id,function(input,output,session) {
  output$excel<-shiny::downloadHandler(filename=function() paste0("Resultados_",filters()$year,".xlsx"),content=function(file) export_aggregates(file,tables()))
  output$html<-shiny::downloadHandler(filename=function() paste0("Informe_",filters()$year,".html"),content=function(file) htmltools::save_html(report_html(tables(),state()$configuracion,filters()),file=file))
  mod_table_server("rubric",shiny::reactive(data.frame(componente=c("Calidad del dato y denominadores","Calculo e interpretacion de indicadores","Programacion y logistica","Acciones de mejora","Reproducibilidad y presentacion"),peso=c(25,25,20,20,10),evidencia=c("Fuentes y validacion documentadas","Coberturas, continuidad y limites nominales","Necesidades, stock e insumos con supuestos","Responsables, metas, fechas y seguimiento","Aplicacion propia, informe y defensa individual"))))
})
