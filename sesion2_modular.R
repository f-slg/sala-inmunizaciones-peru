# SESION 2 · Cada estudiante construye su propia sala situacional.
# Abra el .Rproj antes de ejecutar. Compatible con Linux, Windows y macOS.
# PASO 0. Dependencias y paquete de desarrollo
if (!requireNamespace("pkgload",quietly=TRUE)) stop("Ejecute source('instalar.R')")
pkgload::load_all(".",quiet=TRUE)
catalogo <- load_catalog()
datos <- demo_dataset(catalogo)  # SOLO SIMULADOS, sobre distritos reales

# PASO 1. Identificar el proyecto; sustituya estos datos.
mi_nombre <- "Escriba su nombre"
mi_ubigeo <- "090301"  # INEI: Lircay; cifras de demostracion, no datos reales.
datos$configuracion$alumno <- mi_nombre
mi_regla <- "PCV_3"  # tercera dosis de neumococo; denominador A1 (un ano).
informe_validacion <- validate_dataset(datos,catalogo)
print(informe_validacion)
stopifnot(!any(informe_validacion$nivel == "Error"))

# PASO 2. Cobertura y comprobacion manual, octubre 2026 cerrado.
tablero <- coverage_table(datos,catalogo,year=2026,month=10,territories=mi_ubigeo)
mi_cobertura <- tablero[tablero$regla_id == mi_regla,]
print(mi_cobertura)
stopifnot(nrow(mi_cobertura)==1L)
comprobacion <- mi_cobertura$dosis / mi_cobertura$denominador * 100
stopifnot(isTRUE(all.equal(comprobacion,mi_cobertura$cobertura)))
cat(sprintf("%s: %s, %s dosis / %s personas elegibles; fuente %s.\n",
            mi_ubigeo,fmt_pct(comprobacion),mi_cobertura$dosis,
            mi_cobertura$denominador,datos$configuracion$fuente))

# PASO 3. Desercion administrativa; no es abandono nominal demostrado.
desercion <- dropout_table(tablero,"PENTA_1","PENTA_3")
print(desercion)

# PASO 4. Fecha de corte, dosis exigibles y casos que requieren revision.
corte <- as.Date("2026-11-08")
seguimiento <- assess_nominal(datos,catalogo,corte)
print(head(seguimiento))
print(nominal_summary(seguimiento))
print(opportunity_table(seguimiento))
# Una dosis posterior al corte no cuenta. No sustituir una dosis faltante por otra.
# La tolerancia de oportunidad de 30 dias es PEDAGOGICA, no regla normativa universal.

# PASO 5. Tendencia mensual del proyecto nuevo.
serie <- monthly_trend(datos,mi_regla,2026,mi_ubigeo)
plot(serie$mes,serie$dosis,type="b",xlab="Mes",ylab="Dosis",
     main="Neumococo tercera dosis · datos simulados")
# Noviembre/diciembre pendientes permanecen NA: no se convierten en cero.

# PASO 6. Caso historico separado: 12 distritos FICTICIOS, 2023-2025.
# No mezclar este archivo con los distritos reales del nuevo proyecto.
legacy_dosis <- utils::read.csv(app_sys("extdata","legado","vacunacion_mensual.csv"),colClasses=c(ubigeo="character"),fileEncoding="UTF-8")
legacy_pob <- utils::read.csv(app_sys("extdata","legado","poblacion.csv"),colClasses=c(ubigeo="character"),fileEncoding="UTF-8")
a <- aggregate(dosis_aplicadas ~ anio + ubigeo + distrito,
               subset(legacy_dosis,vacuna=="PENTA3"),sum)
a <- merge(a,legacy_pob[c("anio","ubigeo","pob_menor_1")],by=c("anio","ubigeo"))
a$cobertura <- a$dosis_aplicadas/a$pob_menor_1*100
alto_pacay <- a[a$distrito=="Alto Pacay",]
print(alto_pacay)
plot(alto_pacay$anio,alto_pacay$cobertura,type="b",ylim=c(0,100),
     xlab="Ano",ylab="Cobertura (%)",main="Alto Pacay · caso historico SIMULADO")
abline(h=95,lty=2)
# Tres puntos describen una trayectoria; no justifican una proyeccion causal.

# PASO 7. Mapa interactivo con UBIGEOS REALES y cifras SIMULADAS del nuevo proyecto.
mapa_datos <- coverage_table(datos,catalogo,2026,10)
mapa_datos <- mapa_datos[mapa_datos$regla_id==mi_regla,]
build_leaflet(mapa_datos,"cobertura",tiles=FALSE)

# PASO 8. Programacion: leer supuestos antes de interpretar un pedido.
necesidades <- plan_requirements(datos$programacion,datos$inventario,
                                 datos$presentaciones,catalogo,corte)
print(head(necesidades))
# Presentaciones, volumen, reserva y perdida del ejemplo son SIMULADOS.
# Son metodos alternativos: poblacional / nominal / consumo. No sumarlos entre si.

# PASO 9. Guardar proyecto propio e informe agregado.
write_template("Mi_proyecto_privado.xlsx",dataset=datos)
export_aggregates("Mis_resultados.xlsx",list(coberturas=tablero,necesidades=necesidades))
# Escriba una accion concreta con evidencia, responsable, fecha e indicador.

# PASO 10. Abrir la sala. Detenga la app para continuar con otros comandos.
run_app(data=datos)
