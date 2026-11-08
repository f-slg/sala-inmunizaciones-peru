test_that("wastage is divided by survival proportion, not increased by a flat percent", {
  d<-demo_dataset();p<-d$programacion[1,,drop=FALSE];p$poblacion_elegible<-100;p$meta<-1;p$recuperacion<-0;p$perdida<-.2;p$reserva_dosis<-0;p$transito_dosis<-0
  x<-plan_requirements(p,d$inventario[FALSE,],d$presentaciones,cutoff=as.Date("2026-11-08"))
  expect_equal(x$dosis_brutas,125);expect_equal(x$pedido_neto,125)
})
test_that("stock is subtracted once after pooling doses of a product", {
  d<-demo_dataset();p<-d$programacion[d$programacion$ubigeo=="090301" & d$programacion$regla_id %in% c("PENTA_1","PENTA_2","PENTA_3"),]
  p$poblacion_elegible<-100;p$meta<-1;p$recuperacion<-0;p$perdida<-0;p$reserva_dosis<-10;p$transito_dosis<-20
  pr<-d$presentaciones;pr$dosis_frasco[pr$producto_id=="PENTA"]<-10
  x<-plan_requirements(p,d$inventario,pr,cutoff=as.Date("2026-11-08"))
  expect_equal(nrow(x),1);expect_equal(x$pedido_neto,250);expect_equal(x$frascos,25)
})
test_that("expired and quarantined stock cannot cover needs", {
  d<-demo_dataset();p<-d$programacion[1,,drop=FALSE];inv<-d$inventario
  inv$vencimiento<-as.Date("2025-01-01");x<-plan_requirements(p,inv,d$presentaciones,cutoff=as.Date("2026-11-08"));expect_equal(x$stock_utilizable,0)
  inv$vencimiento<-as.Date("2028-01-01");inv$cuarentena<-TRUE
  expect_equal(plan_requirements(p,inv,d$presentaciones,cutoff=as.Date("2026-11-08"))$stock_utilizable,0)
})
test_that("loss of 100 percent is rejected", {
  d<-demo_dataset();p<-d$programacion[1,,drop=FALSE];p$perdida<-1
  expect_error(plan_requirements(p,d$inventario,d$presentaciones),"perdida")
})
test_that("missing presentations require explicit correction", {
  d<-demo_dataset();expect_error(plan_requirements(d$programacion[1,,drop=FALSE],d$inventario,d$presentaciones[FALSE,]),"presentacion unica")
})
test_that("inventory movements are applied exactly once and future movements excluded", {
  d<-demo_dataset();i<-d$inventario[1,,drop=FALSE]
  m<-data.frame(movimiento_id=c("M1","M2"),fecha=as.Date(c("2026-10-01","2027-01-01")),ubigeo=i$ubigeo,producto_id=i$producto_id,lote=i$lote,tipo=c("aplicacion","entrada"),dosis=c(10,100))
  expect_equal(inventory_reconciliation(i,m,as.Date("2026-11-08"))$saldo_calculado,30)
})
test_that("stock dated after cutoff cannot leak into historical balances", {
  d<-demo_dataset();i<-d$inventario[1,,drop=FALSE];i$fecha_saldo<-as.Date("2027-01-01")
  expect_true(is.na(inventory_reconciliation(i,d$movimientos,as.Date("2026-11-08"))$saldo_calculado))
})

test_that("expiry sorting never assigns a balance to a different product", {
  d<-demo_dataset();i<-d$inventario[1:2,,drop=FALSE]
  i$saldo_dosis<-c(100,200);i$vencimiento<-as.Date(c("2029-01-01","2028-01-01"))
  m<-data.frame(movimiento_id="MOVE1",fecha=as.Date("2026-10-01"),ubigeo=i$ubigeo[1],
    producto_id=i$producto_id[1],lote=i$lote[1],tipo="aplicacion",dosis=30)
  balance<-inventory_reconciliation(i,m,as.Date("2026-11-08"))
  expect_identical(balance$producto_id,rev(i$producto_id))
  adjusted<-apply_inventory_balances(i,balance)
  expect_equal(adjusted$saldo_dosis,c(70,200))
  expect_identical(adjusted$producto_id,i$producto_id)
  expect_error(apply_inventory_balances(i,balance[1,,drop=FALSE]),"Falta saldo")
  expect_error(apply_inventory_balances(i,rbind(balance,balance[1,])),"duplicados")
})
