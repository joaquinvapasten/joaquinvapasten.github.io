# ============================================================
# Catálogo unificado región×año para el Explorador de datos
# Une los agregados ya calculados (ENUSC + CASEN) en un solo CSV largo.
# region = 0 -> Nacional
# Salida: data/explorador.csv
# ============================================================
suppressMessages(library(data.table))
D <- "C:/Users/Joaking/Desktop/paginawebjoaquin/data"

nac  <- fread(file.path(D, "enusc_serie_nacional.csv"))
reg  <- fread(file.path(D, "enusc_serie_regional.csv"))
cas  <- fread(file.path(D, "casen_indicadores.csv"))
dcl  <- fread(file.path(D, "casen_deciles.csv"))
del  <- fread(file.path(D, "enusc24_denuncia_delito.csv"))
dreg <- fread(file.path(D, "enusc24_denuncia_region.csv"))

et_enusc <- function(v, e) paste0(e, " (%)")

out <- list()

# ---- ENUSC nacional ----
out$en <- nac[, .(fuente = "ENUSC (INE)", indicador = paste0("enusc_", indicador),
                  nombre = et_enusc(indicador, etiqueta), unidad = "%",
                  anio, region = 0L, region_nombre = "Nacional", est, li, ls)]

# ---- ENUSC regional ----
out$er <- reg[, .(fuente = "ENUSC (INE)", indicador = paste0("enusc_", indicador),
                  nombre = et_enusc(indicador, etiqueta), unidad = "%",
                  anio, region = region16, region_nombre, est, li, ls)]

# ---- CASEN pobreza (ambas metodologías) ----
cas[, ind2 := fifelse(metodologia == "nueva_2024",
                      paste0("casen_", indicador, "_n24"),
                      paste0("casen_", indicador, "_comp"))]
cas[, nom2 := fcase(
  indicador == "pobreza" & metodologia == "comparable_2013", "Pobreza por ingresos — serie comparable (%)",
  indicador == "pobreza" & metodologia == "nueva_2024",      "Pobreza por ingresos — metodología 2024 (%)",
  indicador == "pobreza_extrema" & metodologia == "comparable_2013", "Pobreza extrema — serie comparable (%)",
  indicador == "pobreza_extrema" & metodologia == "nueva_2024",      "Pobreza extrema — metodología 2024 (%)")]
out$ca <- cas[, .(fuente = "CASEN (MDSF)", indicador = ind2, nombre = nom2, unidad = "%",
                  anio, region = fifelse(nivel == "nacional", 0L, as.integer(region)),
                  region_nombre, est, li, ls)]

# ---- CASEN ingresos ----
out$ing <- dcl[, .(fuente = "CASEN (MDSF)", indicador = "casen_mediana_ypc",
                   nombre = "Mediana ingreso per cápita del hogar ($)", unidad = "$",
                   anio, region = fifelse(nivel == "nacional", 0L, as.integer(region)),
                   region_nombre, est = p50, li = NA_real_, ls = NA_real_)]
out$r90 <- dcl[nivel == "nacional",
               .(fuente = "CASEN (MDSF)", indicador = "casen_ratio_90_10",
                 nombre = "Desigualdad p90/p10 (veces)", unidad = "veces",
                 anio, region = 0L, region_nombre = "Nacional",
                 est = ratio_90_10, li = NA_real_, ls = NA_real_)]

# ---- Denuncia 2024 (solo delitos con desagregación regional) ----
prefs <- intersect(unique(dreg$pref), unique(del$pref))
deln <- del[pref %in% prefs,
            .(fuente = "ENUSC 2024 (INE)", indicador = paste0("den_", tolower(pref)),
              nombre = paste0("Tasa de denuncia: ", tolower(delito), " (%)"), unidad = "%",
              anio = 2024L, region = 0L, region_nombre = "Nacional",
              est = tasa_denuncia, li, ls)]
delr <- dreg[, .(fuente = "ENUSC 2024 (INE)", indicador = paste0("den_", tolower(pref)),
                 nombre = paste0("Tasa de denuncia: ", tolower(delito), " (%)"), unidad = "%",
                 anio = 2024L, region = as.integer(region), region_nombre, est, li, ls)]
out$dn <- deln; out$dr <- delr

X <- rbindlist(out, use.names = TRUE)
X[, `:=`(est = round(est, 2), li = round(li, 2), ls = round(ls, 2))]

# cobertura regional por indicador (para que el explorador sepa qué permite cada herramienta)
cob <- X[region > 0, .(cobertura = "regional"), by = indicador]
X <- merge(X, cob, by = "indicador", all.x = TRUE)
X[is.na(cobertura), cobertura := "nacional"]

setorder(X, indicador, anio, region)
fwrite(X, file.path(D, "explorador.csv"))
cat("LISTO:", nrow(X), "filas |", uniqueN(X$indicador), "indicadores\n")
print(X[, .(n = .N, años = paste0(min(anio), "-", max(anio)), cob = cobertura[1]), by = .(indicador, nombre)])
