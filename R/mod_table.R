# Shared component for consistent accessible tables across modules.
module_card <- function(title,...) bslib::card(bslib::card_header(title),...)
data_table <- function(x) {
  if(!is.data.frame(x)||!ncol(x)||!nrow(x)) return(DT::datatable(data.frame(Estado="Sin datos para esta seleccion"),rownames=FALSE,options=list(dom="t")))
  DT::datatable(x,rownames=FALSE,escape=TRUE,filter="top",extensions="Buttons",
    options=list(pageLength=10,scrollX=TRUE,dom="tip",language=list(
      search="Buscar:",lengthMenu="Mostrar _MENU_ filas",info="_START_ a _END_ de _TOTAL_ registros",infoEmpty="Sin registros",zeroRecords="Sin coincidencias",
      paginate=list(first="Primero",last="Ultimo",`next`="Siguiente",previous="Anterior"))))
}
mod_table_ui <- function(id,title,description=NULL) {
  ns<-shiny::NS(id)
  module_card(title,shiny::p(class="module-description",description),DT::DTOutput(ns("table")))
}
mod_table_server <- function(id,data) shiny::moduleServer(id,function(input,output,session) {
  output$table<-DT::renderDT(data_table(data()),server=TRUE)
})
plot_empty <- function(message="Sin datos para esta seleccion") ggplot2::ggplot()+ggplot2::annotate("text",x=0,y=0,label=message,size=5)+ggplot2::theme_void()
sala_theme <- function() ggplot2::theme_minimal(base_size=12)+ggplot2::theme(panel.grid.minor=ggplot2::element_blank(),plot.title=ggplot2::element_text(face="bold",colour="#27213B"),axis.title=ggplot2::element_text(colour="#64748B"))
