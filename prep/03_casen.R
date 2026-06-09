# ============================================================
# CASEN 2013-2024: pobreza e ingresos con diseño muestral complejo
# (2011 omitido: metodología antigua de pobreza)
#
# Dos mediciones de pobreza por ingresos:
#  - "comparable_2013": serie histórica (var pobreza/pobreza_mn en 2013-2017;
#     var pobreza_2013 en las bases 2022/2024 re-publicadas)
#  - "nueva_2024": canasta actualizada 2024 (var pobreza en bases 2022/2024)
#
# Salida : data/casen_indicadores.csv  (con columna metodologia)
#          data/casen_deciles.csv      (p10/p50/p90 ingreso per cápita)
# Diseño : varstrat + varunit + expr
# ============================================================
suppressMessages({library(haven); library(survey); library(data.table)})
options(survey.lonely.psu = "adjust")

OUT <- "C:/Users/Joaking/Desktop/paginawebjoaquin/data"
files <- list(
  "2013" = "C:/Users/Joaking/Desktop/CASEN/2013/base2013.dta",
  "2015" = "C:/Users/Joaking/Desktop/CASEN/2015/base2015.dta",
  "2017" = "C:/Users/Joaking/Desktop/CASEN/2017/base2017.dta",
  "2022" = "C:/Users/Joaking/Desktop/CASEN/2022/casen_2022.dta",
  "2024" = "C:/Users/Joaking/Desktop/CASEN/2024/base2024.dta")

pick <- function(cands, nms) { hit <- cands[cands %in% nms]; if (length(hit)) hit[1] else NA_character_ }

reg_nom <- data.table(
  region = 1:16,
  region_nombre = c("Tarapacá","Antofagasta","Atacama","Coquimbo","Valparaíso",
                    "O'Higgins","Maule","Biobío","La Araucanía","Los Lagos",
                    "Aysén","Magallanes","Metropolitana","Los Ríos","Arica y Parinacota","Ñuble"))

estima_pobreza <- function(des, d, vcol, yy, metodo, res) {
  dsub <- subset(des, !is.na(get(vcol)))
  f_tot <- as.formula(paste0("~I(", vcol, " %in% c(1,2))"))
  f_ext <- as.formula(paste0("~I(", vcol, " == 1)"))
  m1 <- svymean(f_tot, dsub); c1 <- confint(m1)
  m2 <- svymean(f_ext, dsub); c2 <- confint(m2)
  res[[length(res)+1]] <- data.table(
    anio = as.integer(yy), metodologia = metodo, nivel = "nacional",
    region = NA_integer_, region_nombre = "Nacional",
    indicador = c("pobreza","pobreza_extrema"),
    est = c(coef(m1)[2], coef(m2)[2])*100, se = c(SE(m1)[2], SE(m2)[2])*100,
    li = c(c1[2,1], c2[2,1])*100, ls = c(c1[2,2], c2[2,2])*100,
    n = sum(!is.na(d[[vcol]])))
  br <- as.data.table(svyby(f_tot, ~region, dsub, svymean, vartype = c("se","ci")))
  setnames(br, c("region","p0","est","se0","se","li0","li","ls0","ls"))
  res[[length(res)+1]] <- data.table(
    anio = as.integer(yy), metodologia = metodo, nivel = "regional", region = br$region,
    region_nombre = reg_nom$region_nombre[match(br$region, reg_nom$region)],
    indicador = "pobreza", est = br$est*100, se = br$se*100, li = br$li*100, ls = br$ls*100,
    n = d[!is.na(get(vcol)), .N, by = region][match(br$region, region), N])
  res
}

res <- list(); dec <- list()
for (yy in names(files)) {
  f <- files[[yy]]
  enc <- if (yy %in% c("2015","2017")) "latin1" else NULL
  nms <- names(read_dta(f, n_max = 0, encoding = enc))
  v_pob  <- pick(c("pobreza","pobreza_mn"), nms)
  v_p13  <- pick(c("pobreza_2013"), nms)        # presente solo en bases 2022/2024
  v_ypc  <- pick(c("ypchtotcor","ypctotcor"), nms)
  v_yth  <- pick(c("ytotcorh"), nms)
  v_np   <- pick(c("numper"), nms)
  v_w    <- pick(c("expr","expr_full","exp"), nms)
  v_str  <- pick(c("varstrat","estrato"), nms)
  v_psu  <- pick(c("varunit"), nms)
  keep   <- na.omit(c("region", v_pob, v_p13, v_ypc, v_yth, v_np, v_w, v_str, v_psu))
  cat(yy, "-> pobreza:", v_pob, "| pobreza_2013:", v_p13, "| ypc:", v_ypc, "| w:", v_w, "\n")

  d <- as.data.table(read_dta(f, col_select = all_of(unname(keep)), encoding = enc))
  d[, region := as.numeric(region)]
  for (cc in setdiff(names(d), "region")) d[[cc]] <- as.numeric(haven::zap_labels(d[[cc]]))
  if (!is.na(v_ypc)) d[, ypc := get(v_ypc)] else d[, ypc := get(v_yth) / get(v_np)]
  d <- d[!is.na(get(v_w)) & get(v_w) > 0]
  cat("  filas:", nrow(d), "\n")

  des <- svydesign(ids = as.formula(paste0("~", v_psu)), strata = as.formula(paste0("~", v_str)),
                   weights = d[[v_w]], data = d, nest = TRUE)

  if (!is.na(v_p13)) {
    # base re-publicada: pobreza = nueva canasta 2024; pobreza_2013 = serie comparable
    res <- estima_pobreza(des, d, v_p13, yy, "comparable_2013", res)
    res <- estima_pobreza(des, d, v_pob, yy, "nueva_2024", res)
  } else {
    res <- estima_pobreza(des, d, v_pob, yy, "comparable_2013", res)
  }

  # ---- ingresos (no dependen de la línea de pobreza) ----
  dq <- subset(des, !is.na(ypc))
  qn <- svyquantile(~ypc, dq, quantiles = c(.1,.5,.9), ci = TRUE)
  qv <- coef(qn)
  dec[[length(dec)+1]] <- data.table(anio = as.integer(yy), nivel = "nacional",
                                     region = NA_integer_, region_nombre = "Nacional",
                                     p10 = qv[1], p50 = qv[2], p90 = qv[3], ratio_90_10 = qv[3]/qv[1])
  qr <- as.data.table(svyby(~ypc, ~region, dq, svyquantile, quantiles = .5, ci = TRUE, vartype = "se"))
  setnames(qr, c("region","p50","se"))
  dec[[length(dec)+1]] <- data.table(anio = as.integer(yy), nivel = "regional", region = qr$region,
                                     region_nombre = reg_nom$region_nombre[match(qr$region, reg_nom$region)],
                                     p10 = NA_real_, p50 = qr$p50, p90 = NA_real_, ratio_90_10 = NA_real_)
  cat("  año", yy, "ok\n")
}

ind <- rbindlist(res); dq <- rbindlist(dec)
fwrite(ind, file.path(OUT, "casen_indicadores.csv"))
fwrite(dq,  file.path(OUT, "casen_deciles.csv"))
cat("LISTO. indicadores:", nrow(ind), "| deciles:", nrow(dq), "\n")
print(ind[nivel == "nacional" & indicador == "pobreza", .(anio, metodologia, est = round(est,2))])
