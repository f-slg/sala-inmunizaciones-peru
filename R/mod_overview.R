mod_overview_ui <- function(id) {
  ns<-shiny::NS(id)
  shiny::tagList(shiny::uiOutput(ns("cards")),module_card("Lectura del corte",shiny::uiOutput(ns("reading"))),
    mod_table_ui(ns("priority"),"Priorizacion territorial","Brecha administrativa de dosis para alcanzar 95 %. No equivale a personas nominalmente identificadas."))
}
mod_overview_server <- function(id,coverage,requirements,filters,state) shiny::moduleServer(id,function(input,output,session) {
  selected<-shiny::reactive({x<-coverage();if(!nrow(x)) return(x);x[x$regla_id==filters()$rule,,drop=FALSE]})
  output$cards<-shiny::renderUI({
    x<-selected();shiny::validate(shiny::need(nrow(x),"Seleccione territorios con datos"))
    s<-coverage_summary(x);q<-requirements()
    bslib::layout_columns(col_widths=c(3,3,3,3),
      bslib::value_box("Cobertura del ambito",fmt_pct(s$cobertura),theme="primary"),
      bslib::value_box("Brecha a 95 %",if(anyNA(x$brecha_95)) "Sin dato" else format(sum(x$brecha_95),big.mark=" "),theme="secondary"),
      bslib::value_box("Distritos con reporte completo",paste(sum(x$reporte_completo),"/",nrow(x)),theme="info"),
      bslib::value_box("Productos con riesgo de quiebre",if(nrow(q)) sum(q$riesgo_quiebre) else "Sin datos",theme="warning"))
  })
  output$reading<-shiny::renderUI({
    x<-selected();if(!nrow(x)) return(shiny::p("Sin datos"));f<-filters();s<-coverage_summary(x)
    shiny::tagList(shiny::p(sprintf("%s \u00b7 %s \u00b7 cierre %02d/%d. Cobertura: %s.",state()$configuracion$ambito[1],f$rule,f$month,f$year,fmt_pct(s$cobertura))),
      shiny::p("La cobertura agregada se calcula con la suma de numeradores y denominadores de la misma regla, sin promediar porcentajes distritales."),
      if(any(x$cobertura>100,na.rm=TRUE)) shiny::div(class="alert alert-warning","Hay coberturas mayores a 100 %: revisar residencia, numeradores y denominadores."),
      if(any(!x$reporte_completo)) shiny::div(class="alert alert-warning","Reporte incompleto: el sistema mantiene resultados ausentes y no los convierte en cero."))
  })
  mod_table_server("priority",shiny::reactive({x<-selected();if(nrow(x)) x<-x[order(-x$brecha_95,na.last=TRUE),];x}))
})
