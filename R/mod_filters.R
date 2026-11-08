mod_filters_ui <- function(id) {
  ns<-shiny::NS(id)
  shiny::tagList(shiny::selectInput(ns("year"),"A\u00f1o",choices=NULL),shiny::sliderInput(ns("month"),"Mes de cierre",min=1,max=12,value=10,step=1),
    shiny::selectInput(ns("units"),"Distritos",choices=NULL,multiple=TRUE),shiny::selectInput(ns("rule"),"Vacuna y dosis",choices=NULL),
    shiny::dateInput(ns("cutoff"),"Corte nominal / inventario",value=as.Date("2026-11-08"),format="yyyy-mm-dd",language="es"),
    shiny::p(class="small text-muted","Coberturas: vacunacion regular. El ultimo mes debe estar cerrado. La fecha nominal es independiente del periodo administrativo."))
}
mod_filters_server <- function(id,state,catalog) shiny::moduleServer(id,function(input,output,session) {
  previous_choices<-NULL
  shiny::observeEvent(state(),{
    d<-state()
    choices<-list(anios=sort(unique(d$poblacion$anio)),territorios=d$territorios,
                  reglas=sort(unique(d$vacunacion$regla_id)),corte=d$configuracion$fecha_corte)
    if(identical(choices,previous_choices)) return()
    previous_choices<<-choices
    years<-sort(unique(d$poblacion$anio),decreasing=TRUE)
    shiny::updateSelectInput(session,"year",choices=years,selected=as.character(d$configuracion$anio[1]))
    units<-stats::setNames(d$territorios$ubigeo,paste(d$territorios$distrito,d$territorios$ubigeo))
    shiny::updateSelectInput(session,"units",choices=units,selected=unname(units))
    ids<-unique(d$vacunacion$regla_id);r<-catalog$reglas[match(ids,catalog$reglas$regla_id),]
    labels<-paste(r$regla_id,"\u00b7",catalog$productos$nombre[match(r$producto_id,catalog$productos$producto_id)])
    shiny::updateSelectInput(session,"rule",choices=stats::setNames(ids,labels),selected=if("PCV_3" %in% ids) "PCV_3" else ids[1])
    shiny::updateDateInput(session,"cutoff",value=d$configuracion$fecha_corte[1])
  },ignoreNULL=FALSE)
  shiny::reactive({shiny::req(input$year,input$rule,input$cutoff)
    list(year=as.integer(input$year),month=as.integer(input$month),units=input$units %||% character(),rule=input$rule,cutoff=as.Date(input$cutoff))})
})
