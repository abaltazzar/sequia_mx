# sequiaMX

<!-- badges: start -->
[![R-CMD-check](https://github.com/abaltazzar/sequia_mx/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/abaltazzar/sequia_mx/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE.md)
<!-- badges: end -->

Paquete de R con los datos del **Monitor de Sequía en México** (CONAGUA–SMN) en formato
analizable, funciones para resumirlos y dos productos derivados: un reporte en Quarto y
una aplicación Shiny.

El objetivo es que cualquier persona pueda reproducir el análisis y consultar el estado
de la sequía por municipio, entidad federativa u organismo de cuenca desde 2003 hasta el
corte más reciente.

**Reporte:** https://abaltazzar.github.io/sequia_mx/
**Aplicación:** https://posit-connect.URL/sequiaMX/

## ¿Qué contiene?

### Datos

| Objeto | Descripción | Fuente |
|---|---|---|
| `sequia_municipal` | Una fila por municipio y fecha con la categoría del Monitor (Sin sequía, D0–D4). 2,478 municipios × 433 fechas. | CONAGUA–SMN |
| `catalogo_municipios` | Claves, nombres, entidad, organismo y consejo de cuenca, superficie y edición del Marco Geoestadístico. | CONAGUA, INEGI |
| `poblacion_municipal` | Población anual por municipio, 1990–2040. | CONAPO |
| `municipios_sf` | Geometría municipal simplificada para mapas. | INEGI, MGN 2025 |

Corte actual de los datos: **15 de agosto de 2026**.

### Funciones

- `resumen_entidad()`: municipios por categoría y fecha, ponderados por número de
  municipios, superficie o población. Agrega por entidad, nacional, organismo o consejo
  de cuenca.
- `rachas_sequia()`: eventos consecutivos en sequía por municipio, con duración en días.
- `serie_municipio()`: historial de un municipio.
- `graficar_serie()`, `graficar_dona()`: gráficas base del reporte y la app.

## Instalación

```r
# install.packages("pak")
pak::pak("abaltazzar/sequia_mx")
```

## Uso rápido

```r
library(sequiaMX)
library(dplyr)

# Proporción de municipios por categoría en el corte más reciente
resumen_entidad(nivel_geo = "nacional", fechas = fecha_corte())

# Lo mismo ponderado por superficie, por entidad
resumen_entidad(peso = "superficie", fechas = "2024-05-31") |>
  filter(categoria >= "D3") |>
  arrange(desc(proporcion))

# Las sequías más largas (D1 o peor) desde 2003
rachas_sequia(umbral = "D1") |>
  left_join(catalogo_municipios, by = "cvegeo") |>
  slice_max(duracion_dias, n = 10)

# Serie nacional apilada por categoría
resumen_entidad(nivel_geo = "nacional") |> graficar_serie()
```

## Notas metodológicas

- **La unidad de análisis es el municipio.** Las cifras estatales y nacionales son
  conteos o proporciones de municipios. "27 % en D0" significa que 27 % de los
  municipios están en esa categoría, no 27 % del territorio ni de la población. Las
  ponderaciones por superficie y población se ofrecen como complemento y se etiquetan
  siempre como tales.
- **"En sequía" significa D1 o peor.** D0 (anormalmente seco) se reporta por separado,
  siguiendo la convención del propio Monitor.
- **Frecuencia.** El Monitor fue mensual de enero de 2003 a enero de 2014 y quincenal
  desde el 15 de febrero de 2014. Las duraciones se calculan en días calendario, no en
  número de registros. No se elaboró en agosto de 2003 ni febrero de 2004.
- **Municipios nuevos.** 21 municipios se incorporaron con las ediciones 2018, 2021 y
  2025 del Marco Geoestadístico y heredan el historial del municipio del que se
  separaron. Se conservan los 2,478 municipios actuales en toda la serie; la columna
  `fecha_alta` del catálogo permite excluirlos si se desea.
- **Población.** Estimaciones de CONAPO: conciliación demográfica para 1990–2019 y
  proyección para 2020 en adelante. Tres municipios creados en 2025 (Villa de Pozos,
  Eldorado, Juan José Ríos) no tienen estimación propia y quedan fuera del cálculo
  ponderado por población.
- **Organismos de cuenca.** Asignados por CONAGUA según la delimitación de Regiones
  Hidrológico-Administrativas de 2023.

## Reproducir desde cero

Ver `CONFIGURAR.md` y `data-raw/README.md`.

```r
source("data-raw/00_generar_datos.R")
devtools::document(); devtools::load_all()
quarto::quarto_render("inst/quarto/reporte_sequia.qmd")
shiny::runApp("inst/shiny")
```

## Estructura del repositorio

```
├── R/              funciones del paquete
├── data/           datos procesados (.rda)
├── data-raw/       scripts de limpieza (las fuentes crudas no se versionan)
├── inst/quarto/    reporte
├── inst/shiny/     aplicación
├── vignettes/      metodología y ejemplos
├── tests/          pruebas con testthat
└── .github/        CI: R CMD check
```

## Fuentes

- CONAGUA–SMN. *Monitor de Sequía en México.*
  https://smn.conagua.gob.mx/es/climatologia/monitor-de-sequia/monitor-de-sequia-en-mexico
- CONAPO (2024). *Reconstrucción y proyecciones de la población de los municipios de
  México 1990–2040.*
  https://www.gob.mx/conapo/articulos/reconstruccion-y-proyecciones-de-la-poblacion-de-los-municipios-de-mexico
- INEGI (2025). *Marco Geoestadístico Nacional.*

## Cómo citar

```
Baltazar, A. (2026). sequiaMX: Datos y análisis del Monitor de Sequía en México.
Versión 0.1.0. https://github.com/abaltazzar/sequia_mx
```

## Licencia

Código bajo licencia MIT. Los datos son propiedad de sus respectivas instituciones y se
redistribuyen conforme a los términos de datos abiertos del Gobierno de México; cítalos
directamente si los reutilizas.
