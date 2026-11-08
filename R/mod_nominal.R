mod_nominal_ui <- function(id,public=FALSE) {
  ns<-shiny::NS(id)
  if(public) return(shiny::div(class="alert alert-info","Seguimiento nominal no disponible en modo publico."))
  shiny::tagList(shiny::div(class="alert alert-info","Evaluacion educativa de reglas documentadas. Los casos especiales, transiciones e historias mixtas requieren revision. No genera indicaciones clinicas."),
    mod_table_ui(ns("summary"),"Cumplimiento por persona","Completo solo si todas las dosis evaluadas son validas y ninguna requiere revision."),
    mod_table_ui(ns("opportunity"),"Oportunidad de dosis evaluables","Se excluyen dosis invalidas y las que requieren informacion horaria o evaluacion clinica."),
    mod_table_ui(ns("events"),"Dosis exigibles al corte"),mod_table_ui(ns("needs"),"Dosis pendientes nominales","No incluye dosis fuera de edad ni casos en revision. No sumar nuevamente a una programacion que ya los incluya."))
}
mod_nominal_server <- function(id,assessment,public=FALSE) shiny::moduleServer(id,function(input,output,session) {
  if(public) return(invisible(NULL))
  mod_table_server("summary",shiny::reactive(nominal_summary(assessment())))
  mod_table_server("opportunity",shiny::reactive(opportunity_table(assessment())))
  mod_table_server("events",assessment)
  mod_table_server("needs",shiny::reactive(nominal_dose_needs(assessment())))
})
