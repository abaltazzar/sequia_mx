#' Resumen de sequía por unidad geográfica y fecha
#'
#' Cuenta municipios por categoría del Monitor de Sequía y calcula la
#' proporción, ponderada por número de municipios, superficie o población.
#' Es la misma lógica de la gráfica de dona, generalizada.
#'
#' @param datos Tabla larga, normalmente `sequia_municipal`.
#' @param peso `"municipios"` (conteo), `"superficie"` (km2) o `"poblacion"`
#'   (población CONAPO del año de la fecha).
#' @param nivel_geo `"entidad"` (default), `"nacional"`, `"org_cuenca"` o
#'   `"con_cuenca"`.
#' @param fechas Vector opcional de fechas para filtrar antes de agregar.
#'
#' @return Tibble con una fila por unidad geográfica, fecha y categoría, con
#'   `n` (municipios), `valor` (suma del peso), `total` (suma del peso en la
#'   unidad-fecha) y `proporcion` (`valor / total`). Incluye ceros explícitos
#'   para categorías ausentes.
#' @export
resumen_entidad <- function(datos = sequiaMX::sequia_municipal,
                            peso = c("municipios", "superficie", "poblacion"),
                            nivel_geo = c("entidad", "nacional", "org_cuenca", "con_cuenca"),
                            fechas = NULL) {
  peso <- match.arg(peso)
  nivel_geo <- match.arg(nivel_geo)

  if (!is.null(fechas)) {
    datos <- dplyr::filter(datos, .data$fecha %in% as.Date(fechas))
  }

  datos <- dplyr::left_join(
    datos,
    dplyr::select(sequiaMX::catalogo_municipios,
                  "cvegeo", "entidad", "org_cuenca", "con_cuenca", "area_km2"),
    by = "cvegeo"
  )

  if (peso == "poblacion") {
    datos <- dplyr::left_join(
      datos,
      dplyr::select(sequiaMX::poblacion_municipal, "cvegeo", "anio", "poblacion"),
      by = c("cvegeo", "anio")
    )
  }

  datos$w <- switch(peso,
    municipios = rep(1, nrow(datos)),
    superficie = datos$area_km2,
    poblacion  = datos$poblacion
  )

  grupo <- switch(nivel_geo,
    nacional   = character(0),
    entidad    = "entidad",
    org_cuenca = "org_cuenca",
    con_cuenca = "con_cuenca"
  )

  datos |>
    dplyr::filter(!is.na(.data$w)) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(c(grupo, "fecha", "categoria")))) |>
    dplyr::summarise(n = dplyr::n(), valor = sum(.data$w), .groups = "drop") |>
    tidyr::complete(
      !!!rlang::syms(c(grupo, "fecha")), .data$categoria,
      fill = list(n = 0L, valor = 0)
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(c(grupo, "fecha")))) |>
    dplyr::mutate(total = sum(.data$valor), proporcion = .data$valor / .data$total) |>
    dplyr::ungroup() |>
    dplyr::mutate(peso = peso)
}
