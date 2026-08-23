# data-raw/04_preparar_app.R
# Copia funciones y datos del paquete dentro de inst/shiny para que la app
# funcione sin tener sequiaMX instalado (necesario en Connect Cloud).
# Repetir tras regenerar datos o cambiar funciones en R/.
dir.create("inst/shiny/sequiaMX_local/R", recursive = TRUE, showWarnings = FALSE)
dir.create("inst/shiny/sequiaMX_local/data", recursive = TRUE, showWarnings = FALSE)
file.copy(list.files("R", pattern = "\\.R$", full.names = TRUE), "inst/shiny/sequiaMX_local/R", overwrite = TRUE)
file.copy(list.files("data", pattern = "\\.rda$", full.names = TRUE), "inst/shiny/sequiaMX_local/data", overwrite = TRUE)
message("Copia local lista: ", length(list.files("inst/shiny/sequiaMX_local", recursive = TRUE)), " archivos")
