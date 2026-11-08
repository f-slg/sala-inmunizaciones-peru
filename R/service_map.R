# mapsPERU supplies genuine Peruvian boundaries; leaflet provides interactivity.
# No geometrical reassignment of fictional territories is performed.
peru_boundaries <- local({
  cache<-NULL
  function() {
    if(!is.null(cache)) return(cache)
    x<-mapsPERU::map_DIST
    x<-sf::st_as_sf(x)
    if(is.na(sf::st_crs(x))) stop("La cartografia no tiene sistema de coordenadas documentado")
    x<-sf::st_transform(x,4326)
    x$ubigeo<-as.character(x$COD_DISTRITO)
    x<-x[,c("ubigeo","DISTRITO","PROVINCIA","DEPARTAMENTO")]
    # One feature per real INEI district. Geometries stay on the user's machine.
    cache<<-x;x
  }
})
map_join <- function(table,boundaries=peru_boundaries()) {
  if(anyDuplicated(table$ubigeo)) stop("Seleccionar una sola regla antes de mapear",call.=FALSE)
  missing<-setdiff(table$ubigeo,boundaries$ubigeo)
  x<-boundaries[boundaries$ubigeo %in% table$ubigeo,]
  idx<-match(x$ubigeo,table$ubigeo)
  for(n in setdiff(names(table),names(x))) x[[n]]<-table[[n]][idx]
  list(geometria=x,sin_geometria=missing,fuente=paste("mapsPERU",utils::packageVersion("mapsPERU"),"- limites distritales INEI; validar distritos de creacion posterior"))
}
build_leaflet <- function(table,indicator="cobertura",tiles=FALSE) {
  joined<-map_join(table);x<-joined$geometria
  map<-leaflet::leaflet(options=leaflet::leafletOptions(minZoom=4,maxZoom=17))
  if(isTRUE(tiles)) map<-leaflet::addProviderTiles(map,"OpenStreetMap",options=leaflet::providerTileOptions(noWrap=TRUE))
  if(!nrow(x)) return(leaflet::setView(map,lng=-75,lat=-9,zoom=5))
  values<-x[[indicator]]
  if(is.null(values)) stop("Indicador cartografico desconocido")
  if(all(is.na(values))) {
    domain<-c(0,100)
  } else domain<-range(values,na.rm=TRUE)
  pal<-leaflet::colorNumeric(c("#BE4055","#E3AE49","#20836E"),domain=domain,na.color="#CBD5E1")
  if(indicator=="brecha_95") pal<-leaflet::colorNumeric(c("#E9E2F2","#542583"),domain=domain,na.color="#CBD5E1")
  esc<-function(z) as.character(htmltools::htmlEscape(as.character(z)))
  popup<-paste0("<strong>",esc(x$DISTRITO),"</strong><br>Ubigeo INEI: ",esc(x$ubigeo),
    "<br>Cobertura: ",fmt_pct(x$cobertura),"<br>Dosis: ",esc(x$dosis),"<br>Poblacion: ",esc(x$denominador),
    "<br>Brecha a 95 %: ",esc(x$brecha_95),"<br>",esc(x$alerta))
  if(indicator=="cobertura") {
    categories<-c("Baja (<80 %)","Intermedia (80 a <95 %)","Meta (95 a 100 %)","Revisar (>100 %)","Sin dato")
    colors<-c("#BE4055","#E3AE49","#20836E","#537DA0","#CBD5E1")
    status<-ifelse(is.na(values),"Sin dato",ifelse(values<80,categories[1],ifelse(values<95,categories[2],ifelse(values<=100,categories[3],categories[4]))))
    fill<-colors[match(status,categories)]
  } else fill<-pal(values)
  map<-leaflet::addPolygons(map,data=x,layerId=x$ubigeo,fillColor=fill,fillOpacity=.8,color="#FFFFFF",weight=1.5,
    label=x$DISTRITO,popup=popup,highlightOptions=leaflet::highlightOptions(weight=3,color="#222B45",bringToFront=TRUE))
  if(indicator=="cobertura") map<-leaflet::addLegend(map,"bottomright",colors=colors,labels=categories,title="Cobertura (%)",opacity=1)
  else map<-leaflet::addLegend(map,"bottomright",pal=pal,values=values,title="Dosis pendientes a meta",opacity=1)
  bbox<-sf::st_bbox(x)
  leaflet::fitBounds(map,bbox[["xmin"]],bbox[["ymin"]],bbox[["xmax"]],bbox[["ymax"]])
}
