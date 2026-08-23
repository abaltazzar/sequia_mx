# inst/ — productos que acompañan al paquete

Todo lo que está aquí se instala junto con el paquete tal cual, sin procesarse.
El nombre `inst` lo exige R.

| Carpeta | Contenido | Cómo ejecutarlo |
|---|---|---|
| `shiny/` | La aplicación interactiva (`app.R`) | `shiny::runApp("inst/shiny")` |
| `quarto/` | El reporte (`reporte_sequia.qmd`) | `quarto::quarto_render("inst/quarto/reporte_sequia.qmd")` |

Ambos usan las funciones de `R/` y los datos de `data/`; no contienen lógica de
datos propia, solo presentación.
