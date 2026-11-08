test_that("demonstration follows the canonical data contract", {
  expect_false(any(validate_dataset(demo_dataset())$nivel=="Error"))
})
test_that("duplicate, absent and zero denominators block imports", {
  d<-demo_dataset();d$poblacion<-rbind(d$poblacion,d$poblacion[1,]);expect_true("clave_duplicada" %in% validate_dataset(d)$codigo)
  d<-demo_dataset();d$poblacion$poblacion[1]<-NA;expect_true("numero_ausente" %in% validate_dataset(d)$codigo)
  d<-demo_dataset();d$poblacion$poblacion[d$poblacion$grupo_id=="A1"]<-0;expect_true("denominador_cero" %in% validate_dataset(d)$codigo)
})
test_that("joining uses INEI code rather than district spelling", {
  d<-demo_dataset();d$territorios$distrito<-toupper(d$territorios$distrito)
  expect_true(all(is.finite(coverage_table(d,year=2026,month=10)$denominador)))
})
test_that("workbook round trip preserves text ubigeos and dates", {
  file<-tempfile(fileext=".xlsx");write_template(file,example=TRUE)
  x<-import_workbook(file);expect_true(x$exito,info=paste(x$informe$detalle,collapse="; "))
  expect_identical(x$datos$territorios$ubigeo,c("090301","090302","090303"))
  expect_s3_class(x$datos$eventos$fecha,"Date")
  expect_equal(nrow(x$datos$eventos),nrow(demo_dataset()$eventos))
})
test_that("empty template has headers without polluting data with examples", {
  file<-tempfile(fileext=".xlsx");write_template(file)
  expect_equal(nrow(readxl::read_excel(file,sheet="poblacion")),0)
  expect_true("ejemplos" %in% readxl::excel_sheets(file))
})
test_that("malformed workbook returns structured rejection", {
  x<-import_workbook(tempfile(fileext=".xlsx"));expect_false(x$exito);expect_null(x$datos);expect_true(all(x$informe$nivel=="Error"))
})
test_that("public exports reject nominal columns", {
  expect_error(export_aggregates(tempfile(fileext=".xlsx"),list(personas=data.frame(persona_id="P1"))),"identificadores")
})
test_that("date parsing is deterministic across operating systems", {
  expect_equal(parse_date(c("2026-11-08","46334")),as.Date(c("2026-11-08","2026-11-08")))
  expect_true(is.na(parse_date("08/11/2026")))
})
test_that("direct identifiers and undocumented presentations are rejected", {
  d<-demo_dataset();d$personas$dni<-"12345678"
  expect_true("identificadores_directos" %in% validate_dataset(d)$codigo)
  d<-demo_dataset();d$presentaciones<-d$presentaciones[FALSE,]
  expect_true("sin_presentacion" %in% validate_dataset(d)$codigo)
})
test_that("private project round trip preserves student identification", {
  file<-tempfile(fileext=".xlsx");d<-demo_dataset();d$configuracion$alumno<-"Mi estudiante"
  write_template(file,dataset=d);x<-import_workbook(file)
  expect_true(x$exito);expect_identical(x$datos$configuracion$alumno,"Mi estudiante")
})
test_that("generated tables have no dangling drawing or printer relationships", {
  file<-tempfile(fileext=".xlsx");write_template(file,example=TRUE)
  dest<-tempfile();dir.create(dest);utils::unzip(file,exdir=dest)
  rels<-list.files(file.path(dest,"xl","worksheets","_rels"),full.names=TRUE)
  content<-paste(vapply(rels,function(rel) paste(readLines(rel,warn=FALSE),collapse=""),character(1)),collapse="")
  expect_false(grepl("relationships/(drawing|vmlDrawing|printerSettings)",content))
})
