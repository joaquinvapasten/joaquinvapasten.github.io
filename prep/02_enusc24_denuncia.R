# ============================================================
# ENUSC 2024: denuncia, cifra negra y motivos de no denuncia
# Insumo : enusc2024.sav (INE)
# Salida : data/enusc24_denuncia_delito.csv  (tasa denuncia + cifra negra por delito)
#          data/enusc24_motivos.csv          (motivos de no denuncia por delito)
#          data/enusc24_denuncia_region.csv  (tasa de denuncia por región, delitos clásicos)
# Diseño : VarStrat + Conglomerado + Fact_Pers_Reg / Fact_Hog_Reg
# ============================================================
suppressMessages({library(haven); library(survey); library(data.table)})
options(survey.lonely.psu = "adjust")

IN  <- "C:/Users/Joaking/Desktop/No denuncia/nuevo intento paper no denuncia/data/enusc2024.sav"
OUT <- "C:/Users/Joaking/Desktop/paginawebjoaquin/data"

mods <- data.table(
  pref = c("RDV","RDDV","VANDVHC","RFV","VANDVIV","RVI","RPS","HUR",
           "FRB","EST","AGR","AMEN","EXT","SOB","HACK","VIRUS","BULLY","SUPLANT"),
  delito = c("Robo de vehículo","Robo desde vehículo","Vandalismo a vehículo",
             "Robo en la vivienda","Vandalismo a la vivienda",
             "Robo con violencia","Robo por sorpresa","Hurto",
             "Fraude bancario","Estafa","Agresión","Amenaza","Extorsión",
             "Soborno","Hackeo de cuentas","Virus informático","Ciberacoso","Suplantación de identidad"),
  nivel = c("hogar","hogar","hogar","hogar","hogar",
            "persona","persona","persona","persona","persona","persona","persona",
            "persona","persona","persona","persona","persona","persona"))

hdr <- read_sav(IN, n_max = 0)
vars_all <- names(hdr)
den_v <- paste0(mods$pref, "_DENUNCIA"); mot_v <- paste0(mods$pref, "_MOTIV_NO_DEN")
mods <- mods[den_v %in% vars_all]
den_v <- paste0(mods$pref, "_DENUNCIA"); mot_v <- paste0(mods$pref, "_MOTIV_NO_DEN")
mot_v <- mot_v[mot_v %in% vars_all]
cat("módulos con _DENUNCIA:", nrow(mods), "\n")

keep <- unique(c("enc_region","VarStrat","Conglomerado","Fact_Pers_Reg","Fact_Hog_Reg", den_v, mot_v))
d <- as.data.table(read_sav(IN, col_select = all_of(keep)))
cat("filas:", nrow(d), "cols:", ncol(d), "\n")

# conservar etiquetas de motivos como texto y desetiquetar todo lo demás
for (mv in mot_v) d[, paste0(mv, "_lab") := as.character(haven::as_factor(get(mv)))]
num_cols <- setdiff(names(d), paste0(mot_v, "_lab"))
d[, (num_cols) := lapply(.SD, function(x) as.numeric(haven::zap_labels(x))), .SDcols = num_cols]
d[, region := as.numeric(enc_region)]

reg_nom <- data.table(
  region = 1:16,
  region_nombre = c("Tarapacá","Antofagasta","Atacama","Coquimbo","Valparaíso",
                    "O'Higgins","Maule","Biobío","La Araucanía","Los Lagos",
                    "Aysén","Magallanes","Metropolitana","Los Ríos","Arica y Parinacota","Ñuble"))

res_del <- list(); res_mot <- list(); res_reg <- list()
for (k in seq_len(nrow(mods))) {
  pr <- mods$pref[k]
  dv <- paste0(pr, "_DENUNCIA"); mv <- paste0(pr, "_MOTIV_NO_DEN")
  wcol <- if (mods$nivel[k] == "hogar") "Fact_Hog_Reg" else "Fact_Pers_Reg"
  sub <- d[!is.na(get(dv)) & get(dv) %in% c(1, 2) & !is.na(get(wcol)) & get(wcol) > 0]
  if (nrow(sub) < 30) next
  des <- svydesign(ids = ~Conglomerado, strata = ~VarStrat,
                   weights = sub[[wcol]], data = sub, nest = TRUE)
  f <- as.formula(paste0("~I(", dv, "==1)"))
  m <- svymean(f, des); ci <- confint(m)
  res_del[[length(res_del)+1]] <- data.table(
    delito = mods$delito[k], pref = pr, nivel = mods$nivel[k],
    tasa_denuncia = coef(m)[2]*100, se = SE(m)[2]*100,
    li = ci[2,1]*100, ls = ci[2,2]*100,
    cifra_negra = (1-coef(m)[2])*100, n_victimas = nrow(sub))

  # motivos de no denuncia (entre quienes NO denunciaron)
  if (mv %in% names(sub)) {
    nb <- sub[get(dv) == 2 & !is.na(get(mv)) & get(mv) < 85]
    if (nrow(nb) >= 30) {
      nb[, motivo := get(paste0(mv, "_lab"))]
      desn <- svydesign(ids = ~Conglomerado, strata = ~VarStrat,
                        weights = nb[[wcol]], data = nb, nest = TRUE)
      mm <- svymean(~factor(motivo), desn)
      tt <- data.table(motivo = sub("^factor\\(motivo\\)", "", names(coef(mm))),
                       pct = coef(mm)*100, se = SE(mm)*100)
      tt[, `:=`(delito = mods$delito[k], pref = pr, n_no_denuncia = nrow(nb))]
      res_mot[[length(res_mot)+1]] <- tt
    }
  }

  # por región: solo delitos clásicos con n suficiente
  if (pr %in% c("RVI","RPS","HUR","RFV","RDDV","EST")) {
    br <- tryCatch({
      bb <- as.data.table(svyby(f, ~region, des, svymean, vartype = c("se","ci")))
      setnames(bb, c("region","p0","est","se0","se","li0","li","ls0","ls"))
      nn <- sub[, .N, by = region]
      merge(bb[, .(region, est = est*100, se = se*100, li = li*100, ls = ls*100)], nn, by = "region")
    }, error = function(e) {cat("  region falló:", pr, conditionMessage(e), "\n"); NULL})
    if (!is.null(br)) {
      br[, `:=`(delito = mods$delito[k], pref = pr)]
      res_reg[[length(res_reg)+1]] <- br
    }
  }
  cat(pr, "ok\n")
}

del <- rbindlist(res_del)[order(-tasa_denuncia)]
mot <- rbindlist(res_mot)
reg <- merge(rbindlist(res_reg), reg_nom, by = "region")
fwrite(del, file.path(OUT, "enusc24_denuncia_delito.csv"))
fwrite(mot, file.path(OUT, "enusc24_motivos.csv"))
fwrite(reg, file.path(OUT, "enusc24_denuncia_region.csv"))
cat("LISTO. delitos:", nrow(del), "| motivos:", nrow(mot), "| region:", nrow(reg), "\n")
