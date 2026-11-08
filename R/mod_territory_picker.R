mod_territory_picker_ui <- function(id) {
  ns<-shiny::NS(id)
  module_card("Seleccione su territorio en el Peru",
    shiny::p("Elija departamento, provincia y distritos. Puede agregar territorios de distintas provincias a su seleccion. Solo se precargan nombres y ubigeos; nunca poblaciones ni dosis."),
    bslib::layout_columns(shiny::selectInput(ns("department"),"Departamento",choices=NULL),
      shiny::selectInput(ns("province"),"Provincia",choices=NULL),
      shiny::selectizeInput(ns("districts"),"Distritos",choices=NULL,multiple=TRUE)),
    shiny::checkboxInput(ns("all"),"Incluir todos los distritos de esta provincia",FALSE),
    shiny::actionButton(ns("add"),"Agregar a mi seleccion",class="btn-primary"),
    shiny::actionButton(ns("clear"),"Limpiar seleccion"),
    mod_table_ui(ns("selected"),"Distritos elegidos"),
    leaflet::leafletOutput(ns("preview"),height="320px"),
    shiny::downloadButton(ns("scope_template"),"Plantilla integral de mi territorio"),
    shiny::downloadButton(ns("scope_population"),"Poblacion de mi territorio"),
    shiny::p(class="small text-muted","Catalogo cartografico mapsPERU 2.0.1 / INEI: 1891 distritos. No es un directorio territorial actualizado en linea. Para distritos ausentes conserve el ubigeo real; la app notificara si falta geometria."))
}
mod_territory_picker_server <- function(id) shiny::moduleServer(id,function(input,output,session) {
  geography<-territory_catalog()
  chosen<-shiny::reactiveVal(geography[FALSE,,drop=FALSE])
  shiny::updateSelectInput(session,"department",choices=c("Seleccione un departamento"="",sort(unique(geography$departamento))),selected="")
  shiny::observeEvent(input$department,{
    x<-geography[geography$departamento==input$department,,drop=FALSE]
    shiny::updateSelectInput(session,"province",choices=c("Seleccione una provincia"="",sort(unique(x$provincia))),selected="")
    shiny::updateSelectizeInput(session,"districts",choices=character(),selected=character(),server=TRUE)
    shiny::updateCheckboxInput(session,"all",value=FALSE)
  },ignoreNULL=FALSE)
  available<-shiny::reactive({
    shiny::req(input$department,input$province)
    geography[geography$departamento==input$department & geography$provincia==input$province,,drop=FALSE]
  })
  shiny::observeEvent(input$province,{
    shiny::req(input$department,input$province)
    x<-available()
    shiny::updateSelectizeInput(session,"districts",choices=stats::setNames(x$ubigeo,paste(x$distrito,x$ubigeo,sep=" - ")),selected=character(),server=TRUE)
    shiny::updateCheckboxInput(session,"all",value=FALSE)
  })
  shiny::observeEvent(input$add,{
    x<-available()
    if(!isTRUE(input$all)) x<-x[x$ubigeo %in% input$districts,,drop=FALSE]
    if(!nrow(x)) {shiny::showNotification("Seleccione al menos un distrito",type="warning");return()}
    x<-rbind(chosen(),x);x<-x[!duplicated(x$ubigeo),,drop=FALSE];row.names(x)<-NULL;chosen(x)
  })
  shiny::observeEvent(input$clear,{chosen(geography[FALSE,,drop=FALSE])})
  mod_table_server("selected",chosen)
  output$preview<-leaflet::renderLeaflet({
    x<-chosen();map<-leaflet::leaflet()
    country<-sf::st_transform(sf::st_as_sf(mapsPERU::map_DEP),4326)
    map<-leaflet::addPolygons(map,data=country,color="#B7BEC9",weight=.6,fillColor="#EEF0F4",fillOpacity=.75,label=as.character(country$DEPARTAMENTO),group="Departamentos")
    if(!nrow(x)) return(leaflet::setView(map,lng=-75,lat=-9,zoom=5))
    boundary<-peru_boundaries();boundary<-boundary[boundary$ubigeo %in% x$ubigeo,]
    map<-leaflet::addPolygons(map,data=boundary,layerId=boundary$ubigeo,color="#542583",weight=2,fillColor="#A891BF",fillOpacity=.5,label=boundary$DISTRITO,
      popup=paste0(htmltools::htmlEscape(boundary$DISTRITO),"<br>Ubigeo: ",boundary$ubigeo,"<br>Vista territorial: sin indicadores sanitarios"))
    centres<-mapsPERU::map_DIST
    centres<-centres[match(boundary$ubigeo,as.character(centres$COD_DISTRITO)),]
    map<-leaflet::addCircleMarkers(map,lng=centres$coords_x,lat=centres$coords_y,radius=5,
      color="#FFFFFF",weight=1,fillColor="#542583",fillOpacity=1,label=boundary$DISTRITO,
      group="Centros de distritos",popup=paste0(htmltools::htmlEscape(boundary$DISTRITO)," - ",boundary$ubigeo))
    box<-sf::st_bbox(boundary);leaflet::fitBounds(map,box[["xmin"]],box[["ymin"]],box[["xmax"]],box[["ymax"]])
  })
  output$scope_template<-shiny::downloadHandler(filename=function() "Plantilla_de_mi_territorio.xlsx",content=function(file) {
    shiny::req(nrow(chosen())>0);write_template(file,territories=chosen())
  })
  output$scope_population<-shiny::downloadHandler(filename=function() "Poblacion_de_mi_territorio.xlsx",content=function(file) {
    shiny::req(nrow(chosen())>0);write_population_template(file,territories=chosen())
  })
  chosen
})
