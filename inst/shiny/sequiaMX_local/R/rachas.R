#' Rachas (eventos) de sequía por municipio
#'
#' Identifica periodos consecutivos en los que un municipio está en o por
#' encima de un umbral del Monitor. La duración se mide en días calendario
#' (diferencia entre la primera y la última fecha de la racha más el
#' intervalo típico), no en número de registros, para que el cambio de
#' frecuencia mensual -> quincenal en 2014 no sesgue la comparación.
#'
#' @param datos Tabla larga, normalmente `sequia_municipal`.
#' @param umbral Categoría mínima que cuenta como "en sequía". Default `"D1"`.
#'
#' @return Tibble con una fila por racha: `cvegeo`, `inicio`, `fin`,
#'   `n_registros`, `duracion_dias`, `categoria_max`.
#' @export
rachas_sequia <- function(datos = sequia_municipal, umbral = "D1") {
  umbral <- factor(umbral, levels = levels(datos$categoria), ordered = TRUE)

  datos |>
    dplyr::arrange(.data$cvegeo, .data$fecha) |>
    dplyr::group_by(.data$cvegeo) |>
    dplyr::mutate(
      en_sequia = .data$categoria >= umbral,
      id_racha = cumsum(.data$en_sequia != dplyr::lag(.data$en_sequia, default = FALSE) &
                          .data$en_sequia)
    ) |>
    dplyr::filter(.data$en_sequia) |>
    dplyr::group_by(.data$cvegeo, .data$id_racha) |>
    dplyr::summarise(
      inicio = min(.data$fecha),
      fin = max(.data$fecha),
      n_registros = dplyr::n(),
      # intervalo del último registro: 15 días si quincenal, ~30 si mensual
      duracion_dias = as.integer(.data$fin - .data$inicio) +
        dplyr::if_else(dplyr::last(.data$frecuencia) == "quincenal", 15L, 30L),
      categoria_max = max(.data$categoria),
      .groups = "drop"
    ) |>
    dplyr::select(-"id_racha")
}
