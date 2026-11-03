# One illustrative simulation replication; not a replacement for the 600-run study.
source(file.path("R","load_model.R"),encoding="UTF-8")
m <- liq_load_model()
root <- normalizePath(getwd(),winslash="/")
answer <- liq_with_environment(liq_public_environment("example",root), {
  cfg <- m$liq_v480_config("pilot")
  cfg$out_dir <- file.path(root,"results","example")
  m$liq_packages(cfg)
  path <- m$liq_dir(file.path(cfg$out_dir,"non_PH_001"))
  m$liq_v480_one(cfg,"non_PH",1L,path,oracle=FALSE)
})
cat("Illustrative example completed. Independent-oracle coverage was not evaluated.\n")
print(answer$point[model%in%c("Cox_raw","Logit_raw","LIQ_Brier","LIQ_Rank_Guard"),
  .(Brier=mean(Brier),AUC=mean(AUC)),by=model])
