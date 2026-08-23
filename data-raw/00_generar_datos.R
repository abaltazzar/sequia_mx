# data-raw/00_generar_datos.R
# Corre el pipeline completo de datos: CONAGUA -> CONAPO -> MGN.
# Uso:  source("data-raw/00_generar_datos.R")
# Se detiene en el primer error e indica en qué script ocurrió.

stopifnot("Ejecuta desde la raíz del proyecto (donde está DESCRIPTION)" = file.exists("DESCRIPTION"))
stopifnot("Falta data-raw/MunicipiosSequia.xlsx" = file.exists("data-raw/MunicipiosSequia.xlsx"))
stopifnot("Falta data-raw/pobproy_inddemo.csv"  = file.exists("data-raw/pobproy_inddemo.csv"))
stopifnot("Define SEQUIAMX_MGN en .Renviron (zip o carpeta del MGN)" = nzchar(Sys.getenv("SEQUIAMX_MGN")))
stopifnot("La ruta de SEQUIAMX_MGN no existe" = file.exists(Sys.getenv("SEQUIAMX_MGN")))

pasos <- c(
  "data-raw/01_limpiar_monitor.R",
  "data-raw/02_poblacion_conapo.R",
  "data-raw/03_geometria_mgn.R"
)

for (p in pasos) {
  message("\n==> ", p)
  t0 <- Sys.time()
  tryCatch(
    source(p, echo = FALSE, local = new.env()),
    error = function(e) stop("Falló ", p, ":\n  ", conditionMessage(e), call. = FALSE)
  )
  message("    listo en ", round(difftime(Sys.time(), t0, units = "secs")), " s")
}

message("\nArchivos generados en data/: ",
        paste(list.files("data", pattern = "rda$"), collapse = ", "))
message("Siguiente paso: devtools::document(); devtools::load_all(); devtools::test()")
