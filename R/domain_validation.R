# All-or-nothing ingestion: invalid uploads never replace the active dataset.
validate_dataset <- function(data, catalog=load_catalog()) {
  issues <- data.frame(nivel=character(), tabla=character(), codigo=character(), detalle=character())
  add <- function(level, table, code, text) {
    issues[nrow(issues)+1L,] <<- list(level,table,code,text)
  }
  schema <- data_schema()
  for (table in names(schema)) {
    if (is.null(data[[table]])) { add("Error",table,"tabla_ausente","Falta la tabla"); next }
    missing <- setdiff(schema[[table]],names(data[[table]]))
    if (length(missing)) add("Error",table,"columnas",paste(missing,collapse=", "))
  }
  if (any(issues$nivel=="Error")) return(issues)
  numeric_fields <- list(poblacion=c("anio","poblacion"),vacunacion=c("anio","mes","dosis"),
    programacion=c("anio","poblacion_elegible","meta","recuperacion","perdida","reserva_dosis","transito_dosis","dias_horizonte","dias_reposicion"),
    plan_mejora="avance",
    consumo=c("anio","mes","dosis_consumidas","dias_observados","dias_sin_stock"),
    presentaciones=c("dosis_frasco","volumen_cm3_dosis","jeringas_dosis","diluyentes_frasco","jeringas_reconstitucion_frasco","capacidad_caja"),
    inventario="saldo_dosis",movimientos="dosis",cadena_frio=c("capacidad_litros","ocupacion_otros_litros"))
  for (table in names(numeric_fields)) for (col in numeric_fields[[table]]) {
    x <- data[[table]][[col]]
    # A pending monthly report must remain NA; it must not silently become zero.
    allowed_na <- if (table=="vacunacion" && col=="dosis") data$vacunacion$estado_reporte=="pendiente" else rep(FALSE,length(x))
    bad <- !is.finite(suppressWarnings(as.numeric(x))) & !allowed_na
    if (any(bad)) add("Error",table,"numero_ausente",paste(col,": valor ausente o no numerico"))
    if (any(suppressWarnings(as.numeric(x)) < 0,na.rm=TRUE)) add("Error",table,"negativo",paste(col,": valores negativos"))
  }
  keys <- list(consumo=c("anio","mes","ubigeo","producto_id"),territorios="ubigeo",poblacion=c("anio","ubigeo","grupo_id"),
    vacunacion=c("anio","mes","ubigeo","regla_id","estrategia"),personas="persona_id",eventos="evento_id",
    elegibilidad=c("persona_id","grupo_id","episodio_id","inicio"),programacion=c("anio","ubigeo","regla_id"),
    presentaciones="producto_id",inventario=c("ubigeo","producto_id","lote"),movimientos="movimiento_id",cadena_frio="ubigeo",plan_mejora="accion_id")
  for (table in names(keys)) {
    x <- data[[table]]; cols <- keys[[table]]
    if (any(duplicated(x[cols]))) add("Error",table,"clave_duplicada",paste("Clave duplicada:",paste(cols,collapse=" + ")))
    for (col in cols) if (any(is.na(x[[col]]) | trimws(as.character(x[[col]]))=="")) add("Error",table,"clave_vacia",paste("Clave vacia:",col))
  }
  for (table in names(data)) if ("ubigeo" %in% names(data[[table]])) {
    x <- as.character(data[[table]]$ubigeo)
    if (any(!grepl("^[0-9]{6}$",x))) add("Error",table,"ubigeo_formato","Ubigeo INEI: seis digitos como texto; conservar ceros iniciales")
    if (table!="territorios" && any(!x %in% data$territorios$ubigeo)) add("Error",table,"territorio_ausente","Ubigeo sin correspondencia territorial")
  }
  for (table in c("vacunacion","programacion")) if (any(!data[[table]]$regla_id %in% catalog$reglas$regla_id)) add("Error",table,"regla_desconocida","Regla no incluida en el catalogo")
  if (any(!data$poblacion$grupo_id %in% catalog$grupos$grupo_id)) add("Error","poblacion","grupo_desconocido","Grupo poblacional no definido")
  if (any(data$poblacion$poblacion <= 0,na.rm=TRUE)) add("Error","poblacion","denominador_cero","Los denominadores deben ser positivos; omitir grupos no aplicables")
  if (any(!data$vacunacion$mes %in% 1:12)) add("Error","vacunacion","mes","Mes fuera de 1 a 12")
  if (any(!data$vacunacion$estado_reporte %in% c("completo","pendiente"))) add("Error","vacunacion","reporte","Estado debe ser completo o pendiente")
  if (any(!data$vacunacion$estrategia %in% c("regular","recuperacion","campana","bloqueo"))) add("Error","vacunacion","estrategia","Estrategia no reconocida")
  if (any(data$vacunacion$estado_reporte=="pendiente" & !is.na(data$vacunacion$dosis))) add("Error","vacunacion","pendiente_con_valor","Reporte pendiente debe tener dosis vacias")
  for (table in c("vacunacion","poblacion","programacion","inventario","movimientos")) {
    cols <- intersect(c("anio","mes","dosis","poblacion","poblacion_elegible","recuperacion","saldo_dosis","reserva_dosis","transito_dosis"),names(data[[table]]))
    for (col in cols) if (any(data[[table]][[col]] != floor(data[[table]][[col]]),na.rm=TRUE)) add("Error",table,"entero",paste(col,"debe ser entero"))
  }
  for (col in c("meta","perdida")) {
    x <- data$programacion[[col]]
    if (any(x>1 | (col=="perdida" & x>=1),na.rm=TRUE)) add("Error","programacion","proporcion",paste(col,"debe expresarse entre 0 y 1; perdida < 1"))
  }
  if (any(data$programacion$dias_horizonte<=0,na.rm=TRUE)) add("Error","programacion","horizonte","Horizonte debe ser positivo")
  if (any(!data$inventario$cuarentena %in% c(TRUE,FALSE))) add("Error","inventario","cuarentena","Cuarentena debe ser TRUE o FALSE")
  if (any(!data$movimientos$tipo %in% c("entrada","salida","aplicacion","perdida","ajuste_positivo","ajuste_negativo"))) add("Error","movimientos","tipo","Tipo de movimiento no reconocido")
  for (table in c("eventos","elegibilidad")) if (any(!data[[table]]$persona_id %in% data$personas$persona_id)) add("Error",table,"persona_ausente","Referencia a persona inexistente")
  for (table in c("eventos","inventario","movimientos")) if (any(!data[[table]]$producto_id %in% catalog$productos$producto_id)) add("Error",table,"producto_ausente","Producto desconocido")
  dates <- list(configuracion="fecha_corte",personas="fecha_nacimiento",eventos="fecha",elegibilidad=c("inicio","fin"),inventario=c("fecha_saldo","vencimiento"),movimientos="fecha",plan_mejora="fecha_limite")
  for (table in names(dates)) for (col in dates[[table]]) {
    x<-data[[table]][[col]]
    if (length(x) && anyNA(x)) add("Error",table,"fecha_ausente",paste("Fecha ausente:",col))
  }
  if (any(data$consumo$dias_sin_stock>data$consumo$dias_observados,na.rm=TRUE)) add("Error","consumo","dias_stock","Dias sin stock no pueden superar dias observados")
  if (nrow(data$configuracion)!=1L) add("Error","configuracion","configuracion_unica","Debe existir exactamente una configuracion")
  if (nrow(data$eventos) && nrow(data$personas)) {
    births <- data$personas$fecha_nacimiento[match(data$eventos$persona_id,data$personas$persona_id)]
    if (any(data$eventos$fecha < births,na.rm=TRUE)) add("Error","eventos","antes_nacimiento","Hay aplicaciones anteriores al nacimiento")
    if (any(duplicated(data$eventos[c("persona_id","producto_id","dosis_id","fecha","episodio_id")]))) add("Error","eventos","evento_duplicado","Aplicacion duplicada")
  }
  if (nrow(data$vacunacion)) {
    r <- catalog$reglas[match(data$vacunacion$regla_id,catalog$reglas$regla_id),]
    pkey<-paste(data$poblacion$anio,data$poblacion$ubigeo,data$poblacion$grupo_id)
    vkey<-paste(data$vacunacion$anio,data$vacunacion$ubigeo,r$grupo_id)
    if (any(!vkey %in% pkey)) add("Error","vacunacion","sin_denominador","Hay dosis sin denominador para su ano, territorio y grupo")
    if (any(r$estado!="verificada",na.rm=TRUE)) add("Aviso","vacunacion","regla_por_validar","Incluye reglas que requieren revision tecnica; no se evalua esquema nominal con ellas")
  }
  for(table in names(data)) {
    if(any(names(data[[table]]) %in% c("dni","documento","nombre","nombres","apellido","apellidos","telefono","direccion","correo","email"))) add("Error",table,"identificadores_directos","Retirar nombres, documentos y datos de contacto antes de cargar")
  }
  for(table in c("configuracion","poblacion","programacion","presentaciones","cadena_frio")) for(col in intersect(c("fuente","version","version_datos","alumno","ambito"),names(data[[table]]))) {
    x<-data[[table]][[col]]
    if(any(is.na(x)|trimws(as.character(x))=="")) add("Error",table,"fuente_ausente",paste("Completar",col))
  }
  if(any(!data$personas$ruta_id %in% c("penta_ipv","hexavalente","revision"))) add("Error","personas","ruta","Ruta debe ser penta_ipv, hexavalente o revision")
  if(any(!data$personas$sexo %in% c("F","M","X","ND"))) add("Error","personas","sexo","Sexo: F, M, X o ND")
  if(any(!data$elegibilidad$grupo_id %in% catalog$grupos$grupo_id)) add("Error","elegibilidad","grupo","Grupo de elegibilidad desconocido")
  if(any(data$elegibilidad$inicio>data$elegibilidad$fin,na.rm=TRUE)) add("Error","elegibilidad","rango_fecha","Inicio de elegibilidad posterior al fin")
  if(any(data$presentaciones$dosis_frasco<1 | data$presentaciones$capacidad_caja<1,na.rm=TRUE)) add("Error","presentaciones","presentacion_cero","Dosis por frasco y capacidad de caja deben ser positivas")
  if(nrow(data$programacion)) {
    prods<-catalog$reglas$producto_id[match(data$programacion$regla_id,catalog$reglas$regla_id)]
    if(any(!prods %in% data$presentaciones$producto_id)) add("Error","programacion","sin_presentacion","Falta presentacion documentada para un producto programado")
  }
  if(nrow(data$movimientos)) {
    mi<-match(paste(data$movimientos$ubigeo,data$movimientos$producto_id,data$movimientos$lote),paste(data$inventario$ubigeo,data$inventario$producto_id,data$inventario$lote))
    if(anyNA(mi)) add("Error","movimientos","sin_saldo_inicial","Cada lote con movimientos requiere inventario inicial; usar saldo cero para lotes nuevos")
    if(any(data$movimientos$fecha<=data$inventario$fecha_saldo[mi],na.rm=TRUE)) add("Error","movimientos","anterior_al_saldo","Movimientos deben ser posteriores al saldo inicial")
  }
  if(any(!data$consumo$mes %in% 1:12)) add("Error","consumo","mes","Mes fuera de rango")
  if(any(!data$consumo$reporte_completo %in% c(TRUE,FALSE))) add("Error","consumo","reporte","Reporte completo debe ser TRUE o FALSE")
  if(any(data$consumo$dias_observados<1 | data$consumo$dias_observados>31,na.rm=TRUE)) add("Error","consumo","dias","Dias observados entre 1 y 31")
  if(any(!as.character(data$eventos$dosis_id) %in% entry_options(catalog)$dosis_id)) add("Error","eventos","dosis_desconocida","Dosis no incluida en cat_opciones; utilizar el codigo documentado")
  if(any(data$plan_mejora$avance>100,na.rm=TRUE)) add("Error","plan_mejora","avance","Avance debe expresarse de 0 a 100")
  if (!nrow(data$personas)) add("Aviso","personas","sin_nominal","Sin registro nominal: oportunidad y esquema completo no disponibles")
  if (!nrow(issues)) add("Correcto","general","validacion_ok","Contrato de datos verificado")
  issues
}
