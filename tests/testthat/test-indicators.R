test_that("coverage weights denominators and does not average percentages", {
  d<-demo_dataset();x<-coverage_table(d,year=2026,month=10);x<-x[x$regla_id=="PCV_3",]
  s<-coverage_summary(x)
  expect_equal(s$cobertura,sum(x$dosis)/sum(x$denominador)*100)
  expect_false(isTRUE(all.equal(s$cobertura,mean(x$cobertura))))
})
test_that("absent or pending reports cannot become zero doses", {
  d<-demo_dataset();x<-coverage_table(d,year=2026,month=11)
  expect_true(all(is.na(x$cobertura)))
  d$vacunacion<-d$vacunacion[!(d$vacunacion$mes==2 & d$vacunacion$ubigeo=="090301"),]
  x<-coverage_table(d,year=2026,month=10);expect_true(all(is.na(x$cobertura[x$ubigeo=="090301"])))
})
test_that("missing initial/final vaccine does not crash dropout", {
  d<-demo_dataset();d$vacunacion<-d$vacunacion[d$vacunacion$regla_id=="BCG_RN",]
  x<-coverage_table(d,year=2026,month=10)
  expect_equal(nrow(dropout_table(x,"PENTA_1","PENTA_3")),0)
})
test_that("PCV third dose uses one-year population", {
  d<-demo_dataset();d$poblacion$poblacion[d$poblacion$grupo_id=="A1"]<-400
  x<-coverage_table(d,year=2026,month=10)
  expect_true(all(x$denominador[x$regla_id=="PCV_3"]==400))
})
test_that("calendar months and upward gap rounding are exact", {
  expect_equal(add_months(as.Date("2024-01-31"),1),as.Date("2024-02-29"))
  d<-demo_dataset();d$poblacion$poblacion[d$poblacion$grupo_id=="A1"]<-101
  x<-coverage_table(d,year=2026,month=10);z<-x[x$regla_id=="PCV_3",]
  expect_equal(z$brecha_95,pmax(0,96-z$dosis))
})
test_that("empty territorial selection returns no results", {
  expect_equal(nrow(coverage_table(demo_dataset(),year=2026,month=10,territories=character())),0)
})
