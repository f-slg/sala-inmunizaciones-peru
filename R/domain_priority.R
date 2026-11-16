priority_policy <- function() paste(
  "Propuesta pedagogica: primero antecedente de brote de tos ferina en el ultimo ano;",
  "despues menor cobertura Penta 3, mayor desercion Penta 1 - Penta 3, dificil acceso,",
  "mayor proporcion sin seguimiento y ubigeo como desempate.",
  "El orden se calcula dentro de los distritos seleccionados. No es una escala oficial.")
district_priority <- function(data,catalog=load_catalog(),year,month=12L,territories=NULL,slots=3L) {
  assert_number(slots,"cupos",min=0,integer=TRUE)
  c<-coverage_table(data,catalog,year,month,territories)
  if(!nrow(c)) return(data.frame())
  c<-c[c$regla_id=="PENTA_3",,drop=FALSE]
  if(!nrow(c)) return(data.frame())
  dropout<-dropout_table(coverage_table(data,catalog,year,month,territories),"PENTA_1","PENTA_3")
  c$desercion<-dropout$desercion[match(c$ubigeo,dropout$ubigeo)]
  c$semaforo_desercion<-dropout_status(c$desercion)
  end<-add_months(as.Date(sprintf("%04d-%02d-01",year,month)),1)-1
  context<-complete_optional_tables(data)$contexto_territorial
  context<-context[context$anio==year & context$fecha_corte<=end,,drop=FALSE]
  cols<-c("poblacion_dispersa","dificil_acceso","ninos_padron","ninos_sin_seguimiento","alta_sin_seguimiento","brote_tosferina_ultimo_anio")
  for(n in cols) c[[n]]<-context[[n]][match(c$ubigeo,context$ubigeo)]
  c$sin_seguimiento_pct<-safe_pct(c$ninos_sin_seguimiento,c$ninos_padron)
  complete<-is.finite(c$cobertura)&is.finite(c$desercion)&c$desercion>=0 & c$cobertura<=100
  for(n in cols) complete<-complete & !is.na(c[[n]])
  c$orden<-NA_integer_;c$decision<-"Pendiente de datos"
  # Missing districts must not silently change who receives the limited slots.
  if(all(complete)) {
    pos<-order(-as.integer(c$brote_tosferina_ultimo_anio),c$cobertura,-c$desercion,
      -as.integer(c$dificil_acceso),-c$sin_seguimiento_pct,c$ubigeo)
    c<-c[pos,,drop=FALSE];c$orden<-seq_len(nrow(c))
    c$decision<-ifelse(c$orden<=slots,"Intervencion intensiva","Seguimiento regular")
  }
  c$justificacion<-vapply(seq_len(nrow(c)),function(i) {
    if(!complete[i]) return("Completar o revisar coberturas, desercion y contexto territorial del corte")
    paste(c(if(isTRUE(c$brote_tosferina_ultimo_anio[i])) "Antecedente de brote de tos ferina",
      paste("Cobertura Penta 3:",fmt_pct(c$cobertura[i])),paste("Desercion:",fmt_pct(c$desercion[i])),
      if(isTRUE(c$poblacion_dispersa[i])) "Poblacion dispersa",if(isTRUE(c$dificil_acceso[i])) "Dificil acceso",
      paste("Sin seguimiento:",fmt_pct(c$sin_seguimiento_pct[i])),
      if(isTRUE(c$alta_sin_seguimiento[i])) "Alta falta de seguimiento segun el caso"),collapse="; ")
  },character(1))
  if(!all(complete)) c$decision<-"Pendiente de datos"
  c$criterio_orden<-priority_policy();row.names(c)<-NULL
  c[,c("orden","distrito","ubigeo","decision","cobertura","semaforo_cobertura","desercion","semaforo_desercion","brecha_95",cols,"sin_seguimiento_pct","justificacion","criterio_orden")]
}
