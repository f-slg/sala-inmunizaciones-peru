test_that("dictionary covers every schema field with description and unit", {
  dictionary<-variable_dictionary()
  expected<-unlist(lapply(names(data_schema()),function(n) paste(n,data_schema()[[n]],sep="/")))
  expect_setequal(paste(dictionary$hoja,dictionary$variable,sep="/"),expected)
  expect_false(anyNA(dictionary$definicion));expect_true(all(nzchar(dictionary$definicion)))
  expect_true("unidad" %in% names(dictionary))
  expect_match(dictionary$tipo[dictionary$hoja=="plan_mejora" & dictionary$variable=="meta"],"Texto")
})
test_that("territorial catalogue spans departments without inventing health data", {
  geography<-territory_catalog()
  expect_true(nrow(geography)>1800);expect_true(length(unique(geography$departamento))>=25)
  expect_true(all(c("010101","150101","040101","160101","080101") %in% geography$ubigeo))
  expect_identical(names(geography),data_schema()$territorios)
})
test_that("scope template preserves chosen districts and leaves health tables empty", {
  x<-territory_catalog();x<-x[x$ubigeo %in% c("010101","150101"),]
  file<-tempfile(fileext=".xlsx");write_template(file,territories=x)
  z<-as.data.frame(readxl::read_excel(file,sheet="territorios",col_types="text"))
  expect_equal(z,x,ignore_attr=TRUE)
  expect_equal(nrow(readxl::read_excel(file,sheet="poblacion")),0)
  expect_equal(nrow(readxl::read_excel(file,sheet="vacunacion")),0)
  expect_true(all(c("diccionario","cat_territorios","cat_opciones") %in% readxl::excel_sheets(file)))
  expect_error(write_template(file,example=TRUE,territories=x),"solo para plantillas vacias")
})
test_that("dropdowns use standard OOXML and named regions", {
  file<-tempfile(fileext=".xlsx");write_template(file)
  temp<-tempfile();dir.create(temp);utils::unzip(file,exdir=temp)
  workbook<-paste(readLines(file.path(temp,"xl","workbook.xml"),warn=FALSE),collapse="")
  expect_match(workbook,"lista_ubigeo");expect_match(workbook,"lista_regla_id")
  schema<-data_schema()
  for(sheet in c("poblacion","vacunacion","personas","eventos","inventario","movimientos")) {
    i<-match(sheet,names(schema))+1L
    text<-paste(readLines(file.path(temp,"xl","worksheets",paste0("sheet",i,".xml")),warn=FALSE),collapse="")
    expect_match(text,'type="list"');expect_match(text,"<formula1>lista_")
    expect_false(grepl("x14:dataValidation",text,fixed=TRUE))
  }
})
test_that("population workbook and dictionary are valid standalone resources", {
  f<-tempfile(fileext=".xlsx");write_population_template(f)
  expect_true(all(c("poblacion","territorios","diccionario","cat_territorios") %in% readxl::excel_sheets(f)))
  g<-tempfile(fileext=".xlsx");write_catalogue(g)
  expect_identical(readxl::excel_sheets(g)[1],"diccionario")
})
test_that("project plan target text survives workbook round trip", {
  d<-demo_dataset();expect_identical(d$plan_mejora$meta,"95 %")
  f<-tempfile(fileext=".xlsx");write_template(f,dataset=d);z<-import_workbook(f)
  expect_true(z$exito);expect_identical(z$datos$plan_mejora$meta,"95 %")
})
test_that("territory picker combines provinces without duplicate districts", {
  shiny::testServer(mod_territory_picker_server,{
    g<-territory_catalog()
    for(code in c("150101","010101","040101")) {
      z<-g[g$ubigeo==code,]
      session$setInputs(department=z$departamento,province=z$provincia,districts=code,all=FALSE)
      session$setInputs(add=if(code=="150101") 1 else if(code=="010101") 2 else 3)
    }
    expect_setequal(chosen()$ubigeo,c("150101","010101","040101"))
    session$setInputs(add=4);expect_equal(nrow(chosen()),3)
    session$setInputs(clear=1);expect_equal(nrow(chosen()),0)
  })
})
