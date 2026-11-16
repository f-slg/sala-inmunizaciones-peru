mod_coverage_ui <- function(id) {
  ns<-shiny::NS(id)
  shiny::tagList(module_card("Cobertura por distrito",shiny::p("Rojo: <80 %. Amarillo: 80 a <95 %. Verde: 95 a 100 %. Azul: >100 %, revisar datos. Gris: sin reporte o denominador. Cortes de visualizacion educativa."),shiny::plotOutput(ns("plot"),height="420px")),
    mod_table_ui(ns("table"),"Indicadores administrativos","Desagregacion por regla. No sumar coberturas de diferentes dosis o grupos."))
}
mod_coverage_server <- function(id,coverage,filters) shiny::moduleServer(id,function(input,output,session) {
  selected<-shiny::reactive({x<-coverage();if(nrow(x)) x<-x[x$regla_id==filters()$rule,];x})
  output$plot<-shiny::renderPlot({
    x<-selected();if(!nrow(x)) return(plot_empty())
    ggplot2::ggplot(x,ggplot2::aes(x=stats::reorder(distrito,cobertura),y=cobertura,fill=semaforo_cobertura))+
      ggplot2::geom_col(width=.65,na.rm=TRUE)+ggplot2::geom_hline(yintercept=95,linetype="dashed",colour="#542583")+
      ggplot2::coord_flip()+ggplot2::scale_fill_manual(values=c("Meta alcanzada"="#20836E","Baja cobertura"="#BE4055","En alerta"="#B67B08","Revisar datos"="#537DA0","Sin dato"="#CBD5E1"))+
      ggplot2::labs(x=NULL,y="Cobertura (%)",fill=NULL,title=filters()$rule)+sala_theme()
  })
  mod_table_server("table",coverage)
})
