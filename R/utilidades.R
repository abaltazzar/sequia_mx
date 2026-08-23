#' Fecha de corte más reciente
#' @export
fecha_corte <- function() max(sequiaMX::sequia_municipal$fecha)

#' Fechas de corte disponibles
#' @export
fechas_disponibles <- function() sort(unique(sequiaMX::sequia_municipal$fecha))

#' Redondea una fecha arbitraria a la fecha de corte más cercana
#' @param fecha Fecha.
#' @export
fecha_mas_cercana <- function(fecha) {
  f <- fechas_disponibles()
  f[which.min(abs(f - as.Date(fecha)))]
}

#' Historial de un municipio
#' @param cvegeo Clave de 5 dígitos.
#' @export
serie_municipio <- function(cvegeo) {
  dplyr::filter(sequiaMX::sequia_municipal, .data$cvegeo == !!cvegeo)
}
