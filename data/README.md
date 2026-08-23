# data/ — datos limpios

Aquí escriben los scripts de `data-raw/`. No edites estos archivos a mano.

| Archivo | Contenido | Lo genera |
|---|---|---|
| `sequia_municipal.rda` | Categoría de sequía por municipio y fecha (formato largo) | `01_limpiar_monitor.R` |
| `catalogo_municipios.rda` | Claves, nombres, cuencas, superficie, fecha de alta | `01` y `03` |
| `poblacion_municipal.rda` | Población anual por municipio 1990–2040 | `02_poblacion_conapo.R` |
| `municipios_sf.rda` | Geometría municipal simplificada para mapas | `03_geometria_mgn.R` |

Estos cuatro archivos sí se suben a GitHub: son lo que cualquiera obtiene al
instalar el paquete sin necesidad de descargar las fuentes originales.
