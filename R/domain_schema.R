# Canonical data contract. Each row has one explicit grain.
data_schema <- function() list(
  configuracion=c("alumno","ambito","anio","fecha_corte","fuente","version_datos"),
  poblacion=c("anio","ubigeo","grupo_id","poblacion","fuente","version"),
  territorios=c("ubigeo","distrito","provincia","departamento"),
  vacunacion=c("anio","mes","ubigeo","regla_id","estrategia","dosis","estado_reporte"),
  personas=c("persona_id","ubigeo","fecha_nacimiento","sexo","ruta_id"),
  elegibilidad=c("persona_id","grupo_id","inicio","fin","episodio_id"),
  eventos=c("evento_id","persona_id","producto_id","dosis_id","fecha","lote","episodio_id"),
  programacion=c("anio","ubigeo","regla_id","poblacion_elegible","meta","recuperacion","perdida","reserva_dosis","transito_dosis","dias_horizonte","dias_reposicion","fuente"),
  inventario=c("ubigeo","producto_id","lote","fecha_saldo","vencimiento","saldo_dosis","cuarentena"),
  movimientos=c("movimiento_id","fecha","ubigeo","producto_id","lote","tipo","dosis"),
  presentaciones=c("producto_id","dosis_frasco","volumen_cm3_dosis","jeringas_dosis","diluyentes_frasco","jeringas_reconstitucion_frasco","capacidad_caja","fuente"),
  consumo=c("anio","mes","ubigeo","producto_id","dosis_consumidas","dias_observados","dias_sin_stock","reporte_completo"),
  cadena_frio=c("ubigeo","capacidad_litros","ocupacion_otros_litros","fuente"),
  plan_mejora=c("accion_id","ubigeo","problema","evidencia","accion","responsable","fecha_limite","indicador","meta","avance")
)
optional_sheets <- function() c("personas","elegibilidad","eventos","programacion","inventario","movimientos","cadena_frio","presentaciones","consumo","plan_mejora")
empty_dataset <- function() lapply(data_schema(), empty_frame)
# Population groups can overlap. Never add groups to obtain a unique population.
population_groups <- function() read_resource_csv("grupos.csv")
load_catalog <- function() {
  products <- read_resource_csv("productos.csv")
  rules <- read_resource_csv("reglas.csv")
  for (n in c("vigente_desde","vigente_hasta")) rules[[n]] <- as.Date(rules[[n]])
  list(productos=products, reglas=rules, grupos=population_groups(),
       fuentes=read_resource_csv("fuentes.csv"))
}
active_rules <- function(catalog, date, reviewed_only=TRUE) {
  r <- catalog$reglas
  keep <- r$vigente_desde <= as.Date(date) & (is.na(r$vigente_hasta) | r$vigente_hasta >= as.Date(date))
  if (reviewed_only) keep <- keep & r$estado == "verificada"
  r[keep, , drop=FALSE]
}
