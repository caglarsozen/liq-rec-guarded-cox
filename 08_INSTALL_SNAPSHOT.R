# Supply LIQ_SNAPSHOT_ARCHIVE, a command-line ZIP argument, or use the file picker.
source(file.path("R","install_snapshot.R"),encoding="UTF-8")
args <- commandArgs(trailingOnly=TRUE)
archive <- Sys.getenv("LIQ_SNAPSHOT_ARCHIVE",if(length(args))args[1L]else"")
if (!nzchar(archive) && interactive()) archive <- file.choose()
if (!nzchar(archive)) stop("Provide the authorized Online Resource 2 or manuscript-package ZIP path.")
liq_install_snapshot(archive)
