mod_workspace_ui <- function(id,public=FALSE) {
  ns<-shiny::NS(id)
  shiny::tagList(
    bslib::layout_columns(
      module_card("Proyecto del estudiante",
        shiny::textInput(ns("alumno"),"Alumno",value=""),shiny::textInput(ns("ambito"),"Ambito de estudio",value=""),
        shiny::actionButton(ns("save"),"Guardar identificacion",class="btn-primary"),
        shiny::p("Cada alumno trabaja con una copia independiente. Las cargas permanecen en esta sesion.")),
      module_card("Datos y plantillas",
        if(!public) shiny::fileInput(ns("upload"),"Cargar libro XLSX",accept=".xlsx") else shiny::p("Modo publico: consulta agregada. Carga y registro nominal deshabilitados."),
        shiny::downloadButton(ns("template"),"Plantilla vacia"),shiny::downloadButton(ns("example"),"Libro de demostracion"),
        if(!public) shiny::tagList(shiny::actionButton(ns("demo"),"Restaurar demostracion"),shiny::downloadButton(ns("snapshot"),"Guardar proyecto privado (incluye nominal)")))),
    mod_table_ui(ns("validation"),"Resultado de validacion","Los errores bloquean la carga completa. Se conservan los datos anteriores."),
    mod_table_ui(ns("summary"),"Contenido del proyecto")
  )
}
mod_workspace_server <- function(id,state,catalog,public=FALSE) shiny::moduleServer(id,function(input,output,session) {
  issues<-shiny::reactiveVal(validate_dataset(shiny::isolate(state()),catalog))
  shiny::observe({d<-state();shiny::updateTextInput(session,"alumno",value=d$configuracion$alumno[1]);shiny::updateTextInput(session,"ambito",value=d$configuracion$ambito[1])})
  shiny::observeEvent(input$save,{
    if(public) return()
    d<-state();d$configuracion$alumno<-input$alumno;d$configuracion$ambito<-input$ambito;state(d)
    shiny::showNotification("Identificacion actualizada",type="message")
  })
  shiny::observeEvent(input$upload,{
    shiny::req(!public,input$upload)
    x<-import_workbook(input$upload$datapath,catalog);issues(x$informe)
    if(x$exito) {state(x$datos);shiny::showNotification("Archivo validado y cargado",type="message")}
    else shiny::showNotification("Carga rechazada. Revise el informe de validacion.",type="error",duration=8)
  })
  shiny::observeEvent(input$demo,{if(!public) {state(demo_dataset(catalog));issues(validate_dataset(state(),catalog))}})
  output$snapshot<-shiny::downloadHandler(filename=function() "Mi_proyecto_privado.xlsx",content=function(file) {shiny::req(!public);write_template(file,dataset=state())})
  output$template<-shiny::downloadHandler(filename=function() "Plantilla_sala_inmunizaciones.xlsx",content=function(file) write_template(file))
  output$example<-shiny::downloadHandler(filename=function() "Demostracion_sala_inmunizaciones.xlsx",content=function(file) write_template(file,TRUE))
  mod_table_server("validation",issues)
  mod_table_server("summary",shiny::reactive(data.frame(tabla=names(state()),filas=vapply(state(),nrow,integer(1)))))
  issues
})
