# Public entry point. The archived model source is verified and sourced safely.
liq_with_environment <- function(values, code) {
  previous <- Sys.getenv(names(values), unset=NA_character_)
  on.exit({
    absent <- is.na(previous)
    if (any(absent)) Sys.unsetenv(names(previous)[absent])
    if (any(!absent)) do.call(Sys.setenv, as.list(previous[!absent]))
  }, add=TRUE)
  do.call(Sys.setenv, as.list(values))
  force(code)
}

liq_load_model <- function(root=getwd(), stable_citl=TRUE) {
  root <- normalizePath(root, winslash="/", mustWork=TRUE)
  source_path <- file.path(root, "LIQ_REC_Fin_Major_Revision_v4_8_0.R")
  if (!file.exists(source_path)) stop("Run from the repository root, or pass root= explicitly.")
  expected <- "ed19ad4035b799915163897644a8515c"
  if (!identical(unname(tools::md5sum(source_path)), expected))
    stop("Frozen model source differs from the archived scientific specification.")
  model <- new.env(parent=globalenv())
  liq_with_environment(c(LIQ_AUTORUN="false", LIQ_INSTALL_MISSING="false",
                        LIQ_CITL_REPAIR_AUTORUN="false"), {
    sys.source(source_path, envir=model, keep.source=FALSE)
    model$LIQ_SOURCE_PATH <- source_path
    sys.source(file.path(root, "R", "repair_archived_citl.R"),
               envir=model, keep.source=FALSE)
  })
  # These S3 methods must remain discoverable when the model lives in an
  # isolated environment, including the validated ridge fallback path.
  registerS3method("coef", "liq_ridge_path", model$coef.liq_ridge_path,
                   envir=asNamespace("stats"))
  registerS3method("predict", "liq_ridge_path", model$predict.liq_ridge_path,
                   envir=asNamespace("stats"))
  if (isTRUE(stable_citl)) {
    model$.liq_original_calibration <- model$liq_calibration
    model$liq_calibration <- eval(quote(function(y,p,w=rep(1,length(y))) {
      answer <- .liq_original_calibration(y,p,w)
      answer["CITL"] <- liq_citl_stable_v480(y,p,w)
      answer
    }), envir=model)
  }
  attr(model, "repo_root") <- root
  attr(model, "reporting_patch") <- isTRUE(stable_citl)
  model
}

liq_public_environment <- function(stage=c("pilot","full","market","example"), root=getwd()) {
  stage <- match.arg(stage)
  root <- normalizePath(root, winslash="/", mustWork=TRUE)
  folder <- switch(stage, full="simulation_full", stage)
  out <- file.path(root,"results",folder)
  # Explicit public profiles must not inherit scientific inputs or output
  # routing from another R session. liq_with_environment restores them later.
  c(LIQ_AUTORUN="false", LIQ_CITL_REPAIR_AUTORUN="false",
    LIQ_MODE="full", LIQ_INSTALL_MISSING="false", LIQ_REFRESH_DATA="false",
    LIQ_DATA_MODE="csv", LIQ_UNIVERSE="expanded100", LIQ_SYMBOLS="",
    LIQ_INPUT_CSV=file.path(root,"data","frozen_ohlcv.csv"),
    LIQ_MEMBERSHIP_FILE="", LIQ_ASSET_METADATA="", LIQ_CONTEXT_FILE="",
    LIQ_ALLOW_MISSING_ASSETS="false", LIQ_PREFLIGHT_ONLY="false",
    LIQ_TRAIN_FREEZE="", LIQ_BOOT_REPS="1999",
    LIQ_RUN_SENSITIVITY="false", LIQ_RUN_ROLLING="true",
    LIQ_RUN_SIMULATION="false", LIQ_RUN_ABLATIONS="false", LIQ_RUN_PANEL_CHECKS="false",
    LIQ_THREADS="1", LIQ_V470_SIM_DAYS="3600", LIQ_REQUIRE_SNAPSHOT_LOCK="true",
    LIQ_V480_PILOT_REPS="2", LIQ_V480_FULL_REPS="100",
    LIQ_V480_ORACLE_BATCHES="8",
    LIQ_V480_ORACLE_ORIGINS=if(stage%in%c("pilot","example"))"250"else"2000",
    LIQ_V480_SCENARIOS="signal,no_regime,prevalence_shift,regime_reversal,non_PH,strong_dependence",
    LIQ_CACHE_DIR=file.path(root,"results","frozen_cache"),
    LIQ_V480_PILOT_DIR=file.path(root,"results","pilot"),
    LIQ_OUT_DIR=out, LIQ_V470_OUT_DIR=out, LIQ_V480_OUT_DIR=out,
    LIQ_V480_PROGRESS_DIR=out,
    LIQ_V480_MARKET_OUT_DIR=file.path(root,"results","market"))
}

liq_public_run <- function(stage=c("pilot","full","market"), root=getwd()) {
  stage <- match.arg(stage)
  root <- normalizePath(root, winslash="/", mustWork=TRUE)
  model <- liq_load_model(root)
  values <- liq_public_environment(stage,root)
  liq_with_environment(values, {
    if (stage=="market") {
      sys.source(file.path(root,"R","install_snapshot.R"),envir=model)
      model$liq_verify_public_snapshot(root)
      model$liq_v480_market()
    } else model$liq_v480_run(stage)
  })
}

liq_public_configuration <- function(stage=c("pilot","full","market","example"), root=getwd()) {
  stage <- match.arg(stage)
  root <- normalizePath(root, winslash="/", mustWork=TRUE)
  model <- liq_load_model(root)
  liq_with_environment(liq_public_environment(stage,root), {
    cfg <- if(stage=="market")model$liq_config() else
      model$liq_v480_config(if(stage=="example")"pilot"else stage)
    cfg$out_dir <- Sys.getenv("LIQ_V480_OUT_DIR")
    cfg
  })
}
