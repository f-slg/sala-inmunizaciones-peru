# Portable dependency setup; does not require administrator rights on Windows/macOS.
if (getRversion() < "4.2.0") stop("Se requiere R 4.2 o superior")
options(repos=c(CRAN="https://cloud.r-project.org"))
desc<-read.dcf("DESCRIPTION")
required<-trimws(unlist(strsplit(paste(desc[1,c("Imports","Suggests")],collapse=","),",")))
required<-gsub(" *\\(.*\\)","",required)
missing<-required[!vapply(required,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) install.packages(missing)
still_missing<-required[!vapply(required,requireNamespace,logical(1),quietly=TRUE)]
if(length(still_missing)) stop("Instalacion incompleta: ",paste(still_missing,collapse=", "),
  ". Revise los mensajes y, en Linux, las bibliotecas de sf.")
cat("Dependencias listas. Ejecute shiny::runApp() o abra app.R y pulse Run App.\n")
