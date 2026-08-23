#' Categoría de sequía por municipio y fecha de corte
#'
#' Registros del Monitor de Sequía en México (CONAGUA-SMN) en formato largo.
#' Cortes mensuales de enero de 2003 a enero de 2014 y quincenales a partir
#' del 15 de febrero de 2014. No se elaboró en agosto de 2003 ni febrero de 2004.
#'
#' @format Tibble con una fila por municipio y fecha:
#' \describe{
#'   \item{cvegeo}{Clave INEGI de 5 dígitos (entidad + municipio).}
#'   \item{fecha}{Fecha de corte.}
#'   \item{categoria}{Factor ordenado: Sin sequía < D0 < D1 < D2 < D3 < D4.}
#'   \item{nivel}{Entero 0-5 equivalente a `categoria`.}
#'   \item{frecuencia}{"mensual" o "quincenal".}
#'   \item{anio, mes}{Año y mes de la fecha de corte.}
#' }
#' @source \url{https://smn.conagua.gob.mx/es/climatologia/monitor-de-sequia/monitor-de-sequia-en-mexico}
"sequia_municipal"

#' Catálogo de municipios
#'
#' @format Tibble con una fila por municipio:
#' \describe{
#'   \item{cvegeo}{Clave de 5 dígitos.}
#'   \item{cve_ent, cve_mun}{Claves numéricas de entidad y municipio.}
#'   \item{nombre_mun, entidad}{Nombres.}
#'   \item{org_cuenca, clv_oc}{Organismo de cuenca (RHA 2023) y su clave.}
#'   \item{con_cuenca, cve_conc}{Consejo de cuenca y su clave.}
#'   \item{mgn_edicion}{Edición del Marco Geoestadístico en que se creó el
#'     municipio (2018, 2021, 2025) o NA si existía desde 2003.}
#'   \item{fecha_alta}{Primera fecha en que el municipio aparece en el Monitor.}
#'   \item{area_km2}{Superficie según el MGN 2025, en proyección Albers.}
#' }
#' @source CONAGUA-SMN; INEGI, Marco Geoestadístico Nacional 2025.
"catalogo_municipios"

#' Población municipal anual 1990-2040
#'
#' Conciliación demográfica (1990-2019) y proyecciones (2020-2040) de CONAPO,
#' población a mitad de año. No incluye Villa de Pozos, Eldorado ni
#' Juan José Ríos (municipios creados en 2025).
#'
#' @format Tibble: `cvegeo`, `anio`, `poblacion`, `poblacion_65_mas`,
#'   `tipo_estimacion`.
#' @source CONAPO (2024), Reconstrucción y proyecciones de la población de los
#'   municipios de México.
"poblacion_municipal"

#' Geometría municipal simplificada
#'
#' Polígonos del MGN 2025 simplificados al 5 % de vértices, en WGS84.
#'
#' @format Objeto `sf` con `cvegeo` y `geometry`.
#' @source INEGI, Marco Geoestadístico Nacional 2025.
"municipios_sf"
