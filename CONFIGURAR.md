# Guía de trabajo — sequia_mx

## Rutina de actualización (cada corte quincenal de CONAGUA)

En la consola de R, con el proyecto abierto:

```r
source("data-raw/00_generar_datos.R")   # descarga CONAGUA si cambió, regenera datos y la app
devtools::test()                         # todo en verde
```

En la Terminal:

```bash
git add . && git commit -m "Actualiza datos CONAGUA" && git push
```

Connect Cloud redespliega la app solo al detectar el push.

## Primera instalación en otra máquina

1. Clonar el repo y abrir la carpeta en Positron.
2. Instalar dependencias: `pak::pak(c("devtools", "usethis", "pak"))` y luego `pak::local_install_deps(dependencies = TRUE)`.
3. Copiar `pobproy_inddemo.csv` (CONAPO) a `data-raw/`. El xlsx de CONAGUA se descarga solo.
4. Crear `.Renviron` con la ruta al Marco Geoestadístico (zip o carpeta):
   `writeLines("SEQUIAMX_MGN=/ruta/a/mg_2025_integrado.zip", ".Renviron")` y reiniciar R.
5. `source("data-raw/00_generar_datos.R")`, `devtools::document()`, `devtools::test()`.

## Desarrollo diario

- Cargar el paquete sin instalar: `devtools::load_all()`.
- Probar la app: `shiny::runApp("inst/shiny")`.
- Renderizar el reporte: `quarto::quarto_render("inst/quarto/reporte_sequia.qmd")`.
- Revisar el paquete como lo hace GitHub: `devtools::check()`.

## Reglas que evitan dolores de cabeza

- **Cierra en el editor cualquier archivo que se modifique desde la consola** (por ejemplo con `writeLines`). Si el editor lo tiene abierto y guardas después, sobreescribe el cambio.
- No hagas `devtools::install()` salvo que lo necesites; `load_all()` basta para trabajar.
- Las carpetas `R`, `data`, `inst`, `tests`, `vignettes`, `man` tienen esos nombres porque R lo exige. `data-raw` produce `data`; `R` usa `data`; `inst` usa `R`.
- Si cambias funciones en `R/` o datos, corre `source("data-raw/04_preparar_app.R")` para que la copia que usa Connect Cloud se actualice (lo hace solo `00_generar_datos.R`).
