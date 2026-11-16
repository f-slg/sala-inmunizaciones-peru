# Unit 02 reconstruction: real geographic codes, entirely invented health data.
unit02_dataset <- function() {
  d<-empty_dataset();codes<-sprintf("0903%02d",1:8)
  geo<-territory_catalog();d$territorios<-geo[match(codes,geo$ubigeo),];row.names(d$territorios)<-NULL
  d$configuracion<-data.frame(alumno="Estudiante - completar",ambito="Red simulada de ocho distritos - Unidad 02",anio=2026L,fecha_corte=as.Date("2026-12-31"),fuente="SIMULADO - reconstruccion del enunciado de Unidad 02; no es la base del aula virtual",version_datos="unidad02-2026-v1")
  denominator<-c(500,400,300,250,350,450,200,150)
  p1<-c(450,360,270,230,315,420,195,150)
  p2<-c(380,315,246,215,309,413,192,149)
  p3<-c(310,272,222,200,301,405,188,147)
  d$poblacion<-data.frame(anio=2026L,ubigeo=codes,grupo_id="M1",poblacion=denominator,fuente="SIMULADO - poblacion menor de un ano para el ejercicio",version="unidad02-v1")
  totals<-list(PENTA_1=p1,PENTA_2=p2,PENTA_3=p3)
  rows<-list();k<-0L
  for(rule in names(totals)) for(i in seq_along(codes)) {
    # Integer monthly increments preserve each annual total exactly.
    doses<-diff(floor(c(0,cumsum(c(8,7,9,8,9,8,8,9,8,9,8,9)))/100*totals[[rule]][i]))
    k<-k+1L;rows[[k]]<-data.frame(anio=2026L,mes=1:12,ubigeo=codes[i],regla_id=rule,estrategia="regular",dosis=doses,estado_reporte="completo")
  }
  d$vacunacion<-do.call(rbind,rows)
  d$contexto_territorial<-data.frame(anio=2026L,ubigeo=codes,
    poblacion_dispersa=c(FALSE,TRUE,TRUE,TRUE,FALSE,FALSE,FALSE,FALSE),
    dificil_acceso=c(FALSE,TRUE,TRUE,TRUE,FALSE,FALSE,FALSE,FALSE),
    ninos_padron=denominator,ninos_sin_seguimiento=c(150,48,45,35,21,126,10,6),
    alta_sin_seguimiento=c(TRUE,FALSE,FALSE,FALSE,FALSE,TRUE,FALSE,FALSE),
    brote_tosferina_ultimo_anio=c(FALSE,FALSE,FALSE,TRUE,FALSE,FALSE,FALSE,FALSE),
    fecha_corte=as.Date("2026-12-31"),fuente="SIMULADO - condiciones asignadas para cumplir el caso; alta es la clasificacion del enunciado",version="unidad02-v1")
  coerce_dataset(d)
}
