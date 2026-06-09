# ============================================================
# CASEN 2013-2024: pobreza e ingresos con diseño muestral complejo
# (2022 omitido: archivo local en 0 bytes; 2011 omitido: metodología antigua)
# Salida : data/casen_indicadores.csv  (nacional y regional, por año)
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
  "2024" = "C:/Users/Joaking/Desktop/CASEN/2024/base2024.dta")

pick <- function(cands, nms) { hit <- cands[cands %in% nms]; if (length(hit)) hit[1] else NA_character_ }

reg_nom <- data.table(
  region = 1:16,
  region_nombre = c("Tarapacá","Antofagasta","Atacama","Coquimbo","Valparaíso",
                    "O'Higgins","Maule","Biobío","La Araucanía","Los Lagos",
                    "Aysén","Magallanes","Metropolitana","Los Ríos","Arica y Parinacota","Ñuble"))

res <- list(); dec <- list()
for (yy in names(files)) {
  f <- files[[yy]]
  nms <- names(read_dta(f, n_max = 0, encoding = if (yy %in% c("2015","2017")) "latin1" else NULL))
  v_pob <- pick(c("pobreza","pobreza_mn"), nms)
  v_ypc <- pick(c("ypchtotcor","ypctotcor"), nms)
  v_yth <- pick(c("ytotcorh"), nms)
  v_np  <- pick(c("numper"), nms)
  v_w   <- pick(c("expr","expr_full","exp"), nms)
  v_str <- pick(c("varstrat","estrato"), nms)
  v_psu <- pick(c("varunit"), nms)
  keep  <- na.omit(c("region", v_pob, v_ypc, v_yth, v_np, v_w, v_str, v_psu))
  cat(yy, "-> pobreza:", v_pob, "| ypc:", v_ypc, "| w:", v_w, "| strat:", v_str, "| psu:", v_psu, "\n")

  d <- as.data.table(read_dta(f, col_select = all_of(unname(keep)),
                              encoding = if (yy %in% c("2015","2017")) "latin1" else NULL))
  d[, region := as.numeric(region)]
  d[, pobreza_v := as.numeric(get(v_pob))]
  if (!is.na(v_ypc)) d[, ypc := as.numeric(get(v_ypc))] else d[, ypc := as.numeric(get(v_yth)) / as.numeric(get(v_np))]
  d <- d[!is.na(get(v_w)) & get(v_w) > 0 & !is.na(pobreza_v)]
  cat("  filas:", nrow(d), "\n")

  des <- svydesign(ids = as.formula(paste0("~", v_psu)), strata = as.formula(paste0("~", v_str)),
                   weights = d[[v_w]], data = d, nest = TRUE)

  # ---- pobreza (1 extrema, 2 no extrema, 3 no pobre) ----
  m1 <- svymean(~I(pobreza_v %in% c(1,2)), des); c1 <- confint(m1)
  m2 <- svymean(~I(pobreza_v == 1), des);        c2 <- confint(m2)
  res[[length(res)+1]] <- data.table(
    anio = as.integer(yy), nivel = "nacional", region = NA_integer_, region_nombre = "Nacional",
    indicador = c("pobreza","pobreza_extrema"),
    est = c(coef(m1)[2], coef(m2)[2])*100, se = c(SE(m1)[2], SE(m2)[2])*100,
    li = c(c1[2,1], c2[2,1])*100, ls = c(c1[2,2], c2[2,2])*100, n = nrow(d))

  br <- as.data.table(svyby(~I(pobreza_v %in% c(1,2)), ~region, des, svymean, vartype = c("se","ci")))
  setnames(br, c("region","p0","est","se0","se","li0","li","ls0","ls"))
  res[[length(res)+1]] <- data.table(
    anio = as.integer(yy), nivel = "regional", region = br$region,
    region_nombre = reg_nom$region_nombre[match(br$region, reg_nom$region)],
    indicador = "pobreza", est = br$est*100, se = br$se*100, li = br$li*100, ls = br$ls*100,
    n = d[, .N, by = region][match(br$region, region), N])

  # ---- mediana ingreso per cápita hogar (nacional y regional) ----
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
