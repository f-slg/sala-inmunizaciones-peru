# Estimates in doses first; round vials only after pooling the same product/territory.
plan_requirements <- function(programming, inventory, presentations, catalog=load_catalog(), cutoff=Sys.Date()) {
  if(!nrow(programming)) return(data.frame())
  assert_columns(presentations,c("producto_id","dosis_frasco","volumen_cm3_dosis","jeringas_dosis","diluyentes_frasco","jeringas_reconstitucion_frasco","capacidad_caja","fuente"),"presentaciones")
  p<-programming
  for(n in c("poblacion_elegible","recuperacion","reserva_dosis","transito_dosis","dias_reposicion")) assert_number(p[[n]],n)
  assert_number(p$meta,"meta",max=1);assert_number(p$perdida,"perdida",max=1-.Machine$double.eps)
  assert_number(p$dias_horizonte,"dias_horizonte",min=1)
  if(anyDuplicated(p[c("anio","ubigeo","regla_id")])) stop("Programacion duplicada",call.=FALSE)
  r<-catalog$reglas[match(p$regla_id,catalog$reglas$regla_id),]
  if(anyNA(r$producto_id)) stop("Regla desconocida",call.=FALSE)
  p$producto_id<-r$producto_id
  p$administrar<-ceiling(p$poblacion_elegible*p$meta)+p$recuperacion
  p$brutas<-p$administrar/(1-p$perdida)
  # Stock/reserve/transit are product-level: entered once per product, never once per dose.
  out<-lapply(split(p,paste(p$anio,p$ubigeo,p$producto_id,sep="::")),function(z) {
    one<-function(n) {u<-unique(z[[n]]);if(length(u)!=1L) stop("Parametros de producto inconsistentes: ",n,call.=FALSE);u}
    pres<-presentations[presentations$producto_id==z$producto_id[1],,drop=FALSE]
    if(nrow(pres)!=1L) stop("Falta una presentacion unica para ",z$producto_id[1],call.=FALSE)
    assert_number(pres$dosis_frasco,"dosis_frasco",min=1,integer=TRUE)
    for(n in c("volumen_cm3_dosis","jeringas_dosis","diluyentes_frasco","jeringas_reconstitucion_frasco")) assert_number(pres[[n]],n)
    assert_number(pres$capacidad_caja,"capacidad_caja",min=1,integer=TRUE)
    inv<-inventory[inventory$ubigeo==z$ubigeo[1]&inventory$producto_id==z$producto_id[1],,drop=FALSE]
    horizon_end<-as.Date(cutoff)+one("dias_horizonte")
    usable<-sum(inv$saldo_dosis[!inv$cuarentena & inv$vencimiento>=horizon_end],na.rm=TRUE)
    at_risk<-sum(inv$saldo_dosis[!inv$cuarentena & inv$vencimiento>=as.Date(cutoff) & inv$vencimiento<horizon_end],na.rm=TRUE)
    gross<-ceiling(sum(z$brutas)); transit<-one("transito_dosis");reserve<-one("reserva_dosis")
    net<-max(0,gross+reserve-usable-transit);vials<-ceiling(net/pres$dosis_frasco)
    daily<-sum(z$brutas)/one("dias_horizonte")
    data.frame(anio=z$anio[1],ubigeo=z$ubigeo[1],producto_id=z$producto_id[1],
      dosis_administrar=sum(z$administrar),dosis_brutas=gross,reserva_dosis=reserve,
      stock_utilizable=usable,stock_vence_horizonte=at_risk,transito_confirmado=transit,
      pedido_neto=net,frascos=vials,dosis_redondeadas=vials*pres$dosis_frasco,
      jeringas_administracion=ceiling(sum(z$administrar)*pres$jeringas_dosis),
      diluyentes=ceiling(vials*pres$diluyentes_frasco),
      jeringas_reconstitucion=ceiling(vials*pres$jeringas_reconstitucion_frasco),
      cajas_seguridad=ceiling((sum(z$administrar)*pres$jeringas_dosis+vials*pres$jeringas_reconstitucion_frasco)/pres$capacidad_caja),
      volumen_pedido_litros=vials*pres$dosis_frasco*pres$volumen_cm3_dosis/1000,
      dias_existencia=if(daily>0) usable/daily else NA_real_,
      punto_pedido=ceiling(daily*one("dias_reposicion")+reserve),
      riesgo_quiebre=if(daily>0) usable/daily<one("dias_reposicion") else FALSE,
      fuente_presentacion=pres$fuente,
      supuesto="Stock que vence antes del fin del horizonte se excluye conservadoramente; revisar consumo FEFO")
  })
  do.call(rbind,out)
}
inventory_reconciliation <- function(inventory,movements,cutoff=Sys.Date()) {
  if(!nrow(inventory)) return(data.frame())
  out<-inventory
  delta<-vapply(seq_len(nrow(out)),function(i) {
    m<-movements[movements$ubigeo==out$ubigeo[i]&movements$producto_id==out$producto_id[i]&movements$lote==out$lote[i]&movements$fecha<=as.Date(cutoff) & movements$fecha>out$fecha_saldo[i],,drop=FALSE]
    sum(ifelse(m$tipo %in% c("entrada","ajuste_positivo"),m$dosis,-m$dosis))
  },numeric(1))
  out$movimiento_neto<-delta
  # Inventory is an opening balance; movements up to cutoff are applied once.
  out$saldo_calculado<-ifelse(out$fecha_saldo>as.Date(cutoff),NA_real_,out$saldo_dosis+delta)
  out$estado<-ifelse(is.na(out$saldo_calculado),"Saldo posterior al corte",ifelse(out$saldo_calculado<0,"Saldo negativo",ifelse(out$cuarentena,"Cuarentena",ifelse(out$vencimiento<as.Date(cutoff),"Vencido",ifelse(out$vencimiento<=as.Date(cutoff)+90,"Vence en 90 dias","Disponible")))))
  out[order(out$vencimiento),,drop=FALSE]
}
cold_chain_summary <- function(requirements,capacity) {
  if(!nrow(requirements)||!nrow(capacity)) return(data.frame())
  x<-stats::aggregate(volumen_pedido_litros~ubigeo,requirements,sum)
  x<-merge(x,capacity,by="ubigeo",all.x=TRUE)
  x$libre_litros<-x$capacidad_litros-x$ocupacion_otros_litros
  x$excede_capacidad<-x$volumen_pedido_litros>x$libre_litros
  x
}
consumption_forecast <- function(consumption,cutoff=Sys.Date(),horizon=90,lookback_months=6) {
  if(!nrow(consumption)) return(data.frame())
  assert_number(horizon,"horizonte",min=1)
  dates<-as.Date(sprintf("%04d-%02d-01",consumption$anio,consumption$mes))
  end_month<-as.Date(format(as.Date(cutoff),"%Y-%m-01"))
  start_month<-add_months(end_month,-lookback_months)
  x<-consumption[dates>=start_month & dates<end_month,,drop=FALSE]
  if(!nrow(x)) return(data.frame())
  do.call(rbind,lapply(split(x,paste(x$ubigeo,x$producto_id)),function(z) {
    complete<-nrow(z)==lookback_months && all(z$reporte_completo) && all(is.finite(z$dosis_consumidas))
    days<-sum(z$dias_observados-z$dias_sin_stock)
    rate<-if(complete&&days>0) sum(z$dosis_consumidas)/days else NA_real_
    data.frame(ubigeo=z$ubigeo[1],producto_id=z$producto_id[1],meses_observados=nrow(z),dias_con_stock=days,
      consumo_diario_estimado=rate,horizonte_dias=horizon,dosis_estimadas=ceiling(rate*horizon),
      ajuste_sin_stock=any(z$dias_sin_stock>0),supuesto="Consumo observado por dia con stock; no mide demanda no atendida. No sumar a proyeccion poblacional.")
  }))
}

# Reconciliation sorts lots by expiry. Rejoin balances by their natural key,
# never by row position, before estimating stock available for each product.
apply_inventory_balances <- function(inventory,reconciled) {
  keys<-c("ubigeo","producto_id","lote")
  assert_columns(inventory,keys,"inventario")
  assert_columns(reconciled,c(keys,"saldo_calculado"),"conciliacion")
  key<-function(x) do.call(paste,c(x[keys],sep="\r"))
  if(anyDuplicated(key(inventory)) || anyDuplicated(key(reconciled))) stop("Lotes duplicados en conciliacion",call.=FALSE)
  pos<-match(key(inventory),key(reconciled))
  if(anyNA(pos)) stop("Falta saldo conciliado para un lote",call.=FALSE)
  inventory$saldo_dosis<-reconciled$saldo_calculado[pos]
  inventory
}
