# -----------------------------------------------------------------------
# ALTERNATIVA al MGN: geometrías de mxmaps (INEGI; no incluye municipios de 2025).
# Produce municipios_sf y area_km2 compatibles con el paquete.
# Descarga el Excel de municipios, lo convierte a formato largo, calcula
# agregados por estado/nacional, y arma las geometrías (municipio y estado)
# usando los datos oficiales del INEGI incluidos en el paquete `mxmaps`
# (unión exacta por clave CVE_CONCATENADA de 5 dígitos).
#
# Ejecutar una sola vez (o cuando se quiera refrescar los datos) desde la
# raíz del proyecto:   source("scripts/data_prep.R")
# Genera los archivos en data/: drought_long.rds, drought_state.rds,
# drought_national.rds, mun_sf.rds, state_sf.rds
# -----------------------------------------------------------------------

library(tidyverse)
library(readxl)
library(sf)
library(jsonlite)


# 4. Geometrías (municipio y estado) desde mxmaps (claves oficiales INEGI)
if (!requireNamespace("mxmaps", quietly = TRUE)) {
  if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
  remotes::install_github("diegovalle/mxmaps", upgrade = "never")
}

topo_to_sf <- function(topo_list) {
  tmp <- tempfile(fileext = ".json")
  writeLines(toJSON(topo_list, auto_unbox = TRUE, digits = NA), tmp)
  out <- st_read(tmp, quiet = TRUE)
  st_crs(out) <- 4326
  file.remove(tmp)
  out
}

mun_sf <- topo_to_sf(mxmaps::mxmunicipio.topoJSON)
state_sf <- topo_to_sf(mxmaps::mxstate.topoJSON)

# Simplificar geometría de municipios para que el mapa cargue rápido en Shiny
sf_use_s2(FALSE)
mun_sf <- st_simplify(mun_sf, dTolerance = 0.001, preserveTopology = TRUE) |>
  st_make_valid()
sf_use_s2(TRUE)

municipios_sf <- mun_sf |>
  transmute(cvegeo = as.character(id)) |>
  st_make_valid()

crs_albers <- "+proj=aea +lat_1=14.5 +lat_2=32.5 +lat_0=24 +lon_0=-105 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"
areas <- municipios_sf |>
  st_transform(crs_albers) |>
  mutate(area_km2 = as.numeric(st_area(geometry)) / 1e6) |>
  st_drop_geometry()

load("data/catalogo_municipios.rda")
catalogo_municipios <- catalogo_municipios |>
  select(-any_of("area_km2")) |>
  left_join(areas, by = "cvegeo")
message("Municipios sin geometría en mxmaps: ",
        paste(catalogo_municipios$cvegeo[is.na(catalogo_municipios$area_km2)], collapse = ", "))

usethis::use_data(municipios_sf, catalogo_municipios, overwrite = TRUE, compress = "xz")

