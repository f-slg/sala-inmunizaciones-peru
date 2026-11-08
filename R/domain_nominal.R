# Rule-driven assessment. No medication orders or inferred clinical eligibility.
product_equivalents <- function(product) {
  switch(product,PCV20=c("PCV20","PCV13"),VPH9=c("VPH9","VPH4"),product)
}
assess_nominal <- function(data,catalog=load_catalog(),cutoff=as.Date(data$configuracion$fecha_corte[1])) {
  if (!nrow(data$personas)) return(data.frame())
  cutoff<-as.Date(cutoff)
  people<-data$personas[!is.na(data$personas$fecha_nacimiento)&data$personas$fecha_nacimiento<=cutoff,,drop=FALSE]
  if(!nrow(people)) return(data.frame())
  rules<-active_rules(catalog,cutoff,reviewed_only=FALSE)
  rules<-rules[order(rules$edad_objetivo_meses,rules$regla_id),,drop=FALSE]
  groups<-data$elegibilidad
  groups<-groups[groups$inicio<=cutoff & groups$fin>=cutoff,,drop=FALSE]
  special_ids<-groups$persona_id[groups$grupo_id %in% c("VIH","ESPECIAL")]
  events<-data$eventos[data$eventos$fecha<=cutoff,,drop=FALSE]
  valid_dates<-list();result<-list()
  # Vectorised across people; only the small rule catalog is iterated.
  for(j in seq_len(nrow(rules))) {
    r<-rules[j,]
    keep<-r$ruta_id=="todas" | people$ruta_id==r$ruta_id
    if(r$elegibilidad=="grupo") keep<-keep & people$persona_id %in% groups$persona_id[groups$grupo_id==r$grupo_id]
    p<-people[keep,,drop=FALSE];if(!nrow(p)) next
    birth<-as.Date(p$fecha_nacimiento)
    due<-add_months(birth,r$edad_objetivo_meses)
    if(r$elegibilidad=="grupo") {
      g<-groups[groups$grupo_id==r$grupo_id,,drop=FALSE]
      beginnings<-tapply(as.numeric(g$inicio),g$persona_id,min)
      due<-as.Date(pmax(as.numeric(birth),beginnings[p$persona_id]),origin="1970-01-01")
    }
    earliest<-add_months(birth,r$edad_min_meses)
    upper<-if(r$producto_id=="ROTA") add_months(birth,8)+1 else add_months(birth,floor(r$edad_max_meses_exclusiva))
    eligible<-due<=cutoff
    if(r$repeticion=="anual") eligible<-eligible & cutoff<upper
    p<-p[eligible,,drop=FALSE];birth<-birth[eligible];due<-due[eligible];earliest<-earliest[eligible];upper<-upper[eligible]
    if(!nrow(p)) next
    state<-ifelse(cutoff>=upper,"fuera_edad_revisar","pendiente")
    received<-as.Date(rep(NA_character_,nrow(p)));timely<-rep(NA,nrow(p))
    review<-r$estado!="verificada" | p$persona_id %in% special_ids | !p$ruta_id %in% c("penta_ipv","hexavalente")
    e<-events[events$producto_id %in% product_equivalents(r$producto_id) & events$dosis_id==r$dosis_id,,drop=FALSE]
    if(r$repeticion=="anual") e<-e[format(e$fecha,"%Y")==format(cutoff,"%Y"),,drop=FALSE]
    idx<-match(e$persona_id,p$persona_id);e<-e[!is.na(idx),,drop=FALSE];idx<-idx[!is.na(idx)]
    if(nrow(e)) {
      state[unique(idx)]<-"registrada_no_valida"
      valid<-e$fecha>=earliest[idx] & e$fecha>=birth[idx] & e$fecha<upper[idx]
      prev<-r$previa_id;if(is.na(prev)) prev<-""
      if(nzchar(prev)) {
        pd<-valid_dates[[prev]]
        if(is.null(pd)) valid[]<-FALSE else {
          previous<-pd[e$persona_id]
          valid<-valid & !is.na(previous) & as.numeric(e$fecha)-previous>=r$intervalo_min_dias
        }
      }
      valid<-valid & !review[idx]
      if(any(valid)) {
        first<-tapply(as.numeric(e$fecha[valid]),e$persona_id[valid],min)
        ii<-match(names(first),p$persona_id)
        received[ii]<-as.Date(as.numeric(first),origin="1970-01-01")
        state[ii]<-"recibida_valida"
        timely[ii]<-received[ii]<=due[ii]+r$tolerancia_oportunidad_dias
        # Day-only data cannot certify a 12/24-hour neonatal window.
        if(r$regla_id %in% c("HVB_RN","BCG_RN")) timely[ii]<-NA
      }
    }
    state[review]<-"requiere_revision"
    valid_dates[[r$regla_id]]<-stats::setNames(as.numeric(received),p$persona_id)
    result[[length(result)+1L]]<-data.frame(persona_id=p$persona_id,ubigeo=p$ubigeo,ruta_id=p$ruta_id,
      regla_id=r$regla_id,producto_id=r$producto_id,dosis_id=r$dosis_id,fecha_objetivo=due,
      fecha_recibida=received,estado=state,oportuna=timely,fecha_corte=cutoff,estado_regla=r$estado,stringsAsFactors=FALSE)
  }
  if(!length(result)) return(data.frame())
  out<-do.call(rbind,result);row.names(out)<-NULL;out
}
nominal_summary <- function(assessment) {
  if(!nrow(assessment)) return(data.frame())
  do.call(rbind,lapply(split(assessment,assessment$persona_id),function(x) {
    evaluated<-x$estado!="requiere_revision"
    data.frame(persona_id=x$persona_id[1],ubigeo=x$ubigeo[1],
      dosis_evaluadas=sum(evaluated),dosis_validas=sum(x$estado=="recibida_valida"),
      pendientes=sum(x$estado %in% c("pendiente","fuera_edad_revisar","registrada_no_valida")),
      revision=sum(!evaluated),
      completo=if(!all(evaluated)||!any(evaluated)) NA else all(x$estado=="recibida_valida"))
  }))
}
opportunity_table <- function(assessment) {
  if(!nrow(assessment)) return(data.frame())
  do.call(rbind,lapply(split(assessment,assessment$regla_id),function(x) {
    evaluated<-x$estado=="recibida_valida" & !is.na(x$oportuna)
    data.frame(regla_id=x$regla_id[1],dosis_validas=sum(x$estado=="recibida_valida"),
      evaluables=sum(evaluated),oportunas=sum(x$oportuna[evaluated]),
      oportunidad=safe_pct(sum(x$oportuna[evaluated]),sum(evaluated)))
  }))
}
nominal_dose_needs <- function(assessment) {
  if(!nrow(assessment)) return(data.frame())
  x<-assessment[assessment$estado=="pendiente",,drop=FALSE]
  if(!nrow(x)) return(data.frame())
  stats::aggregate(list(dosis_pendientes=x$persona_id),x[c("ubigeo","producto_id","regla_id")],length)
}
