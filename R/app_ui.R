app_ui <- function(request) {
  public<-isTRUE(golem::get_golem_options("public_mode"))
  golem::add_resource_path("sala-assets",app_sys("app","www"))
  shiny::tagList(shiny::tags$head(shiny::tags$link(rel="stylesheet",type="text/css",href="sala-assets/sala.css")),
    bslib::page_navbar(title=shiny::span(class="brand","Inmunizaciones \u00b7 Per\u00fa"),id="navigation",lang="es",window_title="Sala situacional de inmunizaciones",fillable=FALSE,
      theme=bslib::bs_theme(version=5,primary="#542583",secondary="#20836E",base_font="Arial",bg="#F4F6FA",fg="#17233B"),
      sidebar=bslib::sidebar(title="\u00c1mbito y cortes",width=300,mod_filters_ui("filters")),
      header=shiny::tagList(shiny::div(class="hero",shiny::div(class="eyebrow","UNIVERSIDAD CONTINENTAL \u00b7 PSSE00333"),shiny::h1("Sala situacional integral de inmunizaciones"),shiny::p("An\u00e1lisis territorial, seguimiento de esquemas y programaci\u00f3n de recursos.")),shiny::uiOutput("source_banner")),
      bslib::nav_panel("Resumen",mod_overview_ui("overview")),
      bslib::nav_panel("Mi proyecto",mod_workspace_ui("workspace",public)),
      bslib::nav_panel("Poblaci\u00f3n",mod_table_ui("population","Poblaci\u00f3n objetivo y denominadores","Grupos potencialmente superpuestos: no sumar para contar personas unicas.")),
      bslib::nav_panel("Coberturas",mod_coverage_ui("coverage")),
      bslib::nav_panel("Tendencias",mod_trends_ui("trends")),
      bslib::nav_panel("Mapa",mod_map_ui("map")),
      bslib::nav_panel("Nominal",mod_nominal_ui("nominal",public)),
      bslib::nav_panel("Programaci\u00f3n",mod_logistics_ui("logistics")),
      bslib::nav_panel("Inventario",mod_inventory_ui("inventory")),
      bslib::nav_panel("Calidad",mod_table_ui("quality","Calidad y completitud","Errores estructurales bloquean la carga. Alertas analiticas requieren interpretacion.")),
      bslib::nav_panel("Norma",shiny::tagList(mod_table_ui("products","Catalogo de productos","Incluye vacunas, antecedentes y anticuerpo monoclonal. Presentaciones logisticas deben documentarse por producto real."),mod_table_ui("rules","Reglas y trazabilidad","Verificada: transcripcion de referencia. Condicional o revision clinica: no se automatiza. Tolerancia de oportunidad de 30 dias es un parametro pedagogico, no un umbral normativo universal."),mod_table_ui("fichas","Fichas t\u00e9cnicas de indicadores"),mod_table_ui("variables","Diccionario de variables"),mod_table_ui("sources","Fuentes"))),
      bslib::nav_panel("Plan de mejora",mod_plan_ui("plan",public)),
      bslib::nav_panel("Informe",mod_reports_ui("reports")),
      footer=shiny::div(class="app-footer","salainmunizaciones 0.2.0 \u00b7 Proyecto educativo reproducible \u00b7 Linux / Windows / macOS")))
}
