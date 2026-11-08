small_nominal <- function() {
  d<-empty_dataset()
  d$configuracion<-data.frame(alumno="A",ambito="Prueba",anio=2026,fecha_corte=as.Date("2027-04-11"),fuente="SIMULADO",version_datos="test")
  d$territorios<-data.frame(ubigeo="090301",distrito="Lircay",provincia="Angaraes",departamento="Huancavelica")
  d$personas<-data.frame(persona_id="P1",ubigeo="090301",fecha_nacimiento=as.Date("2027-01-01"),sexo="F",ruta_id="penta_ipv")
  coerce_dataset(d)
}
add_event <- function(d,product,dose,date,id="E1") {
  d$eventos<-rbind(d$eventos,data.frame(evento_id=id,persona_id="P1",producto_id=product,dosis_id=dose,fecha=as.Date(date),lote="L1",episodio_id="general"));d
}
