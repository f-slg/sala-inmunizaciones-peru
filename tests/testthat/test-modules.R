test_that("workspace rejects invalid uploads without replacing session data", {
  shiny::testServer(mod_workspace_server,args=list(state=shiny::reactiveVal(demo_dataset()),catalog=load_catalog(),public=FALSE),{
    before<-state()
    session$setInputs(upload=data.frame(name="mal.xlsx",size=1,type="",datapath=tempfile()))
    expect_identical(state(),before)
    expect_true(any(issues()$nivel=="Error"))
  })
})
test_that("public workspace refuses uploads at server level", {
  shiny::testServer(mod_workspace_server,args=list(state=shiny::reactiveVal(demo_dataset()),catalog=load_catalog(),public=TRUE),{
    before<-state();session$setInputs(upload=data.frame(name="mal.xlsx",size=1,type="",datapath=tempfile()))
    expect_identical(state(),before)
  })
})
test_that("full application renders modules and exports under shared filters", {
  app<-run_app()
  shiny::testServer(app,{
    session$setInputs(`filters-year`="2026",`filters-month`=10,`filters-units`=c("090301","090302"),`filters-rule`="PCV_3",`filters-cutoff`="2026-11-08")
    session$flushReact()
    expect_true(nrow(coverage())>0)
    expect_true(nrow(requirements())>0)
    expect_true(nrow(assessment())>0)
    expect_equal(sort(unique(coverage()$ubigeo)),c("090301","090302"))
    outputs<-c("source_banner","overview-cards","overview-reading","coverage-plot","trends-plot","map-map","map-notice","logistics-plot")
    for(n in outputs) expect_no_error(output[[n]])
    expect_true(all(c("resumen","coberturas","necesidades") %in% names(tables())))
  })
})
test_that("reports escape student text", {
  d<-demo_dataset();d$configuracion$alumno<-"<script>alert(1)</script>"
  h<-as.character(report_html(list(resumen=data.frame(x="<b>texto</b>")),d$configuracion,list(month=10,year=2026,cutoff=as.Date("2026-11-08"),rule="PCV_3")))
  expect_false(grepl("<script>",h,fixed=TRUE));expect_true(grepl("&lt;script&gt;",h,fixed=TRUE))
})
test_that("consumption forecast does not disguise missing months", {
  d<-demo_dataset();x<-consumption_forecast(d$consumo,as.Date("2026-11-08"))
  expect_true(all(x$dosis_estimadas==36))
  d$consumo<-d$consumo[d$consumo$mes!=5,]
  expect_true(all(is.na(consumption_forecast(d$consumo,as.Date("2026-11-08"))$dosis_estimadas)))
})
test_that("public application removes nominal data before constructing session state", {
  app<-run_app(public_mode=TRUE)
  mock<-shiny::MockShinySession$new()
  mock$options<-app$appOptions
  expect_true(mock$options$golem_options$public_mode)
  shiny::testServer(app,session=mock,{
    session$setInputs(`filters-year`="2026",`filters-month`=10,`filters-units`="090301",`filters-rule`="PCV_3",`filters-cutoff`="2026-11-08")
    session$flushReact()
    expect_equal(nrow(state()$personas),0)
    expect_equal(nrow(state()$eventos),0)
    expect_equal(nrow(state()$elegibilidad),0)
    expect_equal(nrow(assessment()),0)
  })
})
test_that("editing project metadata does not reset territorial filters", {
  traffic<-new.env(parent=emptyenv());traffic$messages<-list()
  mock<-shiny::MockShinySession$new()
  mock$sendInputMessage<-function(inputId,message) {
    traffic$messages[[length(traffic$messages)+1L]]<-list(id=inputId,message=message)
  }
  shiny::testServer(mod_filters_server,session=mock,args=list(state=shiny::reactiveVal(demo_dataset()),catalog=load_catalog()),{
    session$flushReact()
    expect_true(length(traffic$messages)>0)
    traffic$messages<-list()
    d<-state();d$configuracion$alumno<-"Otro alumno";state(d);session$flushReact()
    expect_length(traffic$messages,0)
    d<-state();d$territorios<-d$territorios[1:2,];state(d);session$flushReact()
    expect_true(length(traffic$messages)>0)
  })
})
