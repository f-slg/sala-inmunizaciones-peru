app_server <- function(input,output,session) {
  catalog<-load_catalog();public<-isTRUE(golem::get_golem_options("public_mode"))
  initial<-golem::get_golem_options("data") %||% demo_dataset(catalog)
  check<-validate_dataset(initial,catalog)
  if(any(check$nivel=="Error")) stop("Datos iniciales invalidos: ",paste(check$detalle[check$nivel=="Error"],collapse="; "))
  if(public) for(n in c("personas","eventos","elegibilidad")) initial[[n]]<-empty_dataset()[[n]]
  state<-shiny::reactiveVal(initial)
  filters<-mod_filters_server("filters",state,catalog)
  quality<-mod_workspace_server("workspace",state,catalog,public)
  data_scope<-shiny::reactive({
    f<-filters();d<-state()
    for(n in names(d)) if("ubigeo" %in% names(d[[n]])) d[[n]]<-d[[n]][d[[n]]$ubigeo %in% f$units,,drop=FALSE]
    d$eventos<-d$eventos[d$eventos$persona_id %in% d$personas$persona_id,,drop=FALSE]
    d$elegibilidad<-d$elegibilidad[d$elegibilidad$persona_id %in% d$personas$persona_id,,drop=FALSE]
    d
  })
  coverage<-shiny::reactive({f<-filters();coverage_table(state(),catalog,f$year,f$month,f$units)})
  assessment<-shiny::reactive({if(public) return(data.frame());assess_nominal(data_scope(),catalog,filters()$cutoff)})
  stock<-shiny::reactive({d<-data_scope();inventory_reconciliation(d$inventario,d$movimientos,filters()$cutoff)})
  requirements<-shiny::reactive({
    d<-data_scope();p<-d$programacion;p<-p[p$anio==filters()$year,,drop=FALSE]
    inv<-d$inventario;s<-stock()
    if(nrow(s)) inv<-apply_inventory_balances(inv,s)
    shiny::validate(shiny::need(!nrow(s)||all(is.finite(s$saldo_calculado) & s$saldo_calculado>=0),"Saldo negativo: corregir inventario antes de programar"))
    tryCatch(plan_requirements(p,inv,d$presentaciones,catalog,filters()$cutoff),error=function(e) {shiny::validate(shiny::need(FALSE,conditionMessage(e)));data.frame()})
  })
  consumption<-shiny::reactive(consumption_forecast(data_scope()$consumo,filters()$cutoff))
  capacity<-shiny::reactive(cold_chain_summary(requirements(),data_scope()$cadena_frio))
  population<-shiny::reactive({d<-data_scope();p<-d$poblacion;p[p$anio==filters()$year,,drop=FALSE]})
  output$source_banner<-shiny::renderUI({d<-state();shiny::div(class=if(grepl("SIMULADO",d$configuracion$fuente[1],ignore.case=TRUE)) "source-banner demo" else "source-banner",shiny::strong(d$configuracion$ambito[1]),shiny::span(paste(" \u00b7 ",d$configuracion$fuente[1]," \u00b7 ",if(public) "Modo publico" else "Sesion privada")))})
  mod_overview_server("overview",coverage,requirements,filters,state)
  mod_table_server("population",population)
  mod_coverage_server("coverage",coverage,filters)
  mod_trends_server("trends",state,coverage,filters)
  mod_map_server("map",coverage,filters)
  mod_nominal_server("nominal",assessment,public)
  mod_logistics_server("logistics",requirements,capacity,consumption)
  mod_inventory_server("inventory",stock,shiny::reactive(data_scope()$movimientos))
  quality_analytical<-shiny::reactive({
    q<-validate_dataset(state(),catalog);z<-coverage()
    if(nrow(z)) {
      incomplete<-sum(!z$reporte_completo);above<-sum(z$cobertura>100,na.rm=TRUE)
      if(incomplete) q<-rbind(q,data.frame(nivel="Aviso",tabla="vacunacion",codigo="reporte_incompleto",detalle=paste(incomplete,"indicadores con reporte incompleto")))
      if(above) q<-rbind(q,data.frame(nivel="Aviso",tabla="vacunacion",codigo="cobertura_100",detalle=paste(above,"coberturas mayores a 100 %")))
    }
    q
  })
  mod_table_server("quality",quality_analytical)
  mod_table_server("products",shiny::reactive(catalog$productos));mod_table_server("rules",shiny::reactive(catalog$reglas));mod_table_server("sources",shiny::reactive(catalog$fuentes))
  mod_table_server("variables",shiny::reactive(variable_dictionary(catalog)))
  mod_table_server("fichas",shiny::reactive(indicator_specs()))
  mod_plan_server("plan",state,public)
  tables<-shiny::reactive(list(resumen=coverage_summary(coverage()),coberturas=coverage(),poblacion=population(),necesidades=requirements(),consumo=consumption(),inventario=stock(),cadena_frio=capacity(),calidad=quality_analytical(),plan_mejora=data_scope()$plan_mejora,configuracion=state()$configuracion,trazabilidad=data.frame(version_app="0.2.0",huella_md5=dataset_fingerprint(state()),corte_administrativo=paste(filters()$year,filters()$month,sep="-"),fecha_corte_nominal=as.character(filters()$cutoff)),fichas_tecnicas=indicator_specs(),fuentes=catalog$fuentes))
  mod_reports_server("reports",tables,state,filters)
  # Returned handles are private to the R session and enable integration tests.
  invisible(list(state=state,filters=filters,coverage=coverage,assessment=assessment,requirements=requirements,tables=tables))
}
