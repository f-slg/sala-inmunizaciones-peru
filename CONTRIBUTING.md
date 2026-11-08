# Contribuir

1. Cree un fork y una rama para el cambio.
2. Abra `salainmunizaciones.Rproj` e instale dependencias con `source("instalar.R")`.
3. Mantenga los cálculos en `R/domain_*.R`, la entrada/salida en `R/service_*.R`
   y la interfaz en módulos `R/mod_*.R`.
4. Una modificación de reglas debe citar fuente primaria, página, vigencia,
   población y limitaciones. No cambie retrospectivamente una regla histórica.
5. Añada pruebas de resultados y casos adversos cuando cambie lógica de cálculo.
6. Ejecute `testthat::test_local(".")` y `R CMD check --no-manual` sobre el paquete construido.
7. Abra un pull request explicando el problema, el cambio, la validación y sus límites.

Use rutas portables y recursos incluidos en el paquete. No añada dependencias
de shell ni rutas personales a la aplicación. No publique datos clínicos reales,
credenciales, libros de alumnos ni capturas con identificadores de pacientes.

Los generadores de libros de `dev/` requieren Python y openpyxl solo para desarrollo.
Si modifica fórmulas de Excel, recalcule el archivo en un motor compatible y
compruebe valores esperados y errores antes de sustituir el entregable.
