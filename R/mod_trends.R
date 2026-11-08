mod_trends_ui <- function(id) {
  ns<-shiny::NS(id)
  shiny::tagList(module_card("Dosis mensuales y continuidad del reporte",shiny::plotOutput(ns("plot"),height="360px")),
    mod_table_ui(ns("monthly"),"Serie mensual","Los reportes ausentes interrumpen el acumulado; no se imputan."),
    module_card("Desercion administrativa",shiny::selectInput(ns("pair"),"Par comparable",choices=c("Pentavalente 1 a 3"="penta","Hexavalente 1 a 3"="hexa","SPR 1 a 2"="spr")),
      shiny::p("Los agregados describen desempeno del programa; no identifican abandono individual. Una desercion negativa requiere revisar comparabilidad."),DT::DTOutput(ns("dropout"))))
}
mod_trends_server <- function(id,state,coverage,filters) shiny::moduleServer(id,function(input,output,session) {
  monthly<-shiny::reactive({f<-filters();monthly_trend(state(),f$rule,f$year,f$units)})
  output$plot<-shiny::renderPlot({x<-monthly();ggplot2::ggplot(x,ggplot2::aes(mes,dosis))+ggplot2::geom_line(colour="#542583",linewidth=1,na.rm=TRUE)+ggplot2::geom_point(colour="#20836E",size=2,na.rm=TRUE)+ggplot2::scale_x_continuous(breaks=1:12)+ggplot2::labs(x="Mes",y="Dosis",title=filters()$rule)+sala_theme()})
  mod_table_server("monthly",monthly)
  output$dropout<-DT::renderDT({pair<-switch(input$pair %||% "penta",penta=c("PENTA_1","PENTA_3"),hexa=c("HEXA_1","HEXA_3"),spr=c("SPR_1","SPR_2"));data_table(dropout_table(coverage(),pair[1],pair[2]))})
})
