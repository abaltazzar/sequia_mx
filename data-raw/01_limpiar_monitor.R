# data-raw/01_limpiar_monitor.R
# Convierte MunicipiosSequia.xlsx (CONAGUA, Monitor de Sequía) a formato largo.
# Entrada : data-raw/MunicipiosSequia.xlsx
# Salida  : data/sequia_municipal.rda, data/catalogo_municipios.rda
#
# Estructura del archivo fuente (verificada con corte 15/08/2026):
#   - Hoja MUNICIPIOS: 2,478 filas x (9 columnas de identificación + 433 fechas)
#   - Hoja NOTAS: metadatos y aclaraciones
#   - Frecuencia mensual 2003-01 a 2014-01; quincenal desde 2014-02-15
#   - Celda vacía = sin sequía; D0..D4 = categorías del Monitor
#   - Municipios con *, **, *** en el nombre: altas por MGN 2018, 2021, 2025

library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)

ruta_xlsx <- "data-raw/MunicipiosSequia.xlsx"

# Niveles del Monitor, con "Sin sequía" como nivel base (factor ordenado)
niveles_sequia <- c("Sin sequía", "D0", "D1", "D2", "D3", "D4")
etiquetas_sequia <- c(
  "Sin sequía", "Anormalmente seco", "Sequía moderada",
  "Sequía severa", "Sequía extrema", "Sequía excepcional"
)

raw <- read_excel(ruta_xlsx, sheet = "MUNICIPIOS")

cols_id <- c(
  "CVE_CONCATENADA", "CVE_ENT", "CVE_MUN", "NOMBRE_MUN", "ENTIDAD",
  "ORG_CUENCA*", "CLV_OC", "CON_CUENCA", "CVE_CONC"
)
stopifnot(all(cols_id %in% names(raw)))

# ---- Catálogo de municipios ------------------------------------------------
catalogo_municipios <- raw |>
  select(all_of(cols_id)) |>
  rename(org_cuenca = `ORG_CUENCA*`) |>
  rename_with(tolower) |>
  mutate(
    # Edición del Marco Geoestadístico en la que se dio de alta el municipio
    mgn_edicion = case_when(
      str_detect(nombre_mun, "\\*\\*\\*$") ~ 2025L,
      str_detect(nombre_mun, "\\*\\*$")    ~ 2021L,
      str_detect(nombre_mun, "\\*$")       ~ 2018L,
      TRUE                                 ~ NA_integer_
    ),
    # Fecha desde la que el municipio aparece en el Monitor (según NOTAS)
    fecha_alta = case_when(
      mgn_edicion == 2018L ~ as.Date("2019-10-31"),
      mgn_edicion == 2021L ~ as.Date("2022-10-31"),
      mgn_edicion == 2025L ~ as.Date("2026-01-15"),
      TRUE                 ~ as.Date("2003-01-31")
    ),
    nombre_mun = str_remove(nombre_mun, "\\*+$") |> str_squish(),
    cvegeo = str_pad(cve_concatenada, 5, pad = "0"),
    cve_ent = as.integer(cve_ent),
    cve_mun = as.integer(cve_mun)
  ) |>
  select(
    cvegeo, cve_ent, cve_mun, nombre_mun, entidad,
    org_cuenca, clv_oc, con_cuenca, cve_conc, mgn_edicion, fecha_alta
  ) |>
  arrange(cvegeo)

stopifnot(!any(duplicated(catalogo_municipios$cvegeo)))

# ---- Registros de sequía en formato largo ----------------------------------
# readxl convierte los encabezados de fecha a texto: "2003-01-31" o, en algunas
# versiones, el serial de Excel ("37652"). Esta función acepta ambos.
parsear_fecha_encabezado <- function(x) {
  iso <- suppressWarnings(as.Date(x, format = "%Y-%m-%d"))
  serial <- suppressWarnings(as.numeric(x))
  out <- iso
  out[is.na(iso) & !is.na(serial)] <- as.Date(serial[is.na(iso) & !is.na(serial)], origin = "1899-12-30")
  out
}

cols_fecha <- setdiff(names(raw), cols_id)
stopifnot(!anyNA(parsear_fecha_encabezado(cols_fecha)))

sequia_municipal <- raw |>
  mutate(cvegeo = str_pad(CVE_CONCATENADA, 5, pad = "0")) |>
  select(cvegeo, all_of(cols_fecha)) |>
  mutate(across(all_of(cols_fecha), as.character)) |>
  pivot_longer(-cvegeo, names_to = "fecha", values_to = "categoria") |>
  mutate(
    fecha = parsear_fecha_encabezado(fecha),
    categoria = str_trim(categoria),
    categoria = if_else(is.na(categoria) | categoria == "", "Sin sequía", categoria),
    categoria = factor(categoria, levels = niveles_sequia, ordered = TRUE),
    nivel = as.integer(categoria) - 1L,          # 0 = sin sequía ... 5 = D4
    frecuencia = if_else(fecha < as.Date("2014-02-15"), "mensual", "quincenal"),
    anio = year(fecha),
    mes = month(fecha)
  ) |>
  arrange(cvegeo, fecha)

stopifnot(
  !anyNA(sequia_municipal$fecha),
  !anyNA(sequia_municipal$categoria),
  n_distinct(sequia_municipal$cvegeo) == nrow(catalogo_municipios)
)

attr(sequia_municipal, "fecha_corte") <- max(sequia_municipal$fecha)
attr(sequia_municipal, "fuente") <- "CONAGUA-SMN, Monitor de Sequía en México"

usethis::use_data(sequia_municipal, catalogo_municipios, overwrite = TRUE, compress = "xz")
