source(file.path("R","load_model.R"),encoding="UTF-8")
m <- liq_load_model()
m$liq_packages(liq_public_configuration("market"))
dir.create("results",showWarnings=FALSE)
for(stage in c("pilot","full","market","example")) {
  cfg <- liq_public_configuration(stage)
  write.csv(m$liq_model_spec(cfg),file.path("results",paste0("model_specification_",stage,".csv")),row.names=FALSE)
  dput(cfg,file=file.path("results",paste0("configuration_",stage,".R")))
}
capture.output(sessionInfo(),file="results/current_R_sessionInfo.txt")
cat("Effective pilot/full/market/example profiles and current R environment exported to results/.\n")
