# data-raw/ — fuentes originales y scripts de limpieza

Aquí entran los archivos originales y salen los datos limpios hacia `data/`.
El nombre `data-raw` es la convención de R; nada de esta carpeta se instala con
el paquete ni se sube a GitHub salvo los scripts.

## Archivos que debes colocar aquí (Git los ignora)

| Archivo | Fuente |
|---|---|
| `MunicipiosSequia.xlsx` | CONAGUA–SMN, Monitor de Sequía |
| `pobproy_inddemo.csv` | CONAPO, Reconstrucción y proyecciones municipales 1990–2040 |

El Marco Geoestadístico 2025 (INEGI) **no** va aquí: queda en `datos_geo/` fuera
del repo y se indica su ruta en `.Renviron` (`SEQUIAMX_MGN`).

## Scripts

| Script | Entrada | Salida en `data/` |
|---|---|---|
| `00_generar_datos.R` | — | Corre 01, 02 y 03 en orden |
| `01_limpiar_monitor.R` | `MunicipiosSequia.xlsx` | `sequia_municipal`, `catalogo_municipios` |
| `02_poblacion_conapo.R` | `pobproy_inddemo.csv` | `poblacion_municipal` |
| `03_geometria_mgn.R` | `00mun.shp` del MGN | `municipios_sf`, `catalogo_municipios` (+ superficie) |
| `03b_geometria_mxmaps_fallback.R` | paquete `mxmaps` | Alternativa al 03 si el MGN falla |

## Uso

```r
source("data-raw/00_generar_datos.R")
```

Repetir cada vez que CONAGUA publique un corte nuevo (basta reemplazar el xlsx).
