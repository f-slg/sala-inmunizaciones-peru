report_html <- function(tables,config,filters,catalog=load_catalog()) {
  # Always escape user-provided text; no nominal records or untrusted HTML.
  cell<-function(x) htmltools::tags$td(if(length(x)==0||is.na(x)) "Sin dato" else as.character(x))
  tab<-function(x) {
    if(!is.data.frame(x)||!nrow(x)) return(htmltools::tags$p("Sin datos"))
    if(any(c("persona_id","fecha_nacimiento","evento_id","episodio_id") %in% names(x))) stop("Informe publico con identificadores nominales")
    htmltools::tags$table(htmltools::tags$thead(htmltools::tags$tr(lapply(names(x),htmltools::tags$th))),htmltools::tags$tbody(lapply(seq_len(nrow(x)),function(i) htmltools::tags$tr(lapply(x[i,,drop=FALSE],cell)))))
  }
  parts<-lapply(names(tables),function(n) htmltools::tagList(htmltools::tags$h2(gsub("_"," ",n)),tab(tables[[n]])))
  htmltools::tags$html(lang="es",htmltools::tags$head(htmltools::tags$meta(charset="UTF-8"),htmltools::tags$title("Informe de sala situacional"),
    htmltools::tags$style(htmltools::HTML("body{font:14px Arial,sans-serif;color:#17233b;margin:40px;line-height:1.5}h1,h2{color:#542583}table{border-collapse:collapse;width:100%;font-size:11px;display:block;overflow:auto}th,td{padding:8px;border:1px solid #dbe1e8;text-align:left}th{background:#eee7f5}section{margin-bottom:24px}@media print{table{display:table;font-size:8px}body{margin:12mm}}"))),
    htmltools::tags$body(htmltools::tags$h1("Sala situacional integral de inmunizaciones"),
      htmltools::tags$p(paste("Alumno:",config$alumno[1],"\u00b7 Ambito:",config$ambito[1])),
      htmltools::tags$p(paste("Fuente:",config$fuente[1],"\u00b7 Version de datos:",config$version_datos[1])),
      htmltools::tags$p(sprintf("Corte administrativo: %02d/%d \u00b7 Corte nominal/inventario: %s \u00b7 Regla: %s",filters$month,filters$year,filters$cutoff,filters$rule)),
      htmltools::tags$p(paste("Generado:",format(Sys.time(),"%Y-%m-%d %H:%M:%S %Z"),"\u00b7 salainmunizaciones 0.2.0")),
      htmltools::tags$p("Meta de lectura administrativa: 95 %. Fuentes poblacionales por grupo. Reportes incompletos no se convierten en cero. Programacion: parametros propios del horizonte declarado. Existencias que vencen dentro del horizonte excluidas conservadoramente. Revisar alternativas y grupos superpuestos antes de totalizar pedidos."),
      parts,htmltools::tags$h2("Fuentes y alcance normativo"),tab(catalog$fuentes),
      htmltools::tags$p("Reglas especiales y condicionales requieren revision documentada. Las reglas de oportunidad incluyen una tolerancia pedagogica configurable de 30 dias, no una certificacion de oportunidad normativa. La evaluacion de fechas no sustituye la revision clinica. El informe no contiene registros nominales.")))
}
