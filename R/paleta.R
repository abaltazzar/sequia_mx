#' Paleta y etiquetas del Monitor de Sequía
#'
#' Colores oficiales del Drought Monitor (NDMC/CONAGUA), con gris claro para
#' "Sin sequía" para que se distinga del fondo del mapa.
#'
#' @name paleta_sequia
#' @export
niveles_sequia <- c("Sin sequía", "D0", "D1", "D2", "D3", "D4")

#' @rdname paleta_sequia
#' @export
etiquetas_sequia <- c(
  "Sin sequía"         = "Sin sequía",
  "D0"                 = "D0 Anormalmente seco",
  "D1"                 = "D1 Sequía moderada",
  "D2"                 = "D2 Sequía severa",
  "D3"                 = "D3 Sequía extrema",
  "D4"                 = "D4 Sequía excepcional"
)

#' @rdname paleta_sequia
#' @export
colores_sequia <- c(
  "Sin sequía" = "#E6E6E6",
  "D0"         = "#FFFF00",
  "D1"         = "#FCD37F",
  "D2"         = "#FFAA00",
  "D3"         = "#E60000",
  "D4"         = "#730000"
)
