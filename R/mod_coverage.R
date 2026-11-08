mod_coverage_ui <- function(id) {
  ns<-shiny::NS(id)
  shiny::tagList(module_card("Cobertura por distrito",shiny::plotOutput(ns("plot"),height="420px")),
    mod_table_ui(ns("table"),"Indicadores administrativos","Desagregacion por regla. No sumar coberturas de diferentes dosis o grupos."))
}
mod_coverage_server <- function(id,coverage,filters) shiny::moduleServer(id,function(input,output,session) {
  selected<-shiny::reactive({x<-coverage();if(nrow(x)) x<-x[x$regla_id==filters()$rule,];x})
  output$plot<-shiny::renderPlot({
    x<-selected();if(!nrow(x)) return(plot_empty())
    ggplot2::ggplot(x,ggplot2::aes(x=stats::reorder(distrito,cobertura),y=cobertura,fill=alerta))+
      ggplot2::geom_col(width=.65,na.rm=TRUE)+ggplot2::geom_hline(yintercept=95,linetype="dashed",colour="#542583")+
      ggplot2::coord_flip()+ggplot2::scale_fill_manual(values=c("Meta alcanzada"="#20836E","Bajo la meta"="#C85565","Reporte incompleto"="#CBD5E1","Revisar numerador y denominador"="#DDA74A","Sin denominador"="#CBD5E1"))+
      ggplot2::labs(x=NULL,y="Cobertura (%)",fill=NULL,title=filters()$rule)+sala_theme()
  })
  mod_table_server("table",coverage)
})
