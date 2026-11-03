# Requires the authorized, hash-matching market snapshot; never downloads data.
source(file.path("R","load_model.R"),encoding="UTF-8")
liq_public_run("market")
