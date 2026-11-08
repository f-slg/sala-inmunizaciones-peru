test_that("mapsPERU provides real georeferenced INEI districts", {
  b<-peru_boundaries();expect_s3_class(b,"sf");expect_true(nrow(b)>1800);expect_equal(sf::st_crs(b)$epsg,4326)
  expect_true(all(c("090301","150101","010101") %in% b$ubigeo));expect_false(anyDuplicated(b$ubigeo)>0)
})
test_that("map keeps missing codes visible as diagnostics", {
  x<-data.frame(ubigeo=c("090301","999999"),cobertura=c(80,90),dosis=c(80,90),denominador=100,brecha_95=c(15,5),alerta="Prueba")
  j<-map_join(x);expect_equal(j$sin_geometria,"999999");expect_equal(nrow(j$geometria),1)
})
test_that("interactive map can render without external tiles", {
  d<-demo_dataset();x<-coverage_table(d,year=2026,month=10);x<-x[x$regla_id=="PCV_3",]
  m<-build_leaflet(x,tiles=FALSE);expect_s3_class(m,"leaflet")
  methods<-vapply(m$x$calls,function(z) z$method,character(1));expect_true("addPolygons" %in% methods);expect_false("addTiles" %in% methods)
})
