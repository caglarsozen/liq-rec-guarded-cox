# Optional for old, complete 600-task outputs that still contain legacy CITL.
source(file.path("R","load_model.R"),encoding="UTF-8")
m <- liq_load_model()
full <- Sys.getenv("LIQ_V480_FULL_DIR",file.path("results","simulation_full"))
out <- Sys.getenv("LIQ_V480_CITL_OUT",paste0(full,"_CITL_DIAGNOSTIC_FIX"))
m$liq_repair_citl_reports_v480(full_dir=full,output_dir=out)
