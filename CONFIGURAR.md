# Primeros pasos en Positron

1. Descomprime el contenido directamente en `~/GitHub/sequia_mx` y abre la carpeta en Positron.
2. En la consola de R:

```r
install.packages(c("devtools", "usethis", "renv", "pak"))
pak::pak(c("dplyr","tidyr","stringr","lubridate","rlang","scales","sf","ggplot2",
           "readxl","readr","rmapshaper","shiny","bslib","bsicons","leaflet","DT",
           "htmltools","testthat","knitr","rmarkdown","quarto"))
```

3. Copia las fuentes a `data-raw/`: `MunicipiosSequia.xlsx` y `pobproy_inddemo.csv`.
   Crea un archivo `.Renviron` en la raíz del proyecto (ya está en `.gitignore`) con:

   ```
   SEQUIAMX_MGN=/Users/albertobaltazar/datos_geo_mx/mg_2025/mg_2025_integrado.zip
   ```

   Reinicia R y verifica:

   ```r
   file.exists(Sys.getenv("SEQUIAMX_MGN"))   # TRUE
   ```

4. Genera los datos, en orden:

```r
source("data-raw/00_generar_datos.R")
```

(Corre los tres scripts de limpieza en orden y avisa en cuál falla, si alguno.)

5. Documenta, carga y prueba:

```r
devtools::document()
devtools::load_all()
devtools::test()
```

6. Ejecuta la app y el reporte:

```r
shiny::runApp("inst/shiny")
quarto::quarto_render("inst/quarto/reporte_sequia.qmd")
```

7. Fija dependencias y sube a GitHub:

```r
renv::init()
usethis::use_git()
# El repo ya existe en GitHub:
# git remote add origin https://github.com/abaltazzar/sequia_mx.git
# git push -u origin main
```

