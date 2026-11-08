# Native OOXML validations keep dropdowns readable by Excel and LibreOffice.
add_native_list <- function(wb,sheet,col,name,last_row=5001L) {
  i<-match(sheet,names(wb));letter<-openxlsx::int2col(col)
  style<-if(name=="lista_ubigeo") "warning" else "stop"
  message<-if(name=="lista_ubigeo") "Codigo fuera del catalogo cartografico. Conserve el ubigeo INEI real si esta verificado; puede faltar su geometria." else "Seleccione un codigo valido del catalogo."
  xml<-sprintf('<dataValidation type="list" errorStyle="%s" allowBlank="1" showInputMessage="1" showErrorMessage="1" errorTitle="Revisar codigo" error="%s" sqref="%s2:%s%d"><formula1>%s</formula1></dataValidation>',style,message,letter,letter,last_row,name)
  wb$worksheets[[i]]$dataValidations<-c(wb$worksheets[[i]]$dataValidations,xml)
}
add_catalogue_sheets <- function(wb,catalog=load_catalog(),dictionary=TRUE) {
  geography<-territory_catalog()
  sheets<-c(catalog,list(territorios=geography))
  for(n in names(sheets)) {
    name<-paste0("cat_",n)
    if(name %in% names(wb)) next
    openxlsx::addWorksheet(wb,name);openxlsx::writeData(wb,name,sheets[[n]],withFilter=TRUE)
    style_workbook(wb,name,nrow(sheets[[n]]),ncol(sheets[[n]]))
  }
  openxlsx::createNamedRegion(wb,"cat_territorios",cols=1,rows=2:(nrow(geography)+1),name="lista_ubigeo",overwrite=TRUE)
  opts<-entry_options(catalog)
  n<-max(lengths(opts));wide<-as.data.frame(lapply(opts,function(x) c(x,rep(NA_character_,n-length(x)))),stringsAsFactors=FALSE)
  openxlsx::addWorksheet(wb,"cat_opciones");openxlsx::writeData(wb,"cat_opciones",wide)
  style_workbook(wb,"cat_opciones",n,ncol(wide))
  for(field in names(opts)) openxlsx::createNamedRegion(wb,"cat_opciones",cols=match(field,names(opts)),rows=2:(length(opts[[field]])+1),name=paste0("lista_",field),overwrite=TRUE)
  if(dictionary) {
    d<-variable_dictionary(catalog)
    openxlsx::addWorksheet(wb,"diccionario");openxlsx::writeData(wb,"diccionario",d,withFilter=TRUE)
    style_workbook(wb,"diccionario",nrow(d),ncol(d))
    openxlsx::addStyle(wb,"diccionario",openxlsx::createStyle(wrapText=TRUE,fontName="Arial",valign="top"),rows=2:(nrow(d)+1),cols=seq_len(ncol(d)),gridExpand=TRUE,stack=TRUE)
    openxlsx::setRowHeights(wb,"diccionario",rows=2:(nrow(d)+1),heights=48)
    openxlsx::setColWidths(wb,"diccionario",cols=match(c("definicion","valores_permitidos"),names(d)),widths=c(75,65))
  }
  invisible(wb)
}
add_input_controls <- function(wb,data) {
  opts<-entry_options()
  for(sheet in names(data)) {
    x<-data[[sheet]];last<-max(5001L,nrow(x)+1L)
    for(field in intersect(names(x),c("ubigeo",names(opts)))) {
      add_native_list(wb,sheet,match(field,names(x)),paste0("lista_",field),last)
    }
    for(field in intersect(c("ubigeo","persona_id","evento_id","episodio_id","lote","regla_id","producto_id","grupo_id"),names(x))) {
      # Preserve leading zeros when a student types a code instead of using a list.
      openxlsx::addStyle(wb,sheet,openxlsx::createStyle(numFmt="@",fontName="Arial",fontColour="#1258A2"),rows=2:last,cols=match(field,names(x)),stack=TRUE)
    }
    for(field in intersect(c("poblacion","dosis","poblacion_elegible","saldo_dosis","recuperacion","reserva_dosis","transito_dosis","mes","anio","dosis_frasco","capacidad_caja"),names(x))) {
      lo<-if(field %in% c("poblacion","dosis_frasco","capacidad_caja","mes")) 1 else if(field=="anio") 1900 else 0
      hi<-if(field=="mes") 12 else if(field=="anio") 2200 else 1e9
      openxlsx::dataValidation(wb,sheet,cols=match(field,names(x)),rows=2:last,type="whole",operator="between",value=c(lo,hi))
    }
    if(sheet=="programacion") for(field in c("meta","perdida")) openxlsx::dataValidation(wb,sheet,cols=match(field,names(x)),rows=2:last,type="decimal",operator="between",value=c(0,if(field=="meta") 1 else .9999))
    if(sheet=="plan_mejora") openxlsx::dataValidation(wb,sheet,cols=match("avance",names(x)),rows=2:last,type="decimal",operator="between",value=c(0,100))
  }
  invisible(wb)
}
#' Crear un catalogo de variables y codigos de entrada
#' @param path Archivo XLSX de salida.
#' @return Ruta del archivo, invisiblemente.
#' @export
write_catalogue <- function(path) {
  wb<-openxlsx::createWorkbook();openxlsx::modifyBaseFont(wb,fontName="Arial",fontSize=10)
  add_catalogue_sheets(wb);openxlsx::worksheetOrder(wb)<-c(match("diccionario",names(wb)),setdiff(seq_along(names(wb)),match("diccionario",names(wb))));save_sala_workbook(wb,path);invisible(path)
}
#' Crear plantilla complementaria de poblacion
#' @param path Archivo XLSX de salida.
#' @param territories Distritos elegidos con las cuatro columnas de territorios, o NULL.
#' @return Ruta del archivo, invisiblemente.
#' @export
write_population_template <- function(path,territories=NULL) {
  d<-empty_dataset()[c("poblacion","territorios")]
  if(!is.null(territories)) {assert_columns(territories,data_schema()$territorios);d$territorios<-territories[data_schema()$territorios]}
  wb<-openxlsx::createWorkbook();openxlsx::modifyBaseFont(wb,fontName="Arial",fontSize=10)
  instructions<-data.frame(tema=c("Uso","Editar","Codigos","Diccionario","Territorios","Ejemplo","Fuente geografica"),
    indicacion=c("Copiar las hojas poblacion y territorios al libro integral antes de cargar. Esta plantilla aislada no contiene todos los datos requeridos.",
      "Azul: entradas. Listas hasta fila 5001. Escribir poblacion y fuente propias; no modificar catalogos.",
      "Usar desplegables de ubigeo y grupo_id. Ubigeo como texto de seis digitos, sin perder ceros.",
      "La hoja diccionario define variables, tipos, obligatoriedad, valores y ejemplos.",
      "El selector de la app puede entregar los nombres oficiales ya completados. Consultar cat_territorios para otros distritos.",
      "La fila ilustrativa esta en ejemplos y no se importa como poblacion real.",
      paste("mapsPERU",utils::packageVersion("mapsPERU"),"- limites distritales INEI; no es un registro actualizado en linea")))
  openxlsx::addWorksheet(wb,"instrucciones");openxlsx::writeData(wb,"instrucciones",instructions);style_workbook(wb,"instrucciones",nrow(instructions),2);openxlsx::setColWidths(wb,"instrucciones",2,110)
  for(n in names(d)) {openxlsx::addWorksheet(wb,n);openxlsx::writeData(wb,n,d[[n]]);style_workbook(wb,n,nrow(d[[n]]),ncol(d[[n]]),TRUE)}
  openxlsx::addWorksheet(wb,"ejemplos");example<-demo_dataset()$poblacion[1,,drop=FALSE];openxlsx::writeData(wb,"ejemplos",example);style_workbook(wb,"ejemplos",1,ncol(example))
  add_catalogue_sheets(wb);add_input_controls(wb,d);save_sala_workbook(wb,path);invisible(path)
}
