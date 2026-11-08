# Administrative indicators retain report completeness; absence is never zero.
coverage_table <- function(data, catalog=load_catalog(), year, month=12L, territories=NULL, strategies="regular") {
  v<-data$vacunacion
  v<-v[v$anio==year & v$mes<=month & v$estrategia %in% strategies, ,drop=FALSE]
  if (!is.null(territories)) v<-v[v$ubigeo %in% territories,,drop=FALSE]
  if (!nrow(v)) return(data.frame())
  parts<-split(v,paste(v$ubigeo,v$regla_id,sep="::"))
  out<-lapply(parts,function(x) {
    rule<-catalog$reglas[match(x$regla_id[1],catalog$reglas$regla_id),]
    p<-data$poblacion
    den<-p$poblacion[p$anio==year & p$ubigeo==x$ubigeo[1] & p$grupo_id==rule$grupo_id]
    if (length(den)>1L) stop("Denominador duplicado",call.=FALSE)
    den<-if(length(den)) den else NA_real_
    complete<-all(x$estado_reporte=="completo") && all(is.finite(x$dosis)) && length(unique(x$mes))==month
    doses<-if (complete) sum(x$dosis) else NA_real_
    cob<-safe_pct(doses,den)
    data.frame(anio=year,mes_corte=month,ubigeo=x$ubigeo[1],regla_id=rule$regla_id,producto_id=rule$producto_id,
      grupo_id=rule$grupo_id,dosis=doses,denominador=den,cobertura=cob,
      meses_reportados=length(unique(x$mes[x$estado_reporte=="completo"])),
      reporte_completo=complete,estado_regla=rule$estado,
      brecha_95=if(is.na(den)||is.na(doses)) NA_real_ else max(0,ceiling(den*.95)-doses),
      alerta=if(!complete) "Reporte incompleto" else if(is.na(cob)) "Sin denominador" else if(cob>100) "Revisar numerador y denominador" else if(cob>=95) "Meta alcanzada" else "Bajo la meta")
  })
  out<-do.call(rbind,out);row.names(out)<-NULL
  merge(out,data$territorios,by="ubigeo",all.x=TRUE,sort=FALSE)
}
coverage_summary <- function(table) {
  if (!nrow(table)) return(data.frame())
  # Aggregate within one rule only: different denominators must not be added.
  do.call(rbind,lapply(split(table,table$regla_id),function(x) data.frame(
    regla_id=x$regla_id[1],dosis=if(all(x$reporte_completo)) sum(x$dosis) else NA_real_,
    denominador=if(all(is.finite(x$denominador))) sum(x$denominador) else NA_real_,
    cobertura=if(all(x$reporte_completo)&&all(is.finite(x$denominador))) safe_pct(sum(x$dosis),sum(x$denominador)) else NA_real_,
    territorios=nrow(x),reportes_completos=sum(x$reporte_completo))))
}
dropout_table <- function(coverage, initial, final) {
  if (!nrow(coverage)) return(data.frame())
  a<-coverage[coverage$regla_id==initial,c("ubigeo","dosis")];names(a)[2]<-"dosis_inicial"
  b<-coverage[coverage$regla_id==final,c("ubigeo","dosis")];names(b)[2]<-"dosis_final"
  x<-merge(a,b,by="ubigeo",all=TRUE)
  x$desercion<-safe_pct(x$dosis_inicial-x$dosis_final,x$dosis_inicial)
  x$interpretacion<-ifelse(is.na(x$desercion),"No calculable",ifelse(x$desercion<0,"Desercion negativa: revisar comparabilidad",ifelse(x$desercion>=10,"Continuidad por mejorar","Bajo el umbral")))
  x
}
monthly_trend <- function(data, rule, year, territories=NULL) {
  x<-data$vacunacion
  x<-x[x$anio==year & x$regla_id==rule & x$estrategia=="regular",,drop=FALSE]
  units<-territories %||% unique(data$poblacion$ubigeo[data$poblacion$anio==year])
  x<-x[x$ubigeo %in% units,,drop=FALSE]
  cumulative<-0
  out<-lapply(seq_len(12),function(m) {
    z<-x[x$mes==m,,drop=FALSE]
    complete<-length(units)>0L && nrow(z)==length(units)&&all(z$estado_reporte=="completo")&&all(is.finite(z$dosis))
    value<-if(complete) sum(z$dosis) else NA_real_
    cumulative<<-cumulative+value
    data.frame(mes=m,dosis=value,acumulado=cumulative,reporte_completo=complete)
  })
  do.call(rbind,out)
}
# A negative administrative dropout is a signal, never proof of individual abandonment.
