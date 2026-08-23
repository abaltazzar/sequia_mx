# inst/shiny/app.R
# Monitor de Sequía en México — explorador interactivo.
# Toda la lógica de datos vive en el paquete sequiaMX; la app solo presenta.

library(shiny)
library(bslib)
library(bsicons)
library(dplyr)
library(ggplot2)
library(leaflet)
library(sf)
library(DT)
if (!requireNamespace("sequiaMX", quietly = TRUE)) {
  remotes::install_github("abaltazzar/sequia_mx", upgrade = "never")
}
library(sequiaMX)

# ---- Datos estáticos ------------------------------------------------------
fechas_disp <- fechas_disponibles()
fecha_max   <- max(fechas_disp)
fecha_min   <- min(fechas_disp)
version_pkg <- tryCatch(as.character(utils::packageVersion("sequiaMX")), error = \(e) "dev")

catalogo <- catalogo_municipios
entidades <- catalogo |> distinct(cve_ent, entidad) |> arrange(entidad)

mun_sf <- municipios_sf |>
  left_join(select(catalogo, cvegeo, cve_ent, nombre_mun, entidad), by = "cvegeo")

sf_use_s2(FALSE)
ent_sf <- mun_sf |>
  st_make_valid() |>
  group_by(cve_ent, entidad) |>
  summarise(geometry = st_union(geometry), .groups = "drop") |>
  st_cast("MULTIPOLYGON") |>
  st_make_valid()
sf_use_s2(TRUE)

# Resumen por entidad en municipios (mapa estatal y comparación); el resto se
# calcula sobre el conjunto de municipios seleccionado
res_nacional <- list(
  municipios = resumen_entidad(peso = "municipios", nivel_geo = "nacional"),
  superficie = resumen_entidad(peso = "superficie", nivel_geo = "nacional"),
  poblacion  = resumen_entidad(peso = "poblacion",  nivel_geo = "nacional")
)
res_entidad_mun <- resumen_entidad(peso = "municipios", nivel_geo = "entidad")
serie_ent_d1 <- res_entidad_mun |>
  filter(categoria >= "D1") |>
  group_by(entidad, fecha) |>
  summarise(p = sum(proporcion), .groups = "drop")
rachas_d1 <- rachas_sequia(umbral = "D1")

dias_reg <- tibble(fecha = fechas_disp, dias = as.numeric(c(diff(fechas_disp), 15)))
sequia_dias <- sequia_municipal |>
  select(cvegeo, fecha, categoria) |>
  left_join(dias_reg, by = "fecha")

pal_pct <- colorNumeric("YlOrRd", domain = c(0, 1))
tema_estado <- value_box_theme(bg = "#E4EAF1", fg = "#1F2A36")
tema_peso   <- value_box_theme(bg = "#EFE8DA", fg = "#3A2F1E")
tema_tiempo <- value_box_theme(bg = "#DCEBE5", fg = "#1C3A31")

fmt_pct <- function(x, d = 1) sprintf(paste0("%.", d, "f %%"), 100 * x)
fmt_n   <- function(x) format(round(x), big.mark = ",")
fmt_compacto <- function(x) {
  if (is.na(x)) return("s/d")
  if (x >= 1e6) sprintf("%.1f M", x / 1e6)
  else if (x >= 1e4) sprintf("%.0f mil", x / 1e3)
  else fmt_n(x)
}
fmt_fecha <- function(f) format(f, "%d %b %Y")
fmt_duracion <- function(dias) {
  if (is.na(dias)) return("s/d")
  if (dias >= 730) sprintf("%.1f años", dias / 365.25)
  else if (dias >= 60) sprintf("%.0f meses", dias / 30.44)
  else sprintf("%.0f días", dias)
}
dias_periodo <- function(r) as.numeric(r[2] - r[1]) + 15
lista_nombres <- function(x) {
  if (length(x) <= 1) return(x)
  paste(paste(x[-length(x)], collapse = ", "), "y", x[length(x)])
}

# ---- Estilo -------------------------------------------------------------------
css <- "
  .bslib-value-box .value-box-title { font-size: .78rem; letter-spacing: .04em;
    text-transform: uppercase; opacity: .75; }
  .bslib-value-box .value-box-value { font-family: 'Source Serif 4', serif;
    font-weight: 500; font-size: 2rem; }
  .bslib-value-box p { font-size: .85rem; opacity: .85; margin-bottom: 0; }
  .card-header { font-size: .8rem; letter-spacing: .04em; text-transform: uppercase;
    color: #4A4A4A; background: #FFFFFF; border-bottom: 1px solid #E8E6E1; }
  .card { border: 1px solid #E8E6E1; box-shadow: none; }
  .sidebar { background: #FBFAF8; }
  footer.pie { margin-top: 2rem; padding: 1.5rem 0 .5rem; border-top: 1px solid #E8E6E1;
    font-size: .82rem; color: #5A5A5A; line-height: 1.5; }
  footer.pie h6 { font-size: .78rem; letter-spacing: .04em; text-transform: uppercase;
    color: #6B6B6B; margin-bottom: .4rem; }
  footer.pie a { color: #B8420F; text-decoration: none; }
"

# ---- UI ---------------------------------------------------------------------
ui <- page_sidebar(
  title = "Monitor de Sequía en México",
  fillable = FALSE,
  theme = bs_theme(
    version = 5, bg = "#FFFFFF", fg = "#1F1F1F", primary = "#B8420F",
    base_font = font_google("Source Sans 3"),
    heading_font = font_google("Source Serif 4")
  ),
  tags$head(tags$style(HTML(css))),

  sidebar = sidebar(
    width = 320,
    sliderInput(
      "fecha", "Fecha de corte",
      min = fecha_min, max = fecha_max, value = fecha_max,
      timeFormat = "%d %b %Y",
      animate = animationOptions(interval = 500, loop = FALSE)
    ),
    selectizeInput(
      "entidad", "Entidades (una o varias; vacío = todo el país)",
      choices = setNames(entidades$cve_ent, entidades$entidad),
      multiple = TRUE,
      options = list(placeholder = "Todo el país", plugins = list("remove_button"))
    ),
    selectInput("municipio", "Municipio", choices = c("Toda la selección" = "")),
    radioButtons(
      "nivel_mapa", "Mapa",
      choices = c("Municipios" = "municipio", "Entidades" = "entidad"),
      selected = "municipio", inline = TRUE
    ),
    tags$label(class = "form-label", "Periodo para la serie y el tiempo en sequía"),
    dateRangeInput(
      "rango", NULL,
      start = fecha_min, end = fecha_max, min = fecha_min, max = fecha_max,
      language = "es", separator = " a "
    ),
    hr(),
    helpText(
      "La unidad de análisis es el municipio. ",
      "\"En sequía\" significa D1 o peor; D0 (anormalmente seco) se reporta aparte. ",
      "Con varias entidades, las cifras corresponden al conjunto de sus municipios."
    )
  ),

  layout_column_wrap(
    width = 1/3, fill = FALSE,
    value_box(title = textOutput("t1"), value = textOutput("v1"), p(textOutput("s1")),
              showcase = bs_icon("droplet-half"), theme = tema_estado),
    value_box(title = textOutput("t2"), value = textOutput("v2"), p(textOutput("s2")),
              showcase = bs_icon("geo-alt"), theme = tema_estado),
    value_box(title = textOutput("t3"), value = textOutput("v3"), p(textOutput("s3")),
              showcase = bs_icon("exclamation-triangle"), theme = tema_estado),
    value_box(title = textOutput("t4"), value = textOutput("v4"), p(textOutput("s4")),
              showcase = bs_icon("map"), theme = tema_peso),
    value_box(title = textOutput("t5"), value = textOutput("v5"), p(textOutput("s5")),
              showcase = bs_icon("people"), theme = tema_peso),
    value_box(title = textOutput("t6"), value = textOutput("v6"), p(textOutput("s6")),
              showcase = bs_icon("hourglass-split"), theme = tema_tiempo)
  ),

  layout_columns(
    col_widths = c(7, 5),
    card(full_screen = TRUE,
         card_header(textOutput("titulo_mapa", inline = TRUE)),
         leafletOutput("mapa", height = 500)),
    card(full_screen = TRUE,
         card_header(textOutput("titulo_dona", inline = TRUE)),
         plotOutput("dona", height = 500))
  ),

  card(full_screen = TRUE,
       card_header(textOutput("titulo_serie", inline = TRUE)),
       plotOutput("serie", height = 360)),

  conditionalPanel(
    "input.entidad && input.entidad.length > 1",
    card(full_screen = TRUE,
         card_header("Comparación por entidad: proporción de municipios por categoría"),
         plotOutput("comparacion", height = "auto"))
  ),

  card(full_screen = TRUE, card_header("Municipios"), DTOutput("tabla")),

  tags$footer(class = "pie",
    layout_columns(
      col_widths = c(4, 4, 4),
      div(
        tags$h6("Autor"),
        "Alberto Baltazar", tags$br(),
        tags$a(href = "mailto:abaltazar@me.com", "abaltazar@me.com"), tags$br(),
        tags$a(href = "https://github.com/abaltazzar/sequia_mx", target = "_blank",
               "github.com/abaltazzar/sequia_mx")
      ),
      div(
        tags$h6("Fuentes"),
        tags$a(href = "https://smn.conagua.gob.mx/es/climatologia/monitor-de-sequia/monitor-de-sequia-en-mexico",
               target = "_blank", "CONAGUA–SMN, Monitor de Sequía en México"), tags$br(),
        "INEGI, Marco Geoestadístico Nacional 2025", tags$br(),
        tags$a(href = "https://www.gob.mx/conapo/articulos/reconstruccion-y-proyecciones-de-la-poblacion-de-los-municipios-de-mexico",
               target = "_blank", "CONAPO, Proyecciones municipales 1990–2040")
      ),
      div(
        tags$h6("Acerca de"),
        sprintf("Datos al corte del %s.", fmt_fecha(fecha_max)), tags$br(),
        sprintf("Paquete sequiaMX v%s · Código bajo licencia MIT.", version_pkg), tags$br(),
        "Los datos pertenecen a sus instituciones; cítalas si los reutilizas."
      )
    )
  )
)

# ---- Server -----------------------------------------------------------------
server <- function(input, output, session) {

  fecha_sel <- reactive(fecha_mas_cercana(input$fecha))
  anio_sel  <- reactive(as.integer(format(fecha_sel(), "%Y")))
  rango     <- reactive(as.Date(input$rango))

  # ---- Selección de entidades (conjunto) ---------------------------------------
  cves_ent  <- reactive(as.integer(input$entidad))
  nacional  <- reactive(length(cves_ent()) == 0)
  nombres_ent <- reactive(entidades$entidad[match(cves_ent(), entidades$cve_ent)])
  nombre_unidad <- reactive(if (nacional()) "México" else lista_nombres(nombres_ent()))
  cvegeos_unidad <- reactive({
    if (nacional()) catalogo$cvegeo else catalogo$cvegeo[catalogo$cve_ent %in% cves_ent()]
  })
  n_ent <- reactive(length(cves_ent()))

  observeEvent(input$entidad, {
    if (nacional()) {
      updateSelectInput(session, "municipio", choices = c("Toda la selección" = ""), selected = "")
    } else {
      m <- catalogo |> filter(cve_ent %in% cves_ent()) |> arrange(entidad, nombre_mun)
      etiquetas <- if (n_ent() > 1) paste0(m$nombre_mun, " (", m$entidad, ")") else m$nombre_mun
      updateSelectInput(session, "municipio",
                        choices = c("Toda la selección" = "", setNames(m$cvegeo, etiquetas)),
                        selected = "")
    }
  }, ignoreNULL = FALSE)
  hay_mun <- reactive(nzchar(input$municipio))
  info_mun <- reactive({
    req(hay_mun())
    catalogo |> filter(cvegeo == input$municipio) |>
      left_join(poblacion_municipal |> filter(anio == anio_sel()) |> select(cvegeo, poblacion),
                by = "cvegeo")
  })
  cve_ent_mun <- reactive(info_mun()$cve_ent)

  # ---- Resúmenes del conjunto seleccionado (todas las fechas) ------------------
  resumen_unidad <- reactive({
    if (nacional()) return(res_nacional)
    datos <- sequia_municipal |> filter(cvegeo %in% cvegeos_unidad())
    list(
      municipios = resumen_entidad(datos, peso = "municipios", nivel_geo = "nacional"),
      superficie = resumen_entidad(datos, peso = "superficie", nivel_geo = "nacional"),
      poblacion  = resumen_entidad(datos, peso = "poblacion",  nivel_geo = "nacional")
    )
  })
  indicador <- function(peso, desde) {
    r <- resumen_unidad()[[peso]] |> filter(fecha == fecha_sel(), categoria >= desde)
    list(prop = sum(r$proporcion), valor = sum(r$valor), total = r$total[1])
  }
  indicador_nac <- function(peso, desde) {
    r <- res_nacional[[peso]] |> filter(fecha == fecha_sel(), categoria >= desde)
    sum(r$valor)
  }
  sub_unidad <- function(peso, desde, unidad) {
    i <- indicador(peso, desde)
    cifras <- sprintf("%s de %s %s", fmt_compacto(i$valor), fmt_compacto(i$total), unidad)
    if (nacional()) return(cifras)
    nac <- indicador_nac(peso, desde)
    if (nac == 0) return(cifras)
    sprintf("%s del país · %s", fmt_pct(i$valor / nac), cifras)
  }
  cat_modal <- reactive({
    r <- resumen_unidad()$municipios |> filter(fecha == fecha_sel()) |>
      slice_max(n, n = 1, with_ties = FALSE)
    list(cat = as.character(r$categoria), n = r$n, total = r$total, prop = r$proporcion)
  })
  tiempo_en <- function(cvegeos, desde) {
    d <- sequia_dias |> filter(cvegeo %in% cvegeos, fecha >= rango()[1], fecha <= rango()[2])
    if (nrow(d) == 0) return(NA_real_)
    sum(d$dias[d$categoria >= desde]) / sum(d$dias)
  }
  etiqueta_periodo <- reactive(sprintf("%s a %s", fmt_fecha(rango()[1]), fmt_fecha(rango()[2])))

  # ---- Indicadores municipio ---------------------------------------------------
  cat_mun <- reactive({
    req(hay_mun())
    sequia_municipal |> filter(cvegeo == input$municipio, fecha == fecha_sel()) |> pull(categoria)
  })
  rachas_mun <- reactive({
    req(hay_mun())
    rachas_d1 |> filter(cvegeo == input$municipio, fin >= rango()[1], inicio <= rango()[2])
  })
  racha_actual <- reactive({
    req(hay_mun())
    h <- sequia_municipal |> filter(cvegeo == input$municipio, fecha <= fecha_sel()) |> arrange(desc(fecha))
    en_seq <- h$categoria[1] >= "D1"
    corte <- which(if (en_seq) h$categoria < "D1" else h$categoria >= "D1")[1]
    inicio <- if (is.na(corte)) fecha_min else h$fecha[corte - 1]
    list(en_sequia = en_seq, desde = inicio, dias = as.numeric(fecha_sel() - inicio))
  })
  peso_mun <- function(campo) {
    m <- info_mun()
    en_ent <- catalogo$cvegeo[catalogo$cve_ent == cve_ent_mun()]
    if (campo == "area_km2") {
      ent_tot <- sum(catalogo$area_km2[catalogo$cvegeo %in% en_ent])
      nac_tot <- sum(catalogo$area_km2)
    } else {
      pob <- poblacion_municipal |> filter(anio == anio_sel())
      ent_tot <- sum(pob$poblacion[pob$cvegeo %in% en_ent], na.rm = TRUE)
      nac_tot <- sum(pob$poblacion, na.rm = TRUE)
    }
    v <- m[[campo]]
    if (is.na(v)) return("Sin estimación de CONAPO para este municipio")
    sprintf("%s del estado · %s del país", fmt_pct(v / ent_tot), fmt_pct(v / nac_tot, 2))
  }

  # ---- Tarjetas ------------------------------------------------------------------
  output$t1 <- renderText(if (hay_mun()) "Categoría actual" else "Categoría predominante")
  output$v1 <- renderText(if (hay_mun()) as.character(cat_mun()) else cat_modal()$cat)
  output$s1 <- renderText({
    if (hay_mun()) unname(etiquetas_sequia[as.character(cat_mun())])
    else sprintf("%s · %s (%s de %s municipios)", unname(etiquetas_sequia[cat_modal()$cat]),
                 fmt_pct(cat_modal()$prop), fmt_n(cat_modal()$n), fmt_n(cat_modal()$total))
  })

  output$t2 <- renderText(if (hay_mun()) "Tiempo en sequía (D1–D4)" else "Municipios en sequía (D1–D4)")
  output$v2 <- renderText({
    if (hay_mun()) fmt_pct(tiempo_en(input$municipio, "D1")) else fmt_pct(indicador("municipios", "D1")$prop)
  })
  output$s2 <- renderText({
    if (hay_mun()) {
      r <- rachas_mun()
      t <- fmt_duracion(tiempo_en(input$municipio, "D1") * dias_periodo(rango()))
      if (nrow(r) == 0) sprintf("%s · sin eventos en el periodo", t)
      else sprintf("%s · %d eventos · el más largo, %s días", t, nrow(r), fmt_n(max(r$duracion_dias)))
    } else sub_unidad("municipios", "D1", "municipios")
  })

  output$t3 <- renderText(if (hay_mun()) "Tiempo en sequía extrema o excepcional (D3–D4)" else "Municipios en sequía extrema o excepcional (D3–D4)")
  output$v3 <- renderText({
    if (hay_mun()) fmt_pct(tiempo_en(input$municipio, "D3")) else fmt_pct(indicador("municipios", "D3")$prop)
  })
  output$s3 <- renderText({
    if (hay_mun()) {
      t <- fmt_duracion(tiempo_en(input$municipio, "D3") * dias_periodo(rango()))
      u <- sequia_municipal |> filter(cvegeo == input$municipio, categoria >= "D3", fecha <= fecha_sel()) |> pull(fecha)
      if (length(u) == 0) sprintf("%s · nunca ha estado en D3 o peor", t)
      else sprintf("%s · última vez: %s", t, fmt_fecha(max(u)))
    } else sub_unidad("municipios", "D3", "municipios")
  })

  output$t4 <- renderText(if (hay_mun()) "Superficie" else "Superficie en sequía (D1–D4)")
  output$v4 <- renderText({
    if (hay_mun()) paste(fmt_n(info_mun()$area_km2), "km²") else fmt_pct(indicador("superficie", "D1")$prop)
  })
  output$s4 <- renderText(if (hay_mun()) peso_mun("area_km2") else sub_unidad("superficie", "D1", "km²"))

  output$t5 <- renderText(if (hay_mun()) "Población" else "Población en sequía (D1–D4)")
  output$v5 <- renderText({
    if (hay_mun()) paste(fmt_compacto(info_mun()$poblacion), "hab.") else fmt_pct(indicador("poblacion", "D1")$prop)
  })
  output$s5 <- renderText(if (hay_mun()) peso_mun("poblacion") else sub_unidad("poblacion", "D1", "hab."))

  output$t6 <- renderText(if (hay_mun()) "Racha actual" else "Tiempo en sequía (D1–D4) en el periodo")
  output$v6 <- renderText({
    if (hay_mun()) paste(fmt_n(racha_actual()$dias), "días")
    else fmt_pct(tiempo_en(cvegeos_unidad(), "D1"))
  })
  output$s6 <- renderText({
    if (hay_mun()) {
      r <- racha_actual()
      sprintf("%s desde %s", if (r$en_sequia) "En sequía (D1 o peor)" else "Sin sequía", fmt_fecha(r$desde))
    } else sprintf("%s en promedio por municipio · %s del tiempo en D3 o peor · %s",
                   fmt_duracion(tiempo_en(cvegeos_unidad(), "D1") * dias_periodo(rango())),
                   fmt_pct(tiempo_en(cvegeos_unidad(), "D3")), etiqueta_periodo())
  })

  # ---- Títulos ---------------------------------------------------------------------
  titulo_unidad <- reactive({
    if (hay_mun()) sprintf("%s, %s", info_mun()$nombre_mun, info_mun()$entidad)
    else if (n_ent() > 1) sprintf("%s (%d entidades, %s municipios)", nombre_unidad(), n_ent(), fmt_n(length(cvegeos_unidad())))
    else nombre_unidad()
  })
  output$titulo_mapa  <- renderText(sprintf("%s — %s", titulo_unidad(), fmt_fecha(fecha_sel())))
  output$titulo_dona  <- renderText(sprintf("Municipios de %s por categoría", nombre_unidad()))
  output$titulo_serie <- renderText({
    if (hay_mun()) sprintf("Historial de %s", titulo_unidad())
    else sprintf("Evolución en %s: proporción de municipios por categoría", nombre_unidad())
  })

  # ---- Mapa ------------------------------------------------------------------------
  mun_visible <- reactive({
    if (nacional()) mun_sf else filter(mun_sf, cve_ent %in% cves_ent())
  })
  colores_mun <- function(f) {
    sequia_municipal |>
      filter(fecha == f, cvegeo %in% mun_visible()$cvegeo) |>
      transmute(cvegeo, col = unname(colores_sequia[as.character(categoria)]))
  }
  pct_ent <- function(f) {
    serie_ent_d1 |> filter(fecha == f) |> left_join(entidades, by = "entidad")
  }

  output$mapa <- renderLeaflet({
    leaflet(options = leafletOptions(minZoom = 4)) |>
      addProviderTiles(providers$CartoDB.Positron) |>
      setView(lng = -102, lat = 23.8, zoom = 5)
  })

  observeEvent(list(input$entidad, input$nivel_mapa), {
    f <- isolate(fecha_sel())
    proxy <- leafletProxy("mapa") |> clearShapes() |> clearControls()
    if (input$nivel_mapa == "municipio") {
      geo <- mun_visible() |> left_join(colores_mun(f), by = "cvegeo")
      proxy |>
        addPolygons(
          data = geo, layerId = ~cvegeo,
          fillColor = ~col, fillOpacity = 0.85, color = "#8C8C8C", weight = 0.3,
          label = ~paste0(nombre_mun, ", ", entidad),
          highlightOptions = highlightOptions(weight = 1.5, color = "#1F1F1F", bringToFront = TRUE)
        ) |>
        addLegend("bottomright", colors = unname(colores_sequia),
                  labels = unname(etiquetas_sequia), opacity = 0.9, title = NULL)
    } else {
      geo <- if (nacional()) ent_sf else filter(ent_sf, cve_ent %in% cves_ent())
      geo <- geo |> left_join(select(pct_ent(f), cve_ent, p), by = "cve_ent")
      proxy |>
        addPolygons(
          data = geo, layerId = ~as.character(cve_ent),
          fillColor = ~pal_pct(p), fillOpacity = 0.85, color = "#FFFFFF", weight = 1,
          label = ~sprintf("%s: %.0f %% de municipios en D1+", entidad, 100 * p)
        ) |>
        addLegend("bottomright", pal = pal_pct, values = c(0, 1),
                  labFormat = labelFormat(suffix = " %", transform = \(x) 100 * x),
                  title = "Municipios en D1+", opacity = 0.9)
    }
    bb <- st_bbox(geo)
    proxy |> fitBounds(bb[["xmin"]], bb[["ymin"]], bb[["xmax"]], bb[["ymax"]])
  }, ignoreInit = FALSE, ignoreNULL = FALSE)

  observeEvent(fecha_sel(), {
    f <- fecha_sel()
    if (isolate(input$nivel_mapa) == "municipio") {
      d <- colores_mun(f)
      leafletProxy("mapa") |> setShapeStyle(layerId = d$cvegeo, fillColor = d$col)
    } else {
      d <- pct_ent(f)
      leafletProxy("mapa") |> setShapeStyle(layerId = as.character(d$cve_ent), fillColor = pal_pct(d$p))
    }
  }, ignoreInit = TRUE)

  observeEvent(input$municipio, {
    proxy <- leafletProxy("mapa") |> clearGroup("seleccion")
    if (hay_mun()) {
      g <- filter(mun_sf, cvegeo == input$municipio)
      bb <- st_bbox(g)
      proxy |>
        addPolylines(data = g, group = "seleccion", color = "#1F1F1F", weight = 2.5, opacity = 1) |>
        fitBounds(bb[["xmin"]], bb[["ymin"]], bb[["xmax"]], bb[["ymax"]])
    } else if (!nacional()) {
      bb <- st_bbox(mun_visible())
      proxy |> fitBounds(bb[["xmin"]], bb[["ymin"]], bb[["xmax"]], bb[["ymax"]])
    }
  }, ignoreInit = TRUE)

  # ---- Gráficas ----------------------------------------------------------------
  output$dona <- renderPlot({
    resumen_unidad()$municipios |>
      filter(fecha == fecha_sel()) |>
      graficar_dona(titulo = fmt_fecha(fecha_sel()))
  })

  output$serie <- renderPlot({
    if (hay_mun()) {
      serie_municipio(input$municipio) |>
        transmute(fecha, categoria, n = 1L, valor = 1, total = 1, proporcion = 1, peso = "municipios") |>
        graficar_serie(rango = rango(), fecha_marcada = fecha_sel())
    } else {
      graficar_serie(resumen_unidad()$municipios, rango = rango(), fecha_marcada = fecha_sel())
    }
  })

  output$comparacion <- renderPlot({
    req(n_ent() > 1)
    res_entidad_mun |>
      filter(entidad %in% nombres_ent()) |>
      graficar_serie(rango = rango(), fecha_marcada = fecha_sel(), por = "entidad")
  }, height = function() 120 + 150 * length(input$entidad))

  # ---- Tabla -------------------------------------------------------------------
  output$tabla <- renderDT({
    sequia_municipal |>
      filter(fecha == fecha_sel(), cvegeo %in% cvegeos_unidad()) |>
      left_join(select(catalogo, cvegeo, nombre_mun, entidad, area_km2), by = "cvegeo") |>
      left_join(poblacion_municipal |> filter(anio == anio_sel()) |> select(cvegeo, poblacion), by = "cvegeo") |>
      arrange(desc(categoria), entidad, nombre_mun) |>
      transmute(Clave = cvegeo, Municipio = nombre_mun, Entidad = entidad, Categoría = categoria,
                `Superficie (km²)` = round(area_km2), Población = poblacion)
  }, options = list(pageLength = 12,
                    language = list(url = "//cdn.datatables.net/plug-ins/1.13.6/i18n/es-ES.json")),
  rownames = FALSE)
}

# ---- setShapeStyle: recolorear polígonos sin redibujar ---------------------------
setShapeStyle <- function(map, data = getMapData(map), layerId, stroke = NULL,
                          color = NULL, weight = NULL, opacity = NULL, fill = NULL,
                          fillColor = NULL, fillOpacity = NULL, dashArray = NULL,
                          smoothFactor = NULL, noClip = NULL, options = NULL) {
  options <- c(list(layerId = layerId), options,
               list(stroke = stroke, color = color, weight = weight, opacity = opacity,
                    fill = fill, fillColor = fillColor, fillOpacity = fillOpacity,
                    dashArray = dashArray, smoothFactor = smoothFactor, noClip = noClip))
  options <- options[!vapply(options, is.null, logical(1))]
  options <- leaflet::evalFormula(options, data = data)
  options <- do.call(data.frame, c(options, list(stringsAsFactors = FALSE)))
  leaflet::invokeMethod(map, data, "setStyle", "shape", options[[1]], options[-1])
}

leafletjs <- htmltools::tags$head(htmltools::tags$script(htmltools::HTML("
window.LeafletWidget.methods.setStyle = function(category, layerId, style){
  var map = this;
  if (!layerId) return;
  if (!Array.isArray(layerId)) layerId = [layerId];
  style = HTMLWidgets.dataframeToD3(style);
  layerId.forEach(function(d, i){
    var layer = map.layerManager.getLayer(category, d);
    if (layer) layer.setStyle(style[i]);
  });
};
")))

shinyApp(tagList(leafletjs, ui), server)