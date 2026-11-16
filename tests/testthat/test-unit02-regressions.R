test_that("a completely absent district remains in coverage and blocks the aggregate", {
  d<-unit02_dataset()
  d$vacunacion<-d$vacunacion[!(d$vacunacion$ubigeo=="090303" & d$vacunacion$regla_id=="PENTA_3"),]
  x<-coverage_table(d,year=2026,month=12)
  z<-x[x$regla_id=="PENTA_3",]
  expect_equal(nrow(z),8)
  expect_false(z$reporte_completo[z$ubigeo=="090303"])
  expect_true(is.na(z$cobertura[z$ubigeo=="090303"]))
  s<-coverage_summary(z)
  expect_equal(s$territorios,8);expect_equal(s$reportes_completos,7)
  expect_true(is.na(s$cobertura));expect_equal(s$denominador,2600)
  expect_true(all(is.na(district_priority(d,year=2026)$orden)))
})
test_that("empty selection cannot expand monthly trends to all districts", {
  x<-monthly_trend(unit02_dataset(),"PENTA_3",2026,character())
  expect_true(all(is.na(x$dosis)));expect_true(all(!x$reporte_completo))
  expect_equal(nrow(district_priority(unit02_dataset(),year=2026,territories=character())),0)
})
test_that("presentation integers and product-wide parameters are validated before import", {
  d<-demo_dataset();d$presentaciones$dosis_frasco[1]<-1.5
  expect_true("entero" %in% validate_dataset(d)$codigo)
  file<-tempfile(fileext=".xlsx");write_template(file,dataset=d)
  z<-import_workbook(file);expect_false(z$exito);expect_null(z$datos)
  d<-demo_dataset();d$presentaciones$capacidad_caja[1]<-1.5
  expect_true("entero" %in% validate_dataset(d)$codigo)
  d<-demo_dataset();i<-which(d$programacion$regla_id=="PENTA_1")[1]
  d$programacion$reserva_dosis[i]<-21
  expect_true("parametros_producto" %in% validate_dataset(d)$codigo)
})
test_that("Unit 02 exactly matches the exercise and retains monthly integer counts", {
  d<-unit02_dataset();x<-coverage_table(d,year=2026,month=12)
  z<-x[x$regla_id=="PENTA_3",]
  expect_false(any(validate_dataset(d)$nivel=="Error"))
  expect_equal(nrow(d$territorios),8);expect_equal(nrow(d$vacunacion),288)
  expect_equal(range(z$cobertura),c(62,98))
  expect_equal(sum(dropout_table(x,"PENTA_1","PENTA_3")$desercion>10),4)
  expect_equal(sum(d$contexto_territorial$poblacion_dispersa & d$contexto_territorial$dificil_acceso),3)
  expect_equal(sum(d$contexto_territorial$alta_sin_seguimiento),2)
  expect_equal(sum(d$contexto_territorial$brote_tosferina_ultimo_anio),1)
  expect_true(all(d$vacunacion$dosis==floor(d$vacunacion$dosis)))
  expect_match(d$configuracion$fuente,"SIMULADO")
})
test_that("priority is transparent, limited by budget and reacts to source changes", {
  d<-unit02_dataset();x<-district_priority(d,year=2026)
  expect_identical(x$distrito[1:3],c("Ccochaccasa","Lircay","Anchonga"))
  expect_equal(sum(x$decision=="Intervencion intensiva"),3)
  expect_match(x$justificacion[1],"brote")
  expect_true(all(nzchar(x$criterio_orden)))
  expect_equal(sum(district_priority(d,year=2026,slots=2)$decision=="Intervencion intensiva"),2)
  d$contexto_territorial$brote_tosferina_ultimo_anio[]<-FALSE
  expect_identical(district_priority(d,year=2026)$distrito[1:3],c("Lircay","Anchonga","Callanmarca"))
})
test_that("future, absent or invalid context cannot produce a definitive priority", {
  d<-unit02_dataset();expect_true(all(is.na(district_priority(d,year=2026,month=11)$orden)))
  d$contexto_territorial<-d$contexto_territorial[-1,]
  expect_true(all(is.na(district_priority(d,year=2026)$orden)))
  d<-unit02_dataset();d$contexto_territorial$ninos_sin_seguimiento[1]<-501
  expect_true("padron" %in% validate_dataset(d)$codigo)
  old<-demo_dataset();old$contexto_territorial<-NULL
  expect_false(any(validate_dataset(old)$nivel=="Error"))
})
test_that("traffic light boundaries keep absence and values requiring review separate", {
  expect_identical(coverage_status(c(79.9,80,94.9,95,100,100.1,NA)),c("Baja cobertura","En alerta","En alerta","Meta alcanzada","Meta alcanzada","Revisar datos","Sin dato"))
  expect_identical(dropout_status(c(-1,0,10,10.1,NA)),c("Revisar comparabilidad","Dentro del umbral","Dentro del umbral","Desercion alta","Sin dato"))
  expect_no_error(data_table(district_priority(unit02_dataset(),year=2026)))
})
test_that("Unit 02 loads through the workspace and priority is exported with the filters", {
  app<-run_app()
  shiny::testServer(app,{
    session$setInputs(`workspace-unit02`=1)
    session$setInputs(`filters-year`="2026",`filters-month`=12,`filters-units`=sprintf("0903%02d",1:8),`filters-rule`="PENTA_3",`filters-cutoff`="2026-12-31",`priority-slots`=3)
    session$flushReact()
    expect_equal(nrow(state()$territorios),8)
    expect_equal(sum(priority()$decision=="Intervencion intensiva"),3)
    expect_identical(tables()$priorizacion,priority())
    for(n in c("priority-reading","priority-ranking-table","overview-cards","coverage-plot","trends-plot","map-map","quality-table")) expect_no_error(output[[n]])
  })
})
