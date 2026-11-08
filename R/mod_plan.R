mod_plan_ui <- function(id,public=FALSE) {
  ns<-shiny::NS(id)
  shiny::tagList(module_card("Plan de mejora y microplanificacion",
    shiny::p("Documente evidencia, intervencion, responsable, plazo y meta verificable. El avance va de 0 a 100. Los cambios se conservan durante la sesion y pueden exportarse."),
    if(!public) shiny::tagList(
      bslib::layout_columns(shiny::textInput(ns("problem"),"Problema"),shiny::textInput(ns("evidence"),"Evidencia")),
      shiny::textAreaInput(ns("action"),"Intervencion",width="100%"),
      bslib::layout_columns(shiny::selectInput(ns("unit"),"Distrito",NULL),shiny::textInput(ns("owner"),"Responsable"),shiny::dateInput(ns("due"),"Fecha limite",value=Sys.Date()+30)),
      bslib::layout_columns(shiny::textInput(ns("indicator"),"Indicador de seguimiento"),shiny::textInput(ns("target"),"Meta")),
      shiny::actionButton(ns("add"),"Agregar accion",class="btn-primary")),DT::DTOutput(ns("table"))))
}
mod_plan_server <- function(id,state,public=FALSE) shiny::moduleServer(id,function(input,output,session) {
  shiny::observe({x<-state()$territorios;shiny::updateSelectInput(session,"unit",choices=stats::setNames(x$ubigeo,x$distrito))})
  shiny::observeEvent(input$add,{
    shiny::req(!public,input$problem,input$action,input$owner,input$indicator,input$target,input$unit,input$due)
    d<-state();new<-data.frame(accion_id=paste0("ACC-",format(Sys.time(),"%Y%m%d%H%M%OS6")),ubigeo=input$unit,problema=input$problem,evidencia=input$evidence,accion=input$action,responsable=input$owner,fecha_limite=as.Date(input$due),indicador=input$indicator,meta=input$target,avance=0)
    d$plan_mejora<-rbind(d$plan_mejora,new);state(d);shiny::showNotification("Accion agregada",type="message")
  })
  output$table<-DT::renderDT(data_table(state()$plan_mejora))
})
