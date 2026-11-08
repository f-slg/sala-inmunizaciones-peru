mod_map_ui <- function(id) {
  ns<-shiny::NS(id)
  shiny::tagList(module_card("Mapa interactivo del Peru \u00b7 distritos INEI",
    bslib::layout_columns(shiny::selectInput(ns("indicator"),"Indicador",c("Cobertura (%)"="cobertura","Brecha a 95 %"="brecha_95")),
      shiny::checkboxInput(ns("tiles"),"Mostrar fondo OpenStreetMap (requiere internet)",FALSE)),
    shiny::uiOutput(ns("notice")),leaflet::leafletOutput(ns("map"),height="620px"),shiny::uiOutput(ns("selection")),
    shiny::p(class="small text-muted","Geometria real: mapsPERU 2.0.1, limites distritales INEI. Zoom, desplazamiento, seleccion y fichas emergentes. Las cifras de demostracion son simuladas.")))
}
mod_map_server <- function(id,coverage,filters) shiny::moduleServer(id,function(input,output,session) {
  x<-shiny::reactive({z<-coverage();if(nrow(z)) z<-z[z$regla_id==filters()$rule,,drop=FALSE];z})
  output$map<-leaflet::renderLeaflet({z<-x();shiny::validate(shiny::need(nrow(z),"Sin datos para el mapa"));build_leaflet(z,input$indicator %||% "cobertura",isTRUE(input$tiles))})
  output$notice<-shiny::renderUI({z<-x();if(!nrow(z)) return(NULL);m<-map_join(z)$sin_geometria
    if(length(m)) shiny::div(class="alert alert-warning",paste("Sin geometria en esta version:",paste(m,collapse=", "))) else shiny::p("Todos los ubigeos seleccionados tienen geometria real.")})
  output$selection<-shiny::renderUI({click<-input$map_shape_click;if(is.null(click)) return(shiny::p("Pulse un distrito para inspeccionar su ficha."));z<-x();z<-z[z$ubigeo==click$id,,drop=FALSE];if(!nrow(z)) return(NULL);shiny::p(sprintf("Seleccion: %s (%s) \u00b7 %s",z$distrito[1],z$ubigeo[1],fmt_pct(z$cobertura[1])))})
})
