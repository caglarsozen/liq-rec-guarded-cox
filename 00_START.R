source(file.path("R","load_model.R"),encoding="UTF-8")
liq <- liq_load_model()
cat("Frozen LIQ-REC model 4.8.0 loaded; no estimation or download started.\n",
    "Install packages once: source('00_INSTALL.R')\n",
    "Quick checks:          source('01_QUICK_CHECK.R')\n",
    "One example:           source('02_RUN_EXAMPLE.R')\n",
    "Pilot (12 attempts):   source('03_RUN_PILOT.R')\n",
    "Full simulation (600): source('04_RUN_SIMULATION.R')\n",
    "Historical + rolling: source('05_RUN_MARKET.R')\n",
    "Install snapshot:      source('08_INSTALL_SNAPSHOT.R')\n",sep="")
