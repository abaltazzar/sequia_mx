# data-raw/00_descargar.R
# Descarga MunicipiosSequia.xlsx de CONAGUA solo si el archivo cambió.
# Deja la variable `hay_cambios` (TRUE/FALSE).

library(httr2)
library(fs)

url <- paste0(
  "https://smn.conagua.gob.mx/tools/RESOURCES/",
  "Monitor%20de%20Sequia%20en%20Mexico/MunicipiosSequia.xlsx"
)
destino  <- "data-raw/MunicipiosSequia.xlsx"
temporal <- file_temp(ext = "xlsx")

request(url) |>
  req_user_agent("sequiaMX (https://github.com/abaltazzar/sequia_mx)") |>
  req_retry(max_tries = 3) |>
  req_perform(path = temporal)

hash_nuevo <- as.character(tools::md5sum(temporal))
hash_viejo <- if (file_exists(destino)) as.character(tools::md5sum(destino)) else ""

if (hash_nuevo != hash_viejo) {
  file_copy(temporal, destino, overwrite = TRUE)
  message("Archivo nuevo descargado: ", destino)
  hay_cambios <- TRUE
} else {
  message("Sin cambios respecto al archivo actual.")
  hay_cambios <- FALSE
}