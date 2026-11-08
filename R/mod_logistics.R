mod_logistics_ui <- function(id) {
  ns<-shiny::NS(id)
  shiny::tagList(shiny::div(class="alert alert-info","La programacion usa el horizonte declarado en la plantilla; es independiente del mes administrativo. Presentaciones, perdida, reserva y transito deben estar documentados."),
    mod_table_ui(ns("requirements"),"Necesidad de dosis, frascos e insumos","Se agregan dosis del mismo producto antes de descontar stock y redondear frascos. Los productos alternativos deben asignarse a poblaciones distintas."),
    module_card("Comparacion de necesidades",shiny::plotOutput(ns("plot"),height="420px")),
    mod_table_ui(ns("consumption"),"Proyeccion alternativa por consumo","Seis meses completos previos al mes de corte; horizonte ilustrativo de 90 dias. Comparar con programacion poblacional; no sumar ambos metodos."),
    mod_table_ui(ns("capacity"),"Capacidad de cadena de frio","Volumen empacado del pedido frente a capacidad libre declarada. No reemplaza un estudio de almacenamiento y distribucion."))
}
mod_logistics_server <- function(id,requirements,capacity,consumption) shiny::moduleServer(id,function(input,output,session) {
  mod_table_server("consumption",consumption)
  mod_table_server("requirements",requirements);mod_table_server("capacity",capacity)
  output$plot<-shiny::renderPlot({x<-requirements();if(!nrow(x)) return(plot_empty());x<-stats::aggregate(pedido_neto~producto_id,x,sum);x<-utils::head(x[order(-x$pedido_neto),],15)
    ggplot2::ggplot(x,ggplot2::aes(stats::reorder(producto_id,pedido_neto),pedido_neto))+ggplot2::geom_col(fill="#542583",width=.7)+ggplot2::coord_flip()+ggplot2::labs(x=NULL,y="Dosis a solicitar",title="Quince mayores pedidos netos")+sala_theme()})
})
mod_inventory_ui <- function(id) shiny::tagList(mod_table_ui(shiny::NS(id,"stock"),"Inventario y vencimientos","Saldo inicial mas movimientos hasta el corte. Orden FEFO: primero vence, primero sale."),mod_table_ui(shiny::NS(id,"movements"),"Movimientos del periodo"))
mod_inventory_server <- function(id,inventory,movements) shiny::moduleServer(id,function(input,output,session) {mod_table_server("stock",inventory);mod_table_server("movements",movements)})
