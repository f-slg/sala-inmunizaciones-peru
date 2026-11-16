mod_priority_ui <- function(id) {
  ns<-shiny::NS(id)
  shiny::tagList(module_card("Seleccion de distritos para intervencion",
    shiny::p("Compare los ocho distritos del caso de Unidad 02 o los distritos de su propio proyecto. La cobertura y desercion siempre corresponden a pentavalente y al cierre administrativo seleccionado."),
    shiny::numericInput(ns("slots"),"Distritos que permite intervenir el presupuesto",value=3,min=0,max=100,step=1),
    shiny::p(priority_policy()),status_legend(),shiny::uiOutput(ns("reading"))),
    mod_table_ui(ns("ranking"),"Orden propuesto y sustento","Cobertura: rojo <80 %, amarillo 80 a <95 %, verde 95 a 100 %. Desercion: rojo >10 %, verde 0 a 10 %. Cortes de visualizacion educativa. Alta falta de seguimiento conserva la clasificacion de la fuente; no se infiere un umbral universal."))
}
mod_priority_server <- function(id,state,filters,catalog) shiny::moduleServer(id,function(input,output,session) {
  ranking<-shiny::reactive({f<-filters();district_priority(state(),catalog,f$year,f$month,f$units,as.numeric(input$slots %||% 3))})
  output$reading<-shiny::renderUI({
    x<-ranking();if(!nrow(x)) return(shiny::p("Sin datos Penta 3 para los distritos seleccionados."))
    if(anyNA(x$orden)) return(shiny::div(class="alert alert-warning","Orden pendiente: falta informacion o hay cifras que revisar. Complete los reportes Penta 1 y Penta 3 y la hoja contexto_territorial con fecha no posterior al cierre administrativo. No se asignan cupos mientras falten distritos por evaluar."))
    selected<-x[x$decision=="Intervencion intensiva",]
    shiny::tagList(shiny::p(shiny::strong(paste(nrow(selected),"distritos propuestos de",nrow(x),"evaluados"))),
      if(nrow(selected)) shiny::tags$ol(lapply(seq_len(nrow(selected)),function(i) shiny::tags$li(shiny::strong(selected$distrito[i]),": ",selected$justificacion[i]))) else shiny::p("Presupuesto sin cupos intensivos. Mantener seguimiento regular."),
      shiny::p("Los restantes distritos mantienen actividades regulares y seguimiento. La limitacion del presupuesto no elimina sus necesidades."))
  })
  mod_table_server("ranking",ranking)
  ranking
})
