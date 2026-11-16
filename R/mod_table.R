# Shared component for consistent accessible tables across modules.
module_card <- function(title,...) bslib::card(bslib::card_header(title),...)
data_table <- function(x) {
  if(!is.data.frame(x)||!ncol(x)||!nrow(x)) return(DT::datatable(data.frame(Estado="Sin datos para esta seleccion"),rownames=FALSE,options=list(dom="t")))
  labels<-c(cobertura="Cobertura (%)",desercion="Desercion (%)",sin_seguimiento_pct="Sin seguimiento (%)",brecha_95="Dosis faltantes a 95 %",reporte_completo="Reporte completo",ninos_padron="Ninos en padron",ninos_sin_seguimiento="Ninos sin seguimiento",alta_sin_seguimiento="Alta falta de seguimiento (fuente)",brote_tosferina_ultimo_anio="Brote de tos ferina en ultimo ano",semaforo_cobertura="Estado de cobertura",semaforo_desercion="Estado de desercion")
  headings<-vapply(names(x),function(n) if(n %in% names(labels)) labels[[n]] else gsub("_"," ",n),character(1))
  table<-DT::datatable(x,rownames=FALSE,escape=TRUE,filter="top",colnames=unname(headings),extensions="Buttons",
    options=list(pageLength=10,scrollX=TRUE,dom="tip",language=list(
      search="Buscar:",lengthMenu="Mostrar _MENU_ filas",info="_START_ a _END_ de _TOTAL_ registros",infoEmpty="Sin registros",zeroRecords="Sin coincidencias",
      paginate=list(first="Primero",last="Ultimo",`next`="Siguiente",previous="Anterior"))))
  palette<-status_palette()
  for(n in intersect(names(x),c("semaforo_cobertura","semaforo_desercion","estado","nivel","decision"))) table<-DT::formatStyle(table,n,backgroundColor=DT::styleEqual(names(palette),unname(palette)),color="#17233B",fontWeight="600")
  for(n in intersect(names(x),c("riesgo_quiebre","excede_capacidad","alta_sin_seguimiento","brote_tosferina_ultimo_anio"))) table<-DT::formatStyle(table,n,backgroundColor=DT::styleEqual(c(TRUE,FALSE),c("#FCE8E6","#E1F3E9")))
  for(n in intersect(names(x),c("reporte_completo"))) table<-DT::formatStyle(table,n,backgroundColor=DT::styleEqual(c(TRUE,FALSE),c("#E1F3E9","#EDF0F4")))
  percentages<-intersect(names(x),c("cobertura","desercion","sin_seguimiento_pct","oportunidad"))
  if(length(percentages)) table<-DT::formatRound(table,percentages,digits=1,mark=" ",dec.mark=",")
  table
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
