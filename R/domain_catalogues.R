# Geographic catalogue is provided by mapsPERU; it is not a live INEI register.
territory_catalog <- function() {
  x<-mapsPERU::map_DIST
  d<-data.frame(ubigeo=as.character(x$COD_DISTRITO),distrito=as.character(x$DISTRITO),
    provincia=as.character(x$PROVINCIA),departamento=as.character(x$DEPARTAMENTO),stringsAsFactors=FALSE)
  d<-d[order(d$departamento,d$provincia,d$distrito),,drop=FALSE];row.names(d)<-NULL;d
}
entry_options <- function(catalog=load_catalog()) list(
  grupo_id=catalog$grupos$grupo_id,regla_id=catalog$reglas$regla_id,
  producto_id=catalog$productos$producto_id,dosis_id=unique(catalog$reglas$dosis_id),
  sexo=c("F","M","X","ND"),ruta_id=c("penta_ipv","hexavalente","revision"),
  estrategia=c("regular","recuperacion","campana","bloqueo"),
  estado_reporte=c("completo","pendiente"),cuarentena=c("FALSE","TRUE"),
  reporte_completo=c("TRUE","FALSE"),
  tipo=c("entrada","salida","aplicacion","perdida","ajuste_positivo","ajuste_negativo")
)
# A dictionary entry is contextual: the same variable can have a different unit
# or requirement depending on its sheet. Optional sheet != optional field.
variable_dictionary <- function(catalog=load_catalog()) {
  schema<-data_schema();opts<-entry_options(catalog)
  examples<-demo_dataset(catalog)
  definitions<-c(
    alumno="Identificacion del estudiante responsable; nunca identificacion del paciente",
    ambito="Nombre del establecimiento, distrito o conjunto de territorios analizados",
    anio="Ano de referencia del denominador, reporte o programacion",
    fecha_corte="Fecha de referencia del proyecto; filtros administrativos y nominales se controlan por separado",
    fuente="Sistema o documento de origen, fecha de extraccion y metodo cuando corresponda",
    version_datos="Version identificable del conjunto de datos del proyecto",
    ubigeo="Codigo INEI distrital como texto de seis digitos; conservar ceros iniciales",
    grupo_id="Poblacion elegible del indicador; grupos especiales pueden superponerse",
    poblacion="Denominador positivo del grupo en el ano y territorio indicados",
    version="Version o fecha de la fuente poblacional",
    distrito="Nombre del distrito; consultar catalogo territorial por ubigeo",
    provincia="Nombre de la provincia del distrito",
    departamento="Nombre del departamento del distrito",
    mes="Mes calendario de referencia, de 1 a 12",
    regla_id="Identificador de vacuna/dosis/grupo y ruta; consultar nombre y estado en cat_reglas",
    estrategia="Tipo de actividad; cobertura administrativa actual usa regular",
    dosis="Conteo de dosis; pendiente se registra vacio, no como cero",
    estado_reporte="Completo: reporte disponible; pendiente: dosis ausentes",
    persona_id="Identificador seudonimizado sin nombres, DNI ni datos de contacto",
    fecha_nacimiento="Nacimiento registrado en fecha ISO; no debe ser posterior a la aplicacion",
    sexo="F, M, X o ND (no disponible); no inferir a partir de nombres",
    ruta_id="penta_ipv o hexavalente; historias mixtas y no modeladas usan revision",
    inicio="Inicio de pertenencia documentada al grupo de elegibilidad",
    fin="Fin de pertenencia documentada; no anterior al inicio",
    episodio_id="Identificador del episodio al que corresponde elegibilidad o evento",
    evento_id="Identificador unico de una aplicacion; no repetir el mismo evento",
    producto_id="Producto fisico realmente aplicado o disponible; no duplicar componentes de combinadas",
    dosis_id="Dosis registrada; debe corresponder al producto y regla, no es un ordinal intercambiable",
    fecha="Fecha efectiva de aplicacion o movimiento; no confundir con fecha de digitacion",
    lote="Identificador del lote; enlaza inventario y movimientos del mismo producto y territorio",
    poblacion_elegible="Personas elegibles para esta dosis; evitar duplicar rutas alternativas y grupos superpuestos",
    meta="Proporcion prevista entre 0 y 1; ejemplo 0.95 equivale a 95 por ciento",
    recuperacion="Dosis pendientes adicionales no incluidas ya en la programacion poblacional",
    perdida="Proporcion de dosis suministradas que no se administraran; debe ser menor que 1",
    reserva_dosis="Reserva objetivo del producto; repetir identica entre sus reglas, se cuenta una sola vez",
    transito_dosis="Entregas confirmadas y oportunas del producto; no incluir pedidos sin confirmacion",
    dias_horizonte="Duracion de la programacion en dias; repetir identica entre dosis del producto",
    dias_reposicion="Tiempo esperado entre solicitar y recibir el producto",
    fecha_saldo="Fecha de cierre del saldo inicial; solo movimientos posteriores se agregan al balance",
    vencimiento="Vencimiento del lote; documentar fecha exacta segun presentacion",
    saldo_dosis="Existencias iniciales del lote en dosis, no en frascos",
    cuarentena="TRUE: lote no utilizable; FALSE: lote sin cuarentena declarada",
    movimiento_id="Identificador unico del movimiento logistico",
    tipo="Clase de movimiento; entradas y ajuste positivo suman, otros tipos restan",
    dosis_frasco="Numero entero de dosis de la presentacion real por frasco",
    volumen_cm3_dosis="Volumen EMPACADO por dosis para almacenamiento; no volumen liquido inyectado",
    jeringas_dosis="Jeringas de administracion requeridas por dosis administrada",
    diluyentes_frasco="Unidades de diluyente requeridas por frasco del producto",
    jeringas_reconstitucion_frasco="Jeringas de reconstitucion requeridas por frasco",
    capacidad_caja="Capacidad de una caja de seguridad en jeringas; entero positivo",
    dosis_consumidas="Dosis utilizadas durante el periodo observado de consumo",
    dias_observados="Dias del mes cubiertos por la observacion, entre 1 y 31",
    dias_sin_stock="Dias de la observacion sin disponibilidad; no mayores que dias_observados",
    reporte_completo="TRUE si la observacion mensual esta completa; FALSE si no es comparable",
    capacidad_litros="Capacidad util de almacenamiento declarada para el ambito",
    ocupacion_otros_litros="Volumen ya ocupado que se resta de la capacidad disponible",
    accion_id="Identificador unico de la intervencion del plan de mejora",
    problema="Problema de gestion identificado en el analisis",
    evidencia="Dato, indicador o fuente que sustenta el problema",
    accion="Intervencion concreta que responde al problema documentado",
    responsable="Responsable de ejecutar o supervisar la intervencion",
    fecha_limite="Fecha comprometida para cumplir la intervencion",
    indicador="Medida con la que se evaluara el cumplimiento",
    avance="Avance de la intervencion de 0 a 100; no es una proporcion de 0 a 1"
  )
  numeric<-c("anio","mes","poblacion","dosis","poblacion_elegible","meta","recuperacion","perdida","reserva_dosis","transito_dosis","dias_horizonte","dias_reposicion","saldo_dosis","dosis_frasco","volumen_cm3_dosis","jeringas_dosis","diluyentes_frasco","jeringas_reconstitucion_frasco","capacidad_caja","dosis_consumidas","dias_observados","dias_sin_stock","capacidad_litros","ocupacion_otros_litros","avance")
  dates<-c("fecha_corte","fecha_nacimiento","inicio","fin","fecha","fecha_saldo","vencimiento","fecha_limite")
  decimal<-c("meta","perdida","volumen_cm3_dosis","jeringas_dosis","diluyentes_frasco","jeringas_reconstitucion_frasco","capacidad_litros","ocupacion_otros_litros","avance")
  booleans<-c("cuarentena","reporte_completo")
  out<-list();k<-0L
  for(sheet in names(schema)) for(field in schema[[sheet]]) {
    k<-k+1L;x<-examples[[sheet]][[field]]
    example<-if(length(x) && !is.na(x[1])) as.character(x[1]) else switch(field,
      inicio="2026-01-01",fin="2026-12-31",episodio_id="EP-001",movimiento_id="MOV-001",tipo="entrada",fecha="2026-10-01",dosis="10",persona_id="SIM-0001",grupo_id="GEST","Ver instrucciones")
    desc<-definitions[[field]]
    if(sheet=="plan_mejora" && field=="meta") desc<-"Meta descriptiva verificable de la intervencion; texto, por ejemplo alcanzar 95 por ciento"
    type<-if(field %in% dates) "Fecha AAAA-MM-DD" else if(field %in% booleans) "Logico TRUE/FALSE" else if(field %in% numeric && !(sheet=="plan_mejora"&&field=="meta")) if(field %in% decimal) "Numero decimal" else "Numero entero" else "Texto"
    allowed<-if(field=="ubigeo") "cat_territorios: codigo INEI de seis digitos" else if(field %in% names(opts)) paste(opts[[field]],collapse=" | ") else if(field %in% dates) "Fecha nativa Excel o AAAA-MM-DD" else if(type=="Numero entero") "Entero no negativo; poblacion, frasco y caja positivos" else "Ver definicion y validaciones"
    if(field=="regla_id") allowed<-"cat_reglas: columna regla_id; revisar ruta, dosis, grupo y estado"
    if(field=="producto_id") allowed<-"cat_productos: columna producto_id; presentacion real documentada"
    unit<-if(field %in% c("poblacion","poblacion_elegible")) "personas" else
      if(field %in% c("meta","perdida") && sheet!="plan_mejora") "proporcion 0 a 1" else
      if(field=="avance") "porcentaje 0 a 100" else
      if(field %in% c("dosis","recuperacion","reserva_dosis","transito_dosis","saldo_dosis","dosis_consumidas")) "dosis" else
      if(grepl("^dias_",field)) "dias" else
      if(field=="volumen_cm3_dosis") "cm3 empacados por dosis" else
      if(grepl("litros$",field)) "litros" else
      if(field=="dosis_frasco") "dosis por frasco" else
      if(field=="jeringas_dosis") "jeringas por dosis" else
      if(field %in% c("diluyentes_frasco","jeringas_reconstitucion_frasco")) "unidades por frasco" else
      if(field=="capacidad_caja") "jeringas por caja" else "No aplica o ver definicion"
    out[[k]]<-data.frame(hoja=sheet,variable=field,tipo=type,unidad=unit,
      obligatoria=if(sheet=="vacunacion"&&field=="dosis") "Condicional: vacia si reporte pendiente" else "Si, cuando se utiliza esta hoja",
      hoja_opcional=sheet %in% optional_sheets(),definicion=unname(desc),valores_permitidos=allowed,ejemplo=example,
      sensibilidad=if(sheet %in% c("personas","eventos","elegibilidad")) "Privado: dato nominal seudonimizado" else "Revisar antes de publicar",stringsAsFactors=FALSE)
  }
  do.call(rbind,out)
}
