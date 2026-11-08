# XLSX interchange uses only portable R packages; dates are ISO or native Excel dates.
parse_date <- function(x) {
  if(inherits(x,"Date")) return(x)
  if(inherits(x,"POSIXt")) return(as.Date(x))
  if(is.numeric(x)) return(as.Date(x,origin="1899-12-30"))
  x<-trimws(as.character(x));x[x==""]<-NA_character_
  out<-as.Date(rep(NA_character_,length(x)))
  serial<-!is.na(x)&grepl("^[0-9]+(\\.[0-9]+)?$",x)
  out[serial]<-as.Date(as.numeric(x[serial]),origin="1899-12-30")
  iso<-!is.na(x)&grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",x)
  out[iso]<-as.Date(x[iso],format="%Y-%m-%d")
  out
}
coerce_dataset <- function(data) {
  nums<-c("anio","mes","poblacion","dosis","poblacion_elegible","meta","recuperacion","perdida","reserva_dosis","transito_dosis","dias_horizonte","dias_reposicion","saldo_dosis","capacidad_litros","ocupacion_otros_litros","dosis_frasco","volumen_cm3_dosis","jeringas_dosis","diluyentes_frasco","jeringas_reconstitucion_frasco","capacidad_caja","avance","dosis_consumidas","dias_observados","dias_sin_stock")
  dates<-c("fecha_corte","fecha_nacimiento","fecha","inicio","fin","fecha_saldo","vencimiento","fecha_limite")
  for(table in names(data)) {
    x<-data[[table]]
    for(col in intersect(setdiff(nums,if(table=="plan_mejora") "meta" else character()),names(x))) x[[col]]<-suppressWarnings(as.numeric(x[[col]]))
    for(col in intersect(dates,names(x))) x[[col]]<-parse_date(x[[col]])
    if("cuarentena" %in% names(x)) x$cuarentena<-ifelse(toupper(as.character(x$cuarentena)) %in% c("TRUE","VERDADERO","1"),TRUE,ifelse(toupper(as.character(x$cuarentena)) %in% c("FALSE","FALSO","0"),FALSE,NA))
    if("reporte_completo" %in% names(x)) x$reporte_completo<-ifelse(toupper(as.character(x$reporte_completo)) %in% c("TRUE","1","VERDADERO"),TRUE,ifelse(toupper(as.character(x$reporte_completo)) %in% c("FALSE","0","FALSO"),FALSE,NA))
    data[[table]]<-x
  }
  data
}
#' Importar y validar un libro de la sala situacional
#' @param path Ruta del libro XLSX.
#' @param catalog Catalogo normativo.
#' @return Lista con exito, datos e informe; datos es NULL ante cualquier error.
#' @export
import_workbook <- function(path,catalog=load_catalog()) {
  tryCatch({
    sheets<-readxl::excel_sheets(path); ns<-normalise_names(sheets)
    if(anyDuplicated(ns)) stop("Nombres de hojas duplicados al normalizarlos")
    schema<-data_schema(); data<-empty_dataset()
    for(n in names(schema)) {
      pos<-match(n,ns)
      if(is.na(pos)) {
        if(!n %in% optional_sheets()) stop("Falta la hoja obligatoria: ",n)
      } else {
        x<-as.data.frame(readxl::read_excel(path,sheet=sheets[pos],col_types="text",.name_repair="minimal"),stringsAsFactors=FALSE)
        names(x)<-normalise_names(names(x))
        if(anyDuplicated(names(x))) stop("Columnas duplicadas en ",n)
        if(nrow(x)) x<-x[rowSums(!is.na(x)&x!="")>0,,drop=FALSE]
        data[[n]]<-x
      }
    }
    data<-coerce_dataset(data);issues<-validate_dataset(data,catalog)
    ok<-!any(issues$nivel=="Error")
    list(exito=ok,datos=if(ok) data else NULL,informe=issues)
  },error=function(e) list(exito=FALSE,datos=NULL,informe=data.frame(nivel="Error",tabla="archivo",codigo="lectura",detalle=conditionMessage(e))))
}
style_workbook <- function(wb,sheet,nrows,ncols,input=FALSE) {
  openxlsx::addStyle(wb,sheet,openxlsx::createStyle(fontName="Arial",fontColour="#FFFFFF",fgFill="#542583",textDecoration="bold",wrapText=TRUE),rows=1,cols=seq_len(ncols),gridExpand=TRUE)
  if(nrows>0) openxlsx::addStyle(wb,sheet,openxlsx::createStyle(fontName="Arial",fontColour=if(input) "#1258A2" else "#17233B",valign="top"),rows=2:(nrows+1),cols=seq_len(ncols),gridExpand=TRUE,stack=TRUE)
  openxlsx::freezePane(wb,sheet,firstRow=TRUE)
  openxlsx::setColWidths(wb,sheet,cols=seq_len(ncols),widths=23)
  openxlsx::setRowHeights(wb,sheet,rows=1,heights=32)
}
#' Crear plantilla de intercambio de datos
#' @param path Archivo de salida.
#' @param example Incluir datos simulados completos.
#' @param dataset Datos privados a guardar, o NULL para una plantilla.
#' @param territories Distritos elegidos para precargar una plantilla vacia, o NULL.
#' @return Ruta del archivo generado, invisiblemente.
#' @export
write_template <- function(path,example=FALSE,dataset=NULL,territories=NULL) {
  d<-dataset %||% if(example) demo_dataset() else empty_dataset()
  if(!is.null(territories)) {
    if(example || !is.null(dataset)) stop("Seleccion territorial solo para plantillas vacias",call.=FALSE)
    assert_columns(territories,data_schema()$territorios)
    d$territorios<-territories[data_schema()$territorios]
  }
  wb<-openxlsx::createWorkbook(creator="Sala situacional de inmunizaciones")
  openxlsx::modifyBaseFont(wb,fontName="Arial",fontSize=10)
  instructions<-data.frame(tema=c("Uso","Celdas editables","Ejemplo","Identificadores","Poblacion","Dosis","Nominal","Inventario","Presentaciones","Programacion","Privacidad","Norma"),
    indicacion=c("Una hoja por tabla. Conservar nombres y encabezados. Fechas AAAA-MM-DD. Importacion transaccional.",
    "Texto azul: entradas del alumno. No cambiar los catalogos. Las hojas vacias se llenan desde fila 2.",
    "Ver hoja ejemplos: una fila por tabla. Para practicar use el libro de demostracion separado.",
    "Ubigeo INEI de seis digitos y codigos como texto; conservar ceros iniciales. IDs no identificables.",
    "Un denominador por ano, ubigeo y grupo. Fuente y version obligatorias. Grupos superpuestos no se suman.",
    "Una fila por mes, territorio, regla y estrategia. Cero solo con reporte completo; pendiente deja dosis vacias.",
    "Una fila por persona y una fila por aplicacion. La ruta debe ser penta_ipv, hexavalente o revision.",
    "Saldo inicial antes del primer movimiento incluido. Fechas de movimientos deben ser posteriores a ese balance. No repetir saldos finales como iniciales.",
    "Ingresar presentacion real, dosis/frasco, volumen EMPACADO por dosis en cm3 e insumos; los ejemplos son simulados.",
    "Meta y perdida son proporciones (0.95 y 0.10). Recuperacion excluye dosis ya programadas. Reserva/transito/horizonte deben repetirse identicos entre dosis del mismo producto.",
    "No registrar nombres, DNI, telefono ni direccion. Modo publico no permite carga ni seguimiento nominal.",
    "NTS246, consulta 2026-11-08. Reglas condicionales y especiales requieren validacion documentada."))
  openxlsx::addWorksheet(wb,"instrucciones");openxlsx::writeData(wb,"instrucciones",instructions);style_workbook(wb,"instrucciones",nrow(instructions),2)
  openxlsx::setColWidths(wb,"instrucciones",2,110)
  for(n in names(d)) {
    openxlsx::addWorksheet(wb,n);openxlsx::writeData(wb,n,d[[n]],keepNA=FALSE)
    style_workbook(wb,n,nrow(d[[n]]),ncol(d[[n]]),input=TRUE)
    for(j in seq_along(d[[n]])) if(inherits(d[[n]][[j]],"Date") && nrow(d[[n]])) openxlsx::addStyle(wb,n,openxlsx::createStyle(numFmt="yyyy-mm-dd",fontName="Arial"),rows=2:(nrow(d[[n]])+1),cols=j,stack=TRUE)

  }
  examples<-demo_dataset();examples<-do.call(rbind,lapply(names(examples),function(n) data.frame(tabla=n,ejemplo=if(nrow(examples[[n]])) paste(names(examples[[n]]),as.character(examples[[n]][1,]),sep="=",collapse=" | ") else "Hoja opcional sin ejemplo")))
  openxlsx::addWorksheet(wb,"ejemplos");openxlsx::writeData(wb,"ejemplos",examples);style_workbook(wb,"ejemplos",nrow(examples),2)
  add_catalogue_sheets(wb)
  add_input_controls(wb,d)
  openxlsx::writeData(wb,"instrucciones",data.frame(tema=c("Listas de entrada","Catalogo territorial","Diccionario"),
    indicacion=c("Desplegables hasta la fila 5001: codigos, sexo, ruta, estrategia, estado y movimientos. La validacion R sigue siendo obligatoria.",
      paste("cat_territorios: distritos reales de mapsPERU",utils::packageVersion("mapsPERU"),"; seleccionelos en Mi proyecto para precargar nombres."),
      "Consultar diccionario: una fila por variable y hoja, tipos, ejemplos, obligatoriedad y valores permitidos.")),startRow=15,colNames=FALSE)
  save_sala_workbook(wb,path);invisible(path)
}
export_aggregates <- function(path,tables) {
  prohibited<-c("persona_id","fecha_nacimiento","evento_id","episodio_id")
  wb<-openxlsx::createWorkbook();openxlsx::modifyBaseFont(wb,fontName="Arial",fontSize=10)
  for(n in names(tables)) {
    x<-tables[[n]];if(!is.data.frame(x)) next
    if(any(names(x) %in% prohibited)) stop("La exportacion agregada contiene identificadores nominales",call.=FALSE)
    if(!ncol(x)) x<-data.frame(estado="Sin datos")
    sheet<-substr(n,1,31);openxlsx::addWorksheet(wb,sheet);openxlsx::writeData(wb,sheet,x);style_workbook(wb,sheet,nrow(x),ncol(x))
  }
  save_sala_workbook(wb,path);invisible(path)
}

# openxlsx creates placeholder drawing/printer relationships on empty sheets.
# Our exports contain tables only: remove those unused targets before saving so
# Excel, LibreOffice and openpyxl all see a self-consistent OOXML package.
save_sala_workbook <- function(wb,path) {
  for(i in seq_along(wb$worksheets_rels)) {
    rel<-wb$worksheets_rels[[i]]
    wb$worksheets_rels[[i]]<-rel[!grepl("relationships/(drawing|vmlDrawing|printerSettings)",rel)]
    wb$worksheets[[i]]$pageSetup<-gsub(' r:id="rId2"',"",wb$worksheets[[i]]$pageSetup,fixed=TRUE)
  }
  openxlsx::saveWorkbook(wb,path,overwrite=TRUE)
  invisible(path)
}
