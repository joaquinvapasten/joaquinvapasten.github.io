# ============================================================
# ENUSC interanual 2008-2024: series con diseño muestral complejo
# Insumo : base interanual INE (csv ;, dec ,)
# Salida : data/enusc_serie_nacional.csv, data/enusc_serie_regional.csv
# Diseño : estratos (varstrat) + conglomerados + factor por período
#          2008-2019 -> fact_*_2008_2019 ; 2020-2024 -> fact_*_2019_2024
# ============================================================
suppressMessages({library(data.table); library(survey)})
options(survey.lonely.psu = "adjust")

IN  <- "C:/Users/Joaking/Desktop/No denuncia/ENUSC/2024/base-de-datos---interanual-2008---2024-csv.csv"
OUT <- "C:/Users/Joaking/Desktop/paginawebjoaquin/data"

dt <- fread(IN, sep = ";", dec = ",", encoding = "Latin-1", showProgress = FALSE)
setnames(dt, names(dt)[ncol(dt)], "anio")           # "año" llega con encoding frágil
cat("filas:", nrow(dt), "| años:", paste(sort(unique(dt$anio)), collapse = " "), "\n")
cat("años con region16:", paste(sort(unique(dt$anio[!is.na(dt$region16)])), collapse = " "), "\n")

dt[, w_pers := fifelse(anio <= 2019, fact_pers_2008_2019, fact_pers_2019_2024)]
dt[, w_hog  := fifelse(anio <= 2019, fact_hog_2008_2019,  fact_hog_2019_2024)]

reg_nom <- data.table(
  region16 = 1:16,
  region_nombre = c("Tarapacá","Antofagasta","Atacama","Coquimbo","Valparaíso",
                    "O'Higgins","Maule","Biobío","La Araucanía","Los Lagos",
                    "Aysén","Magallanes","Metropolitana","Los Ríos","Arica y Parinacota","Ñuble"))

# indicador, peso, nivel, filtro
ind <- rbind(
  data.table(var="vh_dmcs", w="w_hog",  nivel="hogar",   etiqueta="Hogar víctima de delito (DMCS)"),
  data.table(var="rfv",     w="w_hog",  nivel="hogar",   etiqueta="Robo con fuerza en la vivienda"),
  data.table(var="rdv",     w="w_hog",  nivel="hogar",   etiqueta="Robo de vehículo (hogares con vehículo)"),
  data.table(var="rddv",    w="w_hog",  nivel="hogar",   etiqueta="Robo desde vehículo (hogares con vehículo)"),
  data.table(var="pad",     w="w_pers", nivel="persona", etiqueta="Percepción: aumentó la delincuencia en el país"),
  data.table(var="rvi",     w="w_pers", nivel="persona", etiqueta="Robo con violencia o intimidación"),
  data.table(var="rps",     w="w_pers", nivel="persona", etiqueta="Robo por sorpresa"),
  data.table(var="hur",     w="w_pers", nivel="persona", etiqueta="Hurto"),
  data.table(var="les",     w="w_pers", nivel="persona", etiqueta="Lesiones"))

res_nac <- list(); res_reg <- list()
for (yy in sort(unique(dt$anio))) {
  dy <- dt[anio == yy]
  for (k in seq_len(nrow(ind))) {
    v <- ind$var[k]; wcol <- ind$w[k]
    sub <- dy[!is.na(get(v)) & !is.na(get(wcol)) & get(wcol) > 0]
    if (v %in% c("rdv","rddv")) sub <- sub[prop_vehiculos == 1]
    if (nrow(sub) < 100) next
    des <- svydesign(ids = ~conglomerado, strata = ~varstrat,
                     weights = sub[[wcol]], data = sub, nest = TRUE)
    f <- as.formula(paste0("~I(", v, "==1)"))
    m <- svymean(f, des); ci <- confint(m)
    res_nac[[length(res_nac)+1]] <- data.table(
      anio = yy, indicador = v, etiqueta = ind$etiqueta[k], nivel = ind$nivel[k],
      est = coef(m)[2]*100, se = SE(m)[2]*100, li = ci[2,1]*100, ls = ci[2,2]*100, n = nrow(sub))
    # regional (solo si region16 disponible y para indicadores clave)
    if (v %in% c("vh_dmcs","pad","rvi","rps","hur") && sum(!is.na(sub$region16)) > 1000) {
      sub2 <- sub[!is.na(region16)]
      des2 <- svydesign(ids = ~conglomerado, strata = ~varstrat,
                        weights = sub2[[wcol]], data = sub2, nest = TRUE)
      br <- svyby(f, ~region16, des2, svymean, vartype = c("se","ci"))
      br <- as.data.table(br)
      setnames(br, c("region16","p0","est","se0","se","li0","li","ls0","ls"))
      res_reg[[length(res_reg)+1]] <- data.table(
        anio = yy, indicador = v, etiqueta = ind$etiqueta[k],
        region16 = br$region16, est = br$est*100, se = br$se*100,
        li = br$li*100, ls = br$ls*100)
    }
  }
  cat("año", yy, "ok\n")
}

nac <- rbindlist(res_nac)
reg <- merge(rbindlist(res_reg), reg_nom, by = "region16")
fwrite(nac, file.path(OUT, "enusc_serie_nacional.csv"))
fwrite(reg, file.path(OUT, "enusc_serie_regional.csv"))
cat("LISTO. nacional:", nrow(nac), "filas | regional:", nrow(reg), "filas\n")
