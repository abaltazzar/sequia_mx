#' Serie temporal apilada por categoría
#'
#' Barras apiladas al 100 % con la proporción de municipios (o superficie,
#' o población) en cada categoría del Monitor, una barra por fecha de corte.
#'
#' @param resumen Salida de [resumen_entidad()]. Si contiene varias unidades
#'   (por ejemplo varias entidades), indica la columna en `por`.
#' @param rango Vector de dos fechas para acotar el eje; `NULL` muestra todo.
#' @param fecha_marcada Fecha opcional que se resalta con una línea vertical.
#' @param titulo Título de la gráfica.
#' @param por Nombre de la columna que define los paneles (p. ej. `"entidad"`);
#'   `NULL` para una sola serie.
#' @return Objeto ggplot.
#' @export
graficar_serie <- function(resumen, rango = NULL, fecha_marcada = NULL, titulo = NULL,
                           por = NULL) {
  if (!is.null(rango)) {
    resumen <- dplyr::filter(resumen, .data$fecha >= rango[1], .data$fecha <= rango[2])
  }
  peso <- unique(resumen$peso)
  eje_y <- switch(peso,
    municipios = "Proporci\u00f3n de municipios",
    superficie = "Proporci\u00f3n de la superficie",
    poblacion  = "Proporci\u00f3n de la poblaci\u00f3n"
  )

  # Cada barra ocupa exactamente el intervalo entre su fecha y la siguiente,
  # así no hay traslapes aunque la frecuencia cambie (mensual -> quincenal).
  fechas <- sort(unique(resumen$fecha))
  siguiente <- c(fechas[-1], fechas[length(fechas)] + 15)
  intervalos <- data.frame(fecha = fechas, x_ini = fechas, x_fin = siguiente)

  grupos <- c(por, "fecha")
  capas <- resumen |>
    dplyr::left_join(intervalos, by = "fecha") |>
    dplyr::arrange(dplyr::across(dplyr::all_of(grupos)), dplyr::desc(.data$categoria)) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grupos))) |>
    dplyr::mutate(
      y_fin = cumsum(.data$proporcion),
      y_ini = .data$y_fin - .data$proporcion
    ) |>
    dplyr::ungroup()

  p <- ggplot2::ggplot(capas) +
    ggplot2::geom_rect(
      ggplot2::aes(xmin = .data$x_ini, xmax = .data$x_fin,
                   ymin = .data$y_ini, ymax = .data$y_fin,
                   fill = .data$categoria),
      colour = NA
    ) +
    ggplot2::scale_fill_manual(
      values = colores_sequia, labels = etiquetas_sequia,
      breaks = rev(niveles_sequia), drop = FALSE
    ) +
    ggplot2::scale_y_continuous(labels = scales::label_percent(), expand = c(0, 0)) +
    ggplot2::scale_x_date(date_labels = "%Y", expand = c(0.005, 0)) +
    ggplot2::labs(x = NULL, y = eje_y, fill = NULL, title = titulo) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position = "bottom",
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(hjust = 0, face = "bold")
    )

  if (!is.null(por)) {
    p <- p + ggplot2::facet_wrap(stats::as.formula(paste("~", por)), ncol = 1)
  }
  if (!is.null(fecha_marcada)) {
    p <- p + ggplot2::geom_vline(
      xintercept = as.Date(fecha_marcada), linetype = "dashed", colour = "grey25"
    )
  }
  p
}

#' Gráfica de dona para un corte
#'
#' @param resumen Salida de [resumen_entidad()] filtrada a una fecha y unidad.
#' @param titulo Título opcional.
#' @return Objeto ggplot.
#' @export
graficar_dona <- function(resumen, titulo = NULL) {
  resumen <- dplyr::mutate(
    resumen,
    etiqueta = ifelse(.data$proporcion >= 0.03,
                      sprintf("%.0f%%\n(%s)", 100 * .data$proporcion,
                              format(round(.data$valor), big.mark = ",")),
                      "")
  )
  ggplot2::ggplot(resumen, ggplot2::aes(x = 2, y = .data$proporcion, fill = .data$categoria)) +
    ggplot2::geom_col(width = 1, colour = "white") +
    ggplot2::geom_text(ggplot2::aes(label = .data$etiqueta),
                       position = ggplot2::position_stack(vjust = 0.5), size = 3) +
    ggplot2::coord_polar(theta = "y", direction = -1) +
    ggplot2::xlim(0.5, 2.5) +
    ggplot2::scale_fill_manual(values = colores_sequia, labels = etiquetas_sequia,
                               breaks = niveles_sequia, drop = FALSE) +
    ggplot2::labs(title = titulo, fill = NULL) +
    ggplot2::theme_void() +
    ggplot2::theme(legend.position = "right")
}
