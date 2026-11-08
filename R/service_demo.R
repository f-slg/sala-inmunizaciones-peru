# Demonstration has REAL INEI territories and exclusively SIMULATED health data.
demo_dataset <- function(catalog=load_catalog()) {
  d<-empty_dataset();year<-2026L;cutoff<-as.Date("2026-11-08")
  d$configuracion<-data.frame(alumno="Estudiante de demostracion",ambito="Angaraes - ejercicio simulado",anio=year,fecha_corte=cutoff,fuente="SIMULADO - no representa situacion sanitaria real",version_datos="demo-0.1.0")
  d$territorios<-data.frame(ubigeo=c("090301","090302","090303"),distrito=c("Lircay","Anchonga","Callanmarca"),provincia="Angaraes",departamento="Huancavelica")
  d$poblacion<-expand.grid(anio=year,ubigeo=d$territorios$ubigeo,grupo_id=catalog$grupos$grupo_id,stringsAsFactors=FALSE)
  d$poblacion$poblacion<-rep(c(120L,85L,65L),length.out=nrow(d$poblacion))
  d$poblacion$fuente<-"SIMULADO - denominadores educativos";d$poblacion$version<-"demo-2026"
  rules<-catalog$reglas
  # All products appear in the pedagogical data. Alternative routes/eligibility
  # are independent example cells and MUST NOT be totalled as unique people.
  d$vacunacion<-expand.grid(anio=year,mes=1:12,ubigeo=d$territorios$ubigeo,regla_id=rules$regla_id,stringsAsFactors=FALSE)
  d$vacunacion$estrategia<-"regular"
  idx<-match(d$vacunacion$ubigeo,d$territorios$ubigeo)
  d$vacunacion$dosis<-pmax(0L,as.integer(c(9,5,3)[idx]+(d$vacunacion$mes%%3)-1))
  d$vacunacion$estado_reporte<-ifelse(d$vacunacion$mes<=10,"completo","pendiente")
  d$vacunacion$dosis[d$vacunacion$mes>10]<-NA_real_
  # Named IDs are invented, without names, DNI or contact information.
  d$personas<-data.frame(persona_id=sprintf("SIM-%04d",1:45),ubigeo=rep(d$territorios$ubigeo,each=15),
    fecha_nacimiento=as.Date("2025-01-15")+seq(0,by=11,length.out=45),sexo=rep(c("F","M","F"),15),ruta_id="penta_ipv")
  ee<-list();k<-0L
  rr<-rules[rules$estado=="verificada" & rules$ruta_id %in% c("todas","penta_ipv") & rules$elegibilidad=="edad",]
  for(i in seq_len(nrow(d$personas))) for(j in seq_len(nrow(rr))) {
    r<-rr[j,];date<-add_months(d$personas$fecha_nacimiento[i],r$edad_objetivo_meses)
    # Every seventh child illustrates missed appointments.
    if(date<=cutoff && !(i%%7==0 && r$edad_objetivo_meses>=4)) {
      k<-k+1L;ee[[k]]<-data.frame(evento_id=paste0("EV-",k),persona_id=d$personas$persona_id[i],producto_id=r$producto_id,dosis_id=r$dosis_id,fecha=date,lote="DEMO",episodio_id="general")
    }
  }
  d$eventos<-do.call(rbind,ee)
  reviewed<-rules[rules$estado=="verificada" & rules$ruta_id %in% c("todas","penta_ipv"),]
  extra<-rules[!rules$producto_id %in% reviewed$producto_id,];extra<-extra[!duplicated(extra$producto_id),]
  pr<-rbind(reviewed,extra)
  d$programacion<-expand.grid(anio=year,ubigeo=d$territorios$ubigeo,regla_id=pr$regla_id,stringsAsFactors=FALSE)
  d$programacion$poblacion_elegible<-100;d$programacion$meta<-.95;d$programacion$recuperacion<-5
  d$programacion$perdida<-.1;d$programacion$reserva_dosis<-20;d$programacion$transito_dosis<-0
  d$programacion$dias_horizonte<-365;d$programacion$dias_reposicion<-30
  d$programacion$fuente<-"SIMULADO - revisar elegibilidad y no duplicar alternativas"
  d$inventario<-expand.grid(ubigeo=d$territorios$ubigeo,producto_id=catalog$productos$producto_id,stringsAsFactors=FALSE)
  d$inventario$lote<-"SIM-2026";d$inventario$fecha_saldo<-as.Date("2026-01-01");d$inventario$vencimiento<-as.Date("2028-01-01");d$inventario$saldo_dosis<-40;d$inventario$cuarentena<-FALSE
  d$presentaciones<-data.frame(producto_id=catalog$productos$producto_id,dosis_frasco=1,volumen_cm3_dosis=5,
    jeringas_dosis=ifelse(catalog$productos$via=="ORAL",0,1),diluyentes_frasco=0,jeringas_reconstitucion_frasco=0,capacidad_caja=100,
    fuente="SIMULADO - sustituir por ficha de presentacion real")
  d$consumo<-expand.grid(anio=2026,mes=5:10,ubigeo=d$territorios$ubigeo,producto_id=catalog$productos$producto_id,stringsAsFactors=FALSE)
  d$consumo$dosis_consumidas<-12;d$consumo$dias_observados<-30;d$consumo$dias_sin_stock<-0;d$consumo$reporte_completo<-TRUE
  d$cadena_frio<-data.frame(ubigeo=d$territorios$ubigeo,capacidad_litros=100,ocupacion_otros_litros=20,fuente="SIMULADO")
  d$plan_mejora<-data.frame(accion_id="ACC-001",ubigeo="090303",problema="Brecha de acceso",evidencia="SIMULADO: cobertura menor a meta",accion="Visitas extramurales y seguimiento semanal",responsable="Estudiante",fecha_limite=as.Date("2026-12-15"),indicador="Cobertura PCV_3",meta="95 %",avance=0)
  coerce_dataset(d)
}
