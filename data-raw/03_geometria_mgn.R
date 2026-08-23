# data-raw/03_geometria_mgn.R
# Geometría y superficie municipal a partir del Marco Geoestadístico 2025 (INEGI).
# Basta con mg_2025_integrado.zip (conjunto nacional); no hacen falta los 32
# zips estatales ni descomprimir. El MGN se guarda FUERA del repositorio y su
# ubicación se indica en .Renviron con SEQUIAMX_MGN, que puede ser:
#   - el zip:        SEQUIAMX_MGN=/Users/albertobaltazar/datos_geo_mx/mg_2025/mg_2025_integrado.zip
#   - o una carpeta: SEQUIAMX_MGN=/Users/albertobaltazar/datos_geo_mx/mg_2025/mg_2025_integrado/conjunto_de_datos
# Salida: data/municipios_sf.rda y data/catalogo_municipios.rda (con area_km2)

library(sf)
library(dplyr)

localizar_00mun <- function(ruta = Sys.getenv("SEQUIAMX_MGN")) {
  stopifnot("Define SEQUIAMX_MGN en .Renviron" = nzchar(ruta))
  if (grepl("\\.zip$", ruta, ignore.case = TRUE)) {
    stopifnot("No existe el zip indicado en SEQUIAMX_MGN" = file.exists(ruta))
    interno <- grep("00mun\\.shp$", utils::unzip(ruta, list = TRUE)$Name, value = TRUE)[1]
    stopifnot("El zip no contiene 00mun.shp" = !is.na(interno))
    return(paste0("/vsizip/", normalizePath(ruta), "/", interno))
  }
  shp <- list.files(ruta, "00mun\\.shp$", recursive = TRUE, full.names = TRUE)[1]
  stopifnot("No se encontró 00mun.shp en SEQUIAMX_MGN" = !is.na(shp))
  shp
}

shp <- localizar_00mun()
message("Leyendo: ", shp)

mun <- st_read(shp, quiet = TRUE)
stopifnot("CVEGEO" %in% names(mun))

# Área en proyección de área equivalente (Albers, parámetros CONABIO para México)
crs_albers <- "+proj=aea +lat_1=14.5 +lat_2=32.5 +lat_0=24 +lon_0=-105 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"

mun <- mun |>
  transmute(cvegeo = as.character(CVEGEO)) |>
  st_transform(crs_albers) |>
  mutate(area_km2 = as.numeric(st_area(geometry)) / 1e6)

load("data/catalogo_municipios.rda")
faltan_en_mgn   <- setdiff(catalogo_municipios$cvegeo, mun$cvegeo)
sobran_en_mgn   <- setdiff(mun$cvegeo, catalogo_municipios$cvegeo)
if (length(faltan_en_mgn) || length(sobran_en_mgn)) {
  message("Claves en CONAGUA sin geometría: ", paste(faltan_en_mgn, collapse = ", "))
  message("Claves en MGN sin CONAGUA: ",       paste(sobran_en_mgn, collapse = ", "))
  stop("Revisa las diferencias de catálogo antes de continuar.")
}

simplificar <- function(x) {
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    rmapshaper::ms_simplify(x, keep = 0.05, keep_shapes = TRUE)
  } else {
    message("rmapshaper no disponible; usando sf::st_simplify (tolerancia 500 m)")
    sf::st_simplify(x, dTolerance = 500, preserveTopology = TRUE)
  }
}

municipios_sf <- mun |>
  simplificar() |>
  st_make_valid() |>
  st_transform(4326) |>
  select(cvegeo, geometry) |>
  arrange(cvegeo)

catalogo_municipios <- catalogo_municipios |>
  select(-any_of("area_km2")) |>
  left_join(st_drop_geometry(mun)[, c("cvegeo", "area_km2")], by = "cvegeo")

stopifnot(!anyNA(catalogo_municipios$area_km2))
message("Superficie total: ", format(round(sum(catalogo_municipios$area_km2)), big.mark = ","), " km2")

usethis::use_data(municipios_sf, catalogo_municipios, overwrite = TRUE, compress = "xz")
