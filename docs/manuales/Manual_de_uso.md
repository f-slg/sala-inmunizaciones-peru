# Manual de uso
Sala situacional de inmunizaciones del Perú
Versión 0.2.0 · Guía del estudiante y del docente · 8 de noviembre de 2026

Cada estudiante construye una sala propia: delimita su territorio, documenta sus fuentes, valida sus datos, interpreta indicadores y propone acciones verificables.

Autoría del proyecto: Dr. Ronald Fabricio Salas Guerrero.
Repositorio: https://github.com/f-slg/sala-inmunizaciones-peru

Este manual describe la versión comprobada 0.2.0. Los ejemplos sanitarios son simulados; los distritos y sus límites son reales. El proyecto es educativo e independiente del MINSA. Su evaluación nominal tiene límites explícitos y no genera indicaciones clínicas.
<!-- PAGE -->
# Ruta de lectura
1. Preparar el equipo y abrir la sala.
2. Reconocer la interfaz y los cortes.
3. Elegir el territorio propio.
4. Conocer los libros y el diccionario.
5. Completar población y vacunación.
6. Cargar y corregir los datos.
7. Interpretar coberturas, tendencias y mapas.
8. Revisar información nominal.
9. Programar dosis, frascos e insumos.
10. Conciliar inventario y cadena de frío.
11. Guardar, informar y entregar el trabajo.
12. Resolver problemas frecuentes.
13. Comprobar el primer ejercicio y la entrega.

Para comenzar hoy: lea los capítulos 1 a 7 y realice el ejercicio del capítulo 13. Añada los componentes nominal y logístico cuando disponga de sus fuentes.

Convención: los textos entre comillas reproducen botones de la aplicación. Los códigos, nombres de hojas y comandos deben conservar su escritura original.
<!-- PAGE -->
# 1. Preparar el equipo y abrir la sala
## Paso 1. Obtener una copia independiente
Descargue el repositorio con Code → Download ZIP, descomprímalo y abra salainmunizaciones.Rproj en RStudio. No trabaje dentro del archivo ZIP. Cada alumno debe conservar su propia carpeta.
## Paso 2. Instalar las dependencias
El proyecto requiere R 4.2 o superior. RStudio facilita su uso. La instalación inicial necesita conexión a CRAN. En la consola de R, desde la carpeta del proyecto:
```r
source("instalar.R")
```
Espere el mensaje de dependencias listas. Si el script informa paquetes faltantes, resuelva la instalación antes de continuar.
## Paso 3. Ejecutar
Abra app.R y pulse Run App, o ejecute:
```r
shiny::runApp()
```
La aplicación se abre con una demostración simulada. Pulse Stop en RStudio para detenerla. Si la aplicación está ejecutándose, la consola puede permanecer ocupada: es normal.
## Diferencias entre sistemas
| Sistema | Preparación |
| Windows | Instale R y RStudio para Windows; prefiera paquetes binarios. |
| macOS | Elija R para Apple Silicon o Intel según su equipo. |
| Linux | sf puede requerir GDAL, GEOS, PROJ y UDUNITS2; consulte el README. |

No necesita Excel instalado para ejecutar la sala. Para editar las plantillas use un editor compatible con XLSX y listas OOXML. La aplicación tampoco requiere Python ni Node.js.
<!-- PAGE -->
# 2. Reconocer la interfaz y los cortes
La barra superior contiene 13 pestañas. La barra lateral define el año, mes de cierre, distritos, regla de vacuna/dosis y fecha de corte nominal e inventario.
| Pestaña | Pregunta que responde |
| Resumen | ¿Cuál es el resultado agregado del ámbito? |
| Mi proyecto | ¿Quién trabaja, qué datos carga y qué territorio utiliza? |
| Población | ¿Qué denominadores y fuentes sustentan el análisis? |
| Coberturas | ¿Cuántas dosis se registraron frente a la población elegible? |
| Tendencias | ¿Cómo cambia el registro y la continuidad administrativa? |
| Mapa | ¿Dónde se localizan los resultados de una regla? |
| Nominal | ¿Qué dosis específicas resultan evaluables al corte? |
| Programación | ¿Qué dosis e insumos requiere el horizonte definido? |
| Inventario | ¿Qué saldo y condición tiene cada lote? |
| Calidad | ¿Qué problemas limitan la lectura? |
| Norma | ¿Qué productos, reglas, fuentes y variables se utilizan? |
| Plan de mejora | ¿Qué acción responde a cada problema? |
| Informe | ¿Cómo exporto los resultados y su trazabilidad? |

El cierre administrativo usa año y mes. El corte nominal y de inventario usa una fecha exacta. Son controles distintos: no suponga que cambiar uno modifica el otro.

En la demostración, use 2026 y octubre para el cierre administrativo. Noviembre y diciembre están pendientes. La fecha nominal puede permanecer en 2026-11-08 para reproducir los ejemplos del proyecto.
<!-- PAGE -->
# 3. Elegir el territorio propio
## Selección paso a paso
1. Abra “Mi proyecto”.
2. En “Seleccione su territorio en el Perú”, elija departamento y provincia.
3. Busque y seleccione uno o varios distritos. También puede marcar “Incluir todos los distritos de esta provincia”.
4. Pulse “Agregar a mi seleccion”. Puede repetirlo con otras provincias o departamentos.
5. Compruebe los nombres y ubigeos en “Distritos elegidos”. Los distritos repetidos no se duplican.
6. Observe la vista territorial y descargue “Plantilla integral de mi territorio”.

La selección genera una plantilla con la hoja territorios precargada. No cambia por sí sola el conjunto analítico de la sesión. Los filtros y el mapa de indicadores cambiarán después de completar y cargar el libro.

La vista previa solo muestra geografía. No contiene datos de población ni coberturas. “Limpiar seleccion” vacía la selección para descargar plantillas; no borra los datos analíticos que ya estaban cargados.
## Alcance nacional
El catálogo de mapsPERU 2.0.1 contiene 1.891 distritos de los 24 departamentos y Callao. No es un registro INEI actualizado en línea. Si falta un distrito nuevo, registre su ubigeo real verificado: el desplegable admite conservarlo tras una advertencia y el mapa informará si falta su geometría.

No reemplace el código por el de un distrito vecino. Si el ámbito es un establecimiento, este modelo no aporta polígonos de establecimientos: documente el establecimiento en la identificación y utilice el ubigeo distrital correspondiente.
<!-- PAGE -->
# 4. Conocer los libros y el diccionario
| Recurso | Finalidad |
| Plantilla_integral.xlsx | Libro vacío para cargar el conjunto completo del alumno. |
| Demostracion_integral.xlsx | Datos sanitarios simulados para aprender y comprobar resultados. |
| Plantilla_poblacion.xlsx | Preparar población y territorios; después copiar ambas hojas al libro integral. |
| Diccionario_variables.xlsx | Consultar definiciones y códigos sin abrir la aplicación. |
| Calculadora_necesidades.xlsx | Recurso de cálculo independiente; no es una plantilla de carga. |

El diccionario contiene 96 entradas identificadas por hoja y variable. Un mismo nombre puede tener una interpretación distinta según la hoja: meta en programacion es una proporción; meta en plan_mejora es un texto descriptivo.

Los libros de carga incluyen las hojas diccionario, cat_productos, cat_reglas, cat_grupos, cat_fuentes, cat_territorios y cat_opciones. Consulte estos catálogos; no los modifique para inventar nuevos códigos aceptados por el programa.
## Reglas de edición
- Conserve los nombres de las hojas y sus encabezados.
- Escriba desde la fila 2. Las listas y controles están preparados hasta la fila 5001 en las plantillas vacías.
- Use fechas AAAA-MM-DD o fechas nativas de Excel. Los códigos son texto; el ubigeo conserva seis dígitos y sus ceros iniciales.
- Use las listas para grupo, regla, producto, dosis, sexo, ruta, estrategia, reporte y movimientos.
- No pegue unidades dentro de campos numéricos: escriba 120, no “120 personas”.

Pegar celdas puede eludir controles de una hoja de cálculo. La validación de R sigue siendo obligatoria. El libro separado de población no se importa por sí solo como proyecto completo.
<!-- PAGE -->
# 5. Completar población y vacunación
## Libro mínimo para el análisis administrativo
Las hojas configuracion, poblacion, territorios y vacunacion son obligatorias. Las demás deben conservar sus encabezados y pueden quedar vacías si no se usa ese componente.
| Hoja | Una fila representa |
| configuracion | Identificación del proyecto, año, corte, fuente y versión. Use una fila. |
| territorios | Un distrito con ubigeo, distrito, provincia y departamento. |
| poblacion | Una población por año, ubigeo y grupo, con fuente y versión. |
| vacunacion | Un reporte mensual por año, mes, ubigeo, regla y estrategia. |

En poblacion, seleccione grupo_id desde el catálogo. No utilice la población total como denominador de todas las vacunas. Los grupos especiales pueden superponerse y no deben sumarse como personas únicas.

En vacunacion, seleccione regla_id. Esa regla determina la dosis, el producto, el grupo y la ruta. Para reproducir cobertura regular, utilice estrategia regular. Registre cada mes desde enero hasta el cierre: la cobertura acumulada exige el reporte completo del periodo.
## Cero, pendiente y ejemplo
| Situación | dosis | estado_reporte |
| Reporte completo sin aplicaciones | 0 | completo |
| Reporte completo con aplicaciones | Conteo entero | completo |
| Reporte aún no disponible | Celda vacía | pendiente |

Ejemplo SIMULADO: PCV_3 en Lircay utiliza el grupo de población de un año; 90 dosis acumuladas y 120 personas dan 75 %. Las 90 dosis deben estar distribuidas en sus reportes mensuales, no repetirse como acumulado en cada mes.

Documente institución o sistema fuente, fecha de extracción, año del denominador y versión. No copie los valores simulados al libro real del establecimiento.
<!-- PAGE -->
# 6. Cargar y corregir los datos
1. Guarde una copia del XLSX completado y cierre su edición.
2. En “Mi proyecto”, utilice “Cargar libro XLSX”. El límite configurado es 30 MB.
3. Lea “Resultado de validacion”. Revise tabla, código y detalle de cada incidencia.
4. Si hay errores, corrija el libro y vuelva a cargarlo. Un archivo rechazado no sustituye el conjunto anterior.
5. Si la carga es aceptada, compruebe “Contenido del proyecto”, la identificación y los distritos disponibles en los filtros.
6. Abra “Calidad” para revisar también las limitaciones analíticas.

“Guardar identificacion” actualiza alumno y ámbito en la sesión. Para cambiar fuentes, versión y demás datos, edite configuracion en el libro y vuelva a cargarlo. Mantenga una copia privada del archivo aceptado.
## Correcciones habituales
| Incidencia | Acción |
| Falta una hoja obligatoria | Parta de la plantilla integral y conserve sus cuatro hojas mínimas. |
| Denominador duplicado | Deje una fila por año, ubigeo y grupo; concilie las fuentes antes de sumar. |
| Regla o producto desconocido | Consulte los códigos del catálogo de la aplicación. |
| Dosis antes del nacimiento | Revise ambas fechas en la fuente original. |
| Ubigeo incompleto | Restituya el código INEI de seis caracteres. |
| Reporte pendiente con número | Deje dosis vacía; no use el acumulado de otro mes. |

Una carga aceptada acredita el contrato y los controles implementados. No demuestra que la fuente sea exhaustiva ni que una decisión clínica sea correcta. Un aviso de revisión de regla requiere documentación, aunque el archivo sea técnicamente legible.
<!-- PAGE -->
# 7. Interpretar coberturas, tendencias y mapas
## Cobertura y brecha
Cobertura = dosis de una regla / población de su grupo × 100. La brecha a 95 % es max(0, redondeo superior de población × 0.95 − dosis).

Compare la misma regla, población, estrategia y periodo. El agregado territorial utiliza suma de dosis / suma de denominadores. No promedie porcentajes distritales ni sume denominadores de distintas reglas.

Si faltan meses o reportes, el resultado acumulado queda ausente. Una cobertura superior a 100 % exige revisar numerador, residencia, denominador y periodo; no se recorta automáticamente a 100 %.
## Continuidad y tendencias
La deserción administrativa es (primera dosis − última dosis) / primera dosis × 100. Una cifra negativa señala falta de comparabilidad u otra situación que debe investigarse; no prueba abandono individual. Con primera dosis cero, la proporción no es calculable.

Compare enero–octubre con enero–octubre, no con un año completo. Una serie describe cambios y no demuestra por sí sola sus causas.
## Mapa de indicadores
Seleccione una sola regla, amplíe o desplace el mapa y pulse un distrito para consultar dosis, población, cobertura y brecha. El fondo OpenStreetMap es opcional y requiere conexión; los límites se obtienen del paquete instalado.
| Categoría de cobertura | Lectura |
| Menor de 80 % | Baja: rojo. |
| 80 a menos de 95 % | Intermedia: amarillo. |
| 95 a 100 % | Meta: verde. |
| Mayor de 100 % | Revisar: azul. |
| Sin dato | Gris; no equivale a cero. |

Los colores de cobertura usan umbrales absolutos. Para brechas se utiliza otra escala. La disponibilidad de geometría no acredita la calidad del indicador sanitario.
<!-- PAGE -->
# 8. Revisar información nominal
Este componente es opcional y solo está disponible en la sesión privada. Utilice identificadores seudonimizados; no cargue nombres, DNI, teléfonos ni direcciones.
| Hoja | Contenido |
| personas | Una persona: identificador, ubigeo, nacimiento, sexo y ruta. |
| eventos | Una aplicación: identificador único, persona, producto, dosis, fecha, lote y episodio. |
| elegibilidad | Condición o episodio de pertenencia a un grupo, con inicio y fin. |

Las rutas de entrada son penta_ipv, hexavalente y revision. Declare historias mixtas o no modeladas para revisión; no fuerce la ruta para obtener un resultado completo.
## Cómo leer los resultados
- Consulte el cumplimiento por persona y las dosis específicas exigibles al corte.
- Distinga aplicación registrada, dosis válida para la regla y oportunidad evaluable.
- Una dosis posterior al corte no mejora retrospectivamente el indicador.
- Una dosis posterior del esquema no reemplaza una anterior faltante.
- Las dosis fuera de edad o los casos en revisión no se convierten automáticamente en una necesidad nominal.

El catálogo tiene 33 productos y 116 reglas; 34 reglas cuentan con evaluación nominal educativa automatizada. La inclusión de una vacuna en el catálogo no significa que toda su elegibilidad clínica esté automatizada.

La tolerancia de oportunidad de 30 días es pedagógica. Una fecha sin hora no demuestra cumplimiento de ventanas neonatales medidas en horas. Lea el estado y la limitación de cada regla en “Norma”.

Los pendientes nominales y la brecha administrativa son medidas distintas. No sume pendientes a la programación si ya están incluidos en recuperación o en la población programada.
<!-- PAGE -->
# 9. Programar dosis, frascos e insumos
Complete programacion y presentaciones. Si se dispone de existencias, complete inventario y movimientos. Cada fila de programación corresponde a año, distrito y regla; la agrupación para el pedido se realiza por producto físico.
## Parámetros que debe documentar
| Campo | Unidad y criterio |
| poblacion_elegible | Personas de esa dosis; conciliar alternativas y grupos superpuestos. |
| meta | Proporción: 0.95 representa 95 %. |
| recuperacion | Dosis adicionales que no están ya incluidas. |
| perdida | Proporción menor que 1; 0.10 representa 10 %. |
| reserva_dosis y transito_dosis | Dosis por producto; repetir el mismo valor en sus reglas. |
| dias_horizonte y dias_reposicion | Días; coherentes para cada producto. |
| dosis_frasco y volumen_cm3_dosis | Presentación real y volumen empacado por dosis. |

Dosis a administrar = redondeo superior de población elegible × meta + recuperación. Necesidad bruta = dosis a administrar / (1 − pérdida). El cálculo agrupa dosis del mismo producto antes de redondear frascos.

Pedido neto = max(0, necesidad bruta + reserva − stock utilizable − tránsito confirmado). Frascos = redondeo superior de pedido neto / dosis por frasco.

Ejemplo SIMULADO de una regla: 100 personas, meta 0.95, recuperación 5 y pérdida 0.10 → 100 dosis a administrar y 112 brutas. Con reserva 10, stock utilizable 20 y tránsito 12 → pedido neto 90 dosis. Si cada frasco tiene 10 dosis, son 9 frascos. Es un ejercicio aritmético, no una presentación recomendada de una vacuna.

La aplicación también estima jeringas, diluyentes, cajas y volumen. Los métodos poblacional, nominal y por consumo son perspectivas alternativas; no sume sus resultados sin conciliación.
<!-- PAGE -->
# 10. Conciliar inventario y cadena de frío
## Registro por lote
En inventario registre un saldo inicial con fecha_saldo, vencimiento y cuarentena. La clave es ubigeo + producto_id + lote. En movimientos registre entradas, salidas, aplicaciones, pérdidas o ajustes, cada uno con identificador único.

Saldo calculado = saldo inicial + entradas y ajustes positivos − salidas, aplicaciones, pérdidas y ajustes negativos. Solo se agregan movimientos posteriores a fecha_saldo y hasta el corte. No registre un saldo final y luego vuelva a sumar los movimientos que ya contiene.

Revise “Inventario” antes de interpretar el pedido. Un saldo negativo o posterior al corte exige corrección y puede bloquear la programación. La tabla se ordena por vencimiento para apoyar la revisión FEFO: primero vence, primero sale; la herramienta no asigna automáticamente cada aplicación a un lote.
## Existencias utilizables y horizonte
El modelo excluye lotes en cuarentena, vencidos y los que vencen antes de finalizar el horizonte de programación. Los lotes que vencen dentro del horizonte se muestran como stock en riesgo: podrían utilizarse antes bajo una planificación documentada, pero el pedido del modelo los excluye conservadoramente.

El tránsito debe ser confirmado y oportuno. Un pedido no confirmado no equivale a existencias disponibles.
## Cadena de frío y consumo
En cadena_frio documente capacidad útil en litros y ocupación de otros productos. El volumen del pedido se calcula con volumen empacado; no use el volumen líquido inyectable.

La estimación por consumo revisa seis meses completos anteriores al mes del corte y ajusta por días observados con stock. No mide toda la demanda no atendida durante los quiebres. Si faltan meses o reportes completos, revise la comparabilidad antes de interpretar la estimación.
<!-- PAGE -->
# 11. Guardar, informar y entregar el trabajo
## Persistencia de la sesión
Los cambios viven en la sesión de R. No hay guardado automático ni sincronización. Antes de cerrar, utilice “Guardar proyecto privado (incluye nominal)”. Ese XLSX permite recuperar el trabajo mediante una nueva carga.

“Guardar identificacion” conserva los datos en la sesión; no sustituye la descarga del libro privado. Una captura de pantalla tampoco permite reconstruir cálculos.
## Informe y plan
1. En “Plan de mejora”, documente problema, evidencia, acción, responsable, fecha, indicador, meta y avance.
2. Formule una acción que responda al problema observado. Meta es texto verificable; avance usa 0 a 100.
3. En “Informe”, descargue “Resultados agregados · Excel” e “Informe tecnico · HTML”.
4. Abra el HTML en el navegador. Puede imprimirlo o guardarlo como PDF.
5. Compruebe fuente, versión, territorio y ambos cortes en el informe.

El informe no exporta filas nominales, pero puede contener nombres de responsables, identificaciones o textos escritos por el alumno. Revise todo el contenido antes de compartirlo. Agregado no significa anonimización garantizada.
## Organización sugerida
```text
Mi_sala/
  codigo/                 copia del proyecto
  datos_privados/          libro privado y fuentes restringidas
  resultados_locales/      resultados e informe revisados
  entrega/                 material autorizado para evaluación
```

GitHub aloja el código; no ejecuta automáticamente el dashboard. No publique el libro privado en un repositorio público. En una sesión en la nube, los datos se procesan donde se ejecuta R, no exclusivamente en el equipo del alumno.
<!-- PAGE -->
# 12. Resolver problemas frecuentes
| Síntoma | Qué comprobar |
| No aparece el proyecto | Descomprima el ZIP y abra la carpeta que contiene DESCRIPTION y app.R. |
| “No hay paquete llamado…” | Detenga la sala y ejecute source("instalar.R"). Lea el primer fallo de instalación. |
| sf no se instala en Linux | Revise GDAL, GEOS, PROJ y UDUNITS2 con el soporte de su distribución. |
| Sigue mostrando Angaraes | Seleccionar territorio no reemplaza datos: complete y cargue su libro propio. |
| No aparece mi distrito | Busque por nombre, provincia y departamento; verifique el ubigeo y la versión cartográfica. |
| Cobertura vacía | Revise año, regla, población y todos los meses desde enero hasta el corte. |
| Cobertura mayor de 100 % | Concilie población, residencia, dosis, duplicados y periodo. |
| Programación no disponible | Revise presentaciones, parámetros coherentes, saldos y fechas de inventario. |
| No puedo cargar ni ver nominal | Compruebe si está en modo público; necesita una ejecución privada autorizada. |
| Mis cambios desaparecieron | Recargue el último libro privado descargado. La sesión no tiene guardado automático. |
| Cambié un catálogo Excel y no funciona | Las reglas se cargan del código; las hojas cat_* son de consulta. |

Si solicita soporte, indique versión 0.2.0, sistema operativo, mensaje exacto, pestaña y pasos para reproducir. Prepare un ejemplo simulado mínimo que reproduzca el problema. No adjunte el padrón real a un issue público.

Para actualizar el código, guarde primero su libro privado y los cambios propios; descargue una nueva copia en otra carpeta. Compruebe el resultado con la demostración antes de cargar datos reales.
<!-- PAGE -->
# 13. Comprobar el primer ejercicio y la entrega
## Ejercicio de control
1. Abra la demostración y seleccione 2026, octubre, Lircay y PCV_3.
2. Compruebe 90 dosis / 120 personas × 100 = 75.0 %.
3. Seleccione Lircay, Anchonga y Callanmarca: 170 / 270 × 100 = 62.96 %. No use el promedio simple de las coberturas.
4. Cambie el cierre a noviembre y explique por qué un reporte pendiente no se convierte en cero.
5. Seleccione su territorio en “Mi proyecto”, descargue su plantilla y verifique que población y vacunación permanecen vacías.
6. Descargue el libro privado de demostración y recárguelo: los resultados deben reproducirse.
## Lista de entrega individual
- Identificación propia y ámbito inequívoco.
- Ubigeos verificados y fuentes de denominadores con versión.
- Libro integral validado y copia privada guardada.
- Numerador, denominador, periodo y limitaciones de cada indicador presentado.
- Necesidades y supuestos documentados, si se incluye logística.
- Una acción con responsable, plazo y meta verificable.
- Informe agregado revisado y código necesario para repetir el resultado.

La defensa dispone de 55 minutos en total, de 12:35 a 13:30; el docente distribuye el tiempo según el número de estudiantes. Cada alumno explica un resultado, una limitación y una acción.
## Referencias y verificación
Repositorio y README: https://github.com/f-slg/sala-inmunizaciones-peru
Cartografía: https://CRAN.R-project.org/package=mapsPERU
Pruebas 0.2.0: https://github.com/f-slg/sala-inmunizaciones-peru/actions/runs/42482417805

La versión 0.2.0 aprobó 139 comprobaciones por sistema en Linux, Windows y macOS con R 4.6.2. La prueba del selector y descarga incluyó Chachapoyas, Arequipa y Lima. Esta verificación técnica no certifica uso clínico.
