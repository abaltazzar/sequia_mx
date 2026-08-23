test_that("sequia_municipal es consistente", {
  expect_s3_class(sequia_municipal$categoria, "ordered")
  expect_equal(levels(sequia_municipal$categoria), niveles_sequia)
  expect_false(anyNA(sequia_municipal$categoria))
  expect_equal(n_distinct_cvegeo <- length(unique(sequia_municipal$cvegeo)),
               nrow(catalogo_municipios))
  # cada municipio tiene todas las fechas
  conteo <- table(sequia_municipal$cvegeo)
  expect_equal(length(unique(conteo)), 1L)
})

test_that("resumen_entidad suma 1 por unidad-fecha", {
  r <- resumen_entidad(nivel_geo = "nacional", fechas = fecha_corte())
  expect_equal(sum(r$proporcion), 1, tolerance = 1e-9)
  expect_equal(sum(r$n), nrow(catalogo_municipios))
  r2 <- resumen_entidad(nivel_geo = "entidad", fechas = fecha_corte())
  sumas <- tapply(r2$proporcion, r2$entidad, sum)
  expect_true(all(abs(sumas - 1) < 1e-9))
})

test_that("rachas no se traslapan", {
  r <- rachas_sequia(umbral = "D1")
  expect_true(all(r$fin >= r$inicio))
  expect_true(all(r$duracion_dias > 0))
})
