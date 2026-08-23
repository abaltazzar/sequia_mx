# data-raw/02_poblacion_conapo.R
# Población municipal anual (1990-2040) de CONAPO, "Reconstrucción y proyecciones
# de la población de los municipios de México" (mayo 2024), archivo de
# indicadores demográficos especiales.
# Entrada : data-raw/pobproy_inddemo.csv
# Salida  : data/poblacion_municipal.rda
#
# Notas:
#   - 2,475 municipios x 51 años. Incluye los municipios creados en 2019 y 2022
#     con serie reconstruida hacia atrás.
#   - No incluye los 3 municipios del MGN 2025: Villa de Pozos (24059),
#     Eldorado (25019) y Juan José Ríos (25020). Quedan con NA.
#   - 1990-2019 es conciliación retrospectiva; 2020-2040 es proyección.
#   - Se usa POB_MIT_MUN (población a mitad de año).

library(readr)
library(dplyr)
library(stringr)

poblacion_municipal <- read_csv(
  "data-raw/pobproy_inddemo.csv",
  col_select = c(CLAVE, ANO, POB_MIT_MUN, POB_65_MAS),
  col_types = cols(.default = col_double()),
  locale = locale(encoding = "UTF-8")
) |>
  transmute(
    cvegeo = str_pad(CLAVE, 5, pad = "0"),
    anio = as.integer(ANO),
    poblacion = POB_MIT_MUN,
    poblacion_65_mas = POB_65_MAS,
    tipo_estimacion = if_else(anio <= 2019L, "conciliación", "proyección")
  ) |>
  arrange(cvegeo, anio)

stopifnot(
  n_distinct(poblacion_municipal$cvegeo) == 2475,
  !anyNA(poblacion_municipal$poblacion)
)

# Verificación cruzada contra el catálogo de CONAGUA
load("data/catalogo_municipios.rda")
faltantes <- setdiff(catalogo_municipios$cvegeo, poblacion_municipal$cvegeo)
message("Municipios sin población en CONAPO: ", paste(faltantes, collapse = ", "))
stopifnot(setequal(faltantes, c("24059", "25019", "25020")))

attr(poblacion_municipal, "fuente") <-
  "CONAPO (2024). Reconstrucción y proyecciones de la población de los municipios de México 1990-2040."

usethis::use_data(poblacion_municipal, overwrite = TRUE, compress = "xz")
