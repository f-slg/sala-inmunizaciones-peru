test_that("a later dose never substitutes a missing first dose", {
  d<-small_nominal();d<-add_event(d,"PENTA","2","2027-04-01")
  a<-assess_nominal(d);expect_equal(a$estado[a$regla_id=="PENTA_1"],"pendiente")
  expect_false(nominal_summary(a)$completo)
})
test_that("events after cutoff are excluded", {
  d<-add_event(small_nominal(),"PENTA","1","2028-03-01")
  a<-assess_nominal(d);expect_equal(a$estado[a$regla_id=="PENTA_1"],"pendiente")
})
test_that("dates before birth cannot be valid or timely", {
  d<-add_event(small_nominal(),"PENTA","1","2026-12-01")
  a<-assess_nominal(d);expect_equal(a$estado[a$regla_id=="PENTA_1"],"registrada_no_valida")
  expect_true(is.na(a$oportuna[a$regla_id=="PENTA_1"]))
  expect_true("antes_nacimiento" %in% validate_dataset(d)$codigo)
})
test_that("interval validation follows a valid previous dose", {
  d<-small_nominal();d$configuracion$fecha_corte<-as.Date("2027-06-15")
  d<-add_event(d,"PENTA","1","2027-04-25");d<-add_event(d,"PENTA","2","2027-05-01","E2")
  a<-assess_nominal(d);expect_equal(a$estado[a$regla_id=="PENTA_2"],"registrada_no_valida")
})
test_that("two alternative routes are not evaluated simultaneously", {
  d<-small_nominal();a<-assess_nominal(d)
  expect_false(any(grepl("^HEXA",a$regla_id)))
  d$personas$ruta_id<-"hexavalente";a<-assess_nominal(d)
  expect_false(any(grepl("^PENTA|^IPV",a$regla_id)))
})
test_that("special eligibility blocks automatic complete certification", {
  d<-small_nominal();d$elegibilidad<-data.frame(persona_id="P1",grupo_id="VIH",inicio=as.Date("2027-01-01"),fin=as.Date("2028-01-01"),episodio_id="VIH1")
  a<-assess_nominal(d);expect_true(all(a$estado=="requiere_revision"));expect_true(is.na(nominal_summary(a)$completo))
})
test_that("empty nominal input is supported",expect_equal(nrow(assess_nominal(empty_dataset())),0))
