# R/ — funciones del paquete

Cada archivo agrupa funciones relacionadas. El nombre de carpeta `R` lo exige R;
no se puede cambiar.

| Archivo | Qué hace |
|---|---|
| `resumen_entidad.R` | Cuenta municipios por categoría y fecha, ponderado por municipios, superficie o población. Es la gráfica de dona generalizada. |
| `rachas.R` | Detecta eventos consecutivos de sequía por municipio y mide su duración. |
| `graficas.R` | `graficar_serie()` (barras apiladas por fecha) y `graficar_dona()`. |
| `paleta.R` | Colores oficiales D0–D4 y etiquetas. |
| `utilidades.R` | Fecha de corte, fechas disponibles, historial de un municipio. |
| `data.R` | Solo documentación de los datos en `data/`; no tiene código. |
| `sequiaMX-package.R` | Archivo técnico que requiere roxygen. No tocar. |

Para agregar un análisis nuevo: crea un archivo aquí, escribe la función con
comentarios `#'` encima (roxygen) y corre `devtools::document()`.
