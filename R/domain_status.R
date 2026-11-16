# Shared visual categories. These are display thresholds, not clinical rules.
coverage_status <- function(x) {
  ifelse(is.na(x),"Sin dato",ifelse(x>100,"Revisar datos",ifelse(x>=95,"Meta alcanzada",ifelse(x>=80,"En alerta","Baja cobertura"))))
}
dropout_status <- function(x) {
  ifelse(is.na(x),"Sin dato",ifelse(x<0,"Revisar comparabilidad",ifelse(x>10,"Desercion alta","Dentro del umbral")))
}
status_palette <- function() c(
  "Baja cobertura"="#FCE8E6","Desercion alta"="#FCE8E6","Saldo negativo"="#FCE8E6","Vencido"="#FCE8E6","Error"="#FCE8E6",
  "En alerta"="#FFF3CD","Cuarentena"="#FFF3CD","Vence en 90 dias"="#FFF3CD","Aviso"="#FFF3CD","pendiente"="#FFF3CD","registrada_no_valida"="#FCE8E6",
  "Meta alcanzada"="#E1F3E9","Dentro del umbral"="#E1F3E9","Disponible"="#E1F3E9","Correcto"="#E1F3E9","recibida_valida"="#E1F3E9",
  "Revisar datos"="#E5EEFA","Revisar comparabilidad"="#E5EEFA","requiere_revision"="#E5EEFA","fuera_edad_revisar"="#E5EEFA","Saldo posterior al corte"="#E5EEFA",
  "Sin dato"="#EDF0F4","Intervencion intensiva"="#E5EEFA","Seguimiento regular"="#EDF0F4","Pendiente de datos"="#FFF3CD")
status_legend <- function() shiny::div(class="status-legend",role="note",
  shiny::span(class="status-label status-red","Rojo: requiere atencion"),
  shiny::span(class="status-label status-amber","Amarillo: alerta o seguimiento"),
  shiny::span(class="status-label status-green","Verde: meta o condicion favorable"),
  shiny::span(class="status-label status-blue","Azul: revisar o decision propuesta"),
  shiny::span(class="status-label status-gray","Gris: sin dato"))
