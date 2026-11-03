# ============================================================================
# LIQ-REC-Fin 4.8.0 | validated numerics and chronological GUARD confirmation | 2026-11-01
# Standalone R entry point. All user switches are in liq_config().
# Default: long-calendar simulated-event pilot; v4.6.0 forecasting rules are preserved below.
# 40 US equity ETFs + 60 equities; ^VIX is a covariate, not the 101st model asset.
# The 29-asset input is preserved; 71 new series are separately dated and documented.
# Yahoo is explicit opt-in. Default analysis never downloads or refreshes inputs.
# Source safely: Sys.setenv(LIQ_AUTORUN="false"); source("this_file.R")
# Offline verification: LIQ_MODE=smoke, LIQ_DATA_MODE=synthetic (explicit only).
# This is a retrospective re-analysis; the historical test has already been seen.
# Synthetic data are NEVER substituted for failed market-data downloads.
# ============================================================================

LIQ_SOURCE_PATH <- local({
  files<-vapply(sys.frames(),function(f) {
    v<-get0("ofile",envir=f,inherits=FALSE)
    if(is.character(v)&&length(v)==1L)v else ""
  },character(1))
  files<-files[nzchar(files)&file.exists(files)]
  if(length(files))return(normalizePath(tail(files,1),winslash="/",mustWork=TRUE))
  arg<-grep("^--file=",commandArgs(FALSE),value=TRUE)
  path<-if(length(arg))sub("^--file=","",tail(arg,1))else Sys.getenv("LIQ_SOURCE_FILE","")
  if(nzchar(path)&&file.exists(path))normalizePath(path,winslash="/",mustWork=TRUE)else ""
})
liq_config <- function() {
  env_bool <- function(n, d) tolower(Sys.getenv(n, if (d) "true" else "false")) %in% c("true","1","yes")
  mode <- tolower(Sys.getenv("LIQ_MODE", "full"))
  stopifnot(mode %in% c("smoke", "full"))
  small <- mode == "smoke"
  baseline <- c("SPY","QQQ","IWM","DIA","XLK","XLF","XLE","XLV","XLP","XLY",
            "XLI","XLU","XLB","XLRE","XLC","AAPL","MSFT","NVDA","META","TSLA",
            "JPM","BAC","XOM","CVX","JNJ","WMT","PG","V","MA")
  extra_etf <- c("VTI","VOO","IVV","RSP","MDY","IJR","IJH","VBR","VB","VO","VTV","VUG",
    "IWD","IWF","IWB","IWR","IWO","IWN","ITOT","SCHB","SCHX","SCHA","SCHM","SCHV","SCHG")
  extra_equity <- c("AMZN","GOOGL","AVGO","AMD","INTC","ORCL","ADBE","CRM","CSCO","QCOM",
    "TXN","IBM","MU","AMAT","LRCX","GS","MS","WFC","C","AXP","SCHW","USB","PNC","BLK",
    "UNH","MRK","ABBV","PFE","ABT","TMO","AMGN","GILD","COST","HD","LOW","NKE","MCD",
    "SBUX","KO","PEP","PM","CAT","DE","UPS","BA","RTX")
  universe <- tolower(Sys.getenv("LIQ_UNIVERSE","expanded100"))
  stopifnot(universe %in% c("expanded100","baseline29"))
  syms <- if(universe=="baseline29")baseline else c(baseline,extra_etf,extra_equity)
  if (small) syms <- c("SPY","QQQ","XLF","XLE","AAPL","MSFT")
  if (nzchar(Sys.getenv("LIQ_SYMBOLS"))) {
    syms <- trimws(strsplit(Sys.getenv("LIQ_SYMBOLS"), ",", fixed=TRUE)[[1]])
    universe <- "custom_declared_before_run"
  }
  stopifnot(length(syms)>0L,!anyNA(syms),all(nzchar(syms)),!anyDuplicated(syms),!"^VIX"%in%syms)
  root <- if(nzchar(LIQ_SOURCE_PATH))dirname(LIQ_SOURCE_PATH)else getwd()
  default_input <- file.path(root,"data",if(universe=="baseline29")"baseline_29_ohlcv.csv"else"frozen_ohlcv.csv")
  list(version="4.6.0", mode=mode, seed=123L,
    frozen_file=Sys.getenv("LIQ_TRAIN_FREEZE",""),
    correction_inner_fractions=c(.35,.45,.55,.65,.75,.85),batch_groups=2L,batch_min_H=3L,
    correction_lambda_grid=c(.3,.1,.03,.01,.003),correction_gamma_grid=c(0,.25,.5,.75,1),
    sn_min_dates=40L,publication_export=env_bool("LIQ_PUBLICATION_EXPORT",TRUE),
    data_mode=tolower(Sys.getenv("LIQ_DATA_MODE", "csv")),
    input_csv=Sys.getenv("LIQ_INPUT_CSV",default_input),
    universe_name=universe,reference_symbols=baseline,
    equity_symbols=c(baseline[16:29],extra_equity),sector_etf_symbols=baseline[5:15],
    universe_file=file.path(root,"universe","universe_100.csv"),
    require_snapshot_lock=env_bool("LIQ_REQUIRE_SNAPSHOT_LOCK",TRUE),
    source_path=LIQ_SOURCE_PATH,dt_threads=as.integer(Sys.getenv("LIQ_THREADS","1")),
    preflight_only=env_bool("LIQ_PREFLIGHT_ONLY",FALSE),
    require_class_support=TRUE,
    mix_eta_grid=c(0,1,3,6),mix_shrink_grid=c(0,.25,.5,.75,1),
    guard_margin_z=1,guard_min_gain=0,rank_min_gain=.005,
    selection_min_dates=3L,selection_min_assets=2L,
    rolling_span=2000L,rolling_step=250L,rolling_fractions=c(.50,.75,.875),rolling_append_tail=TRUE,
    cache_dir=Sys.getenv("LIQ_CACHE_DIR", "liq_rec_frozen_cache"),
    out_dir=Sys.getenv("LIQ_OUT_DIR", paste0("out_liq_rec_revision_v4_6_0_", mode)),
    install=env_bool("LIQ_INSTALL_MISSING", TRUE), refresh=env_bool("LIQ_REFRESH_DATA", FALSE),
    symbols=unique(syms), from=as.Date("2010-01-01"), to=as.Date("2025-12-31"),
    membership_file=Sys.getenv("LIQ_MEMBERSHIP_FILE", ""),
    asset_metadata_file=Sys.getenv("LIQ_ASSET_METADATA", ""),
    allow_missing_assets=env_bool("LIQ_ALLOW_MISSING_ASSETS", FALSE),
    horizons=c(5L,10L,20L,30L), shock_q=.90, recovery_q=.60, k=3L, max_h=30L,
    min_gap=5L, vol_window=60L, corr_window=60L, corr_min_obs=30L,
    corr_min_assets=3L, winsor=.0025, min_daily_train=100L,
    regime_source="market_loo", regime_quantiles=c(1/3,2/3),
    index_variant="equal", save_large_objects=FALSE, strict_inner=TRUE, eta_brier=6,
    context_file=Sys.getenv("LIQ_CONTEXT_FILE",""), min_train=if(small) 60L else 150L,
    min_cal=40L, min_guard=40L, min_class=5L,
    lambda_grid=10^seq(-.5,-4,length.out=if(small) 4L else 10L),
    inner_fractions=if(small) c(.60,.80) else c(.45,.65,.80),
    alpha_logit=.25, alpha_hazard=0, rank_mix_grid=c(.25,.5,.75),
    boot_reps=as.integer(Sys.getenv("LIQ_BOOT_REPS", if(small) "39" else "1999")),
    boot_robust_reps=if(small) 19L else 499L, block_length=45L,
    block_grid=c(30L,45L,60L), cost_ratios=c(1,2,5),
    run_sensitivity=env_bool("LIQ_RUN_SENSITIVITY", TRUE),
    run_rolling=env_bool("LIQ_RUN_ROLLING", TRUE),
    run_simulation=env_bool("LIQ_RUN_SIMULATION", TRUE),
    run_ablations=env_bool("LIQ_RUN_ABLATIONS", TRUE),
    run_panel_checks=env_bool("LIQ_RUN_PANEL_CHECKS", TRUE),
    simulation_reps=as.integer(Sys.getenv("LIQ_SIM_REPS", if(small) "2" else "100")),
    simulation_days=900L, simulation_assets=6L,
    simulation_scenarios=if(small) c("signal","no_regime") else
      c("signal","no_regime","prevalence_shift","regime_reversal","non_PH","strong_dependence"),
    fold=data.frame(role=c("TRAIN","CAL_FIT","GUARD","TEST"),
      from=as.Date(c("2011-01-01","2020-01-01","2022-01-01","2024-02-02")),
      to=as.Date(c("2019-12-31","2021-12-31","2023-12-31","2025-12-31"))),
    inference_scope="marginal future-origin risk, conditional on fitted models and selected asset panel; stationary influence-FCLT for SN; bootstrap coverage diagnostic limitations retained",
    historical_test_seen=TRUE, protocol_status="Expanded convenience roster declared after original TEST inspection; all historical evaluation is re-analysis, not preregistration")
}

liq_packages <- function(cfg) {
  pk <- c("data.table","survival","glmnet")
  if (cfg$data_mode=="yahoo") pk <- c(pk,"quantmod","zoo")
  missing <- pk[!vapply(pk, requireNamespace, logical(1), quietly=TRUE)]
  if(length(missing) && cfg$install)
    utils::install.packages(missing, repos="https://cloud.r-project.org", dependencies=NA)
  missing <- pk[!vapply(pk, requireNamespace, logical(1), quietly=TRUE)]
  if(length(missing)) stop("Missing R packages: ",paste(missing,collapse=", "))
  suppressPackageStartupMessages(library(data.table))
  data.table::setDTthreads(cfg$dt_threads)
  invisible(TRUE)
}

liq_log <- function(...) {
  line<-paste(format(Sys.time(), "%Y-%m-%d %H:%M:%S"),"|",paste(...,collapse=" "))
  cat(line,"\n")
  path<-getOption("liq.log.file","")
  if(nzchar(path))cat(line,"\n",file=path,append=TRUE)
  invisible(line)
}
liq_clip <- function(p) pmin(pmax(p,1e-6),1-1e-6)
liq_mean <- function(x) if(any(is.finite(x))) mean(x[is.finite(x)]) else NA_real_
liq_dt <- function(x) data.table::as.data.table(data.table::copy(x))
liq_bind <- function(x) data.table::rbindlist(x,fill=TRUE,use.names=TRUE)
liq_hash_file <- function(path) {
  if(requireNamespace("digest",quietly=TRUE)) return(paste0("sha256:",digest::digest(file=path,algo="sha256")))
  paste0("md5:",unname(tools::md5sum(path)))
}
liq_hash <- function(x) {
  f<-tempfile();on.exit(unlink(f));saveRDS(x,f,version=3);liq_hash_file(f)
}
liq_assert <- function(ok, msg) if(!isTRUE(ok)) stop(msg,call.=FALSE)
liq_need <- function(ok,msg) if(!isTRUE(ok))stop(structure(list(message=msg,call=NULL),
  class=c("liq_insufficient_sample","error","condition")))
liq_dir <- function(p) { dir.create(p,recursive=TRUE,showWarnings=FALSE); p }
liq_write_csv <- function(x,path) {
  # Preserve binary64 scores on reload: 15-digit CSV output can create AUC ties.
  d<-liq_dt(x)
  for(nm in names(d)) {
    z<-d[[nm]]
    if(is.double(z) && !inherits(z,c("Date","POSIXt","difftime","integer64"))) {
      value<-sprintf("%.17g",z);value[is.na(z)]<-NA_character_
      data.table::set(d,j=nm,value=value)
    }
  }
  data.table::fwrite(d,path,na="NA")
  invisible(path)
}
liq_save <- function(x, name, out) {
  p <- file.path(liq_dir(file.path(out,"tables")), paste0(name,".csv"))
  liq_write_csv(x,p)
  invisible(p)
}
liq_roll <- function(x,n,fun=mean,min_obs=n) {
  fm<-names(formals(data.table::frollapply))
  args<-list(FUN=function(z)
    if(sum(is.finite(z))>=min_obs)fun(z[is.finite(z)])else NA_real_,fill=NA_real_,align="right")
  args[[if("X"%in%fm)"X"else"x"]]<-as.numeric(x)
  if("simplify"%in%fm)args$simplify<-unlist
  argument<-if("N"%in%fm)"N"else"n"
  args[[argument]]<-as.integer(n)
  as.numeric(do.call(data.table::frollapply,args))
}

liq_ecdf <- function(ref,x) {
  ref <- sort(ref[is.finite(ref)])
  if(!length(ref)) return(rep(NA_real_,length(x)))
  ans <- findInterval(x,ref)/length(ref); ans[!is.finite(x)] <- NA_real_; ans
}
liq_pava <- function(y,w=rep(1,length(y))) {
  n <- length(y); if(n<2L) return(y)
  val <- wt <- numeric(n); left <- right <- integer(n); k <- 0L
  for(i in seq_len(n)) {
    k <- k+1L; val[k] <- y[i]; wt[k] <- w[i]; left[k] <- right[k] <- i
    while(k>1L && val[k-1L]>val[k]) {
      val[k-1L] <- (wt[k-1L]*val[k-1L]+wt[k]*val[k])/(wt[k-1L]+wt[k])
      wt[k-1L] <- wt[k-1L]+wt[k]; right[k-1L] <- right[k]; k <- k-1L
    }
  }
  ans <- numeric(n); for(j in seq_len(k)) ans[left[j]:right[j]] <- val[j]; ans
}
liq_cdf <- function(p) {
  p <- as.matrix(p); if(!nrow(p)) return(p)
  ans <- t(vapply(seq_len(nrow(p)),function(i) liq_pava(liq_clip(p[i,])),numeric(ncol(p))))
  dimnames(ans) <- dimnames(p); ans
}
liq_truth <- function(e,h) {
  y <- as.integer(e$status==1L & e$duration<=h)
  full_followup <- e$followup>=h
  known <- (e$status==1L & e$duration<=h) | full_followup
  y[!known]<-NA_integer_
  list(y=y,known=known,full_followup=full_followup)
}
liq_auc <- function(y,s,w=rep(1,length(y))) {
  ok <- is.finite(y)&is.finite(s)&is.finite(w)&w>0
  if(!any(ok)) return(NA_real_)
  d <- data.table(y=y[ok],s=s[ok],w=w[ok])
  a <- d[,.(a=sum(w*(y==1)),b=sum(w*(y==0))),by=s][order(s)]
  if(sum(a$a)<=0 || sum(a$b)<=0) return(NA_real_)
  sum(a$a*(cumsum(a$b)-a$b+.5*a$b))/(sum(a$a)*sum(a$b))
}
liq_calibration <- function(y,p,w=rep(1,length(y))) {
  ans <- c(CITL=NA_real_,cal_intercept=NA_real_,cal_slope=NA_real_)
  ok <- is.finite(y)&is.finite(p)&is.finite(w)&w>0
  y<-y[ok]; p<-p[ok]; w<-w[ok]
  if(length(y)<20L || sum(w*y)<5 || sum(w*(1-y))<5) return(ans)
  z <- qlogis(liq_clip(p))
  f0 <- suppressWarnings(tryCatch(stats::glm.fit(matrix(1,length(y),1),y,weights=w,
           offset=z,family=stats::binomial()),error=function(e) NULL))
  if(!is.null(f0) && isTRUE(f0$converged) && all(is.finite(f0$coefficients))) ans[1]<-f0$coefficients[1]
  if(stats::sd(z)<1e-8) return(ans)
  f1 <- suppressWarnings(tryCatch(stats::glm.fit(cbind(1,z),y,weights=w,
            family=stats::binomial()),error=function(e) NULL))
  if(!is.null(f1) && isTRUE(f1$converged) && all(is.finite(f1$coefficients)) &&
     max(abs(f1$coefficients))<100) ans[2:3]<-f1$coefficients
  ans
}

# -------------------- Frozen inputs and membership ---------------------------
liq_synthetic_raw <- function(cfg) {
  set.seed(cfg$seed)
  days <- seq(cfg$from,cfg$to,by="day")
  days <- days[as.POSIXlt(days)$wday %in% 1:5]
  n <- length(days); f <- as.numeric(stats::arima.sim(list(ar=.86),n=n))
  state <- as.numeric(f>1); vix <- pmax(9,18+4*f+stats::rnorm(n))
  out <- lapply(seq_along(cfg$symbols),function(j) {
    rr <- (.007+.002*state)*stats::rnorm(n)+.003*f
    cp <- (40+10*j)*exp(cumsum(rr))
    op <- cp*exp(-rr*.55+stats::rnorm(n,0,.002))
    span <- abs(stats::rnorm(n,0,.008))+.006+.005*state
    vv <- exp(15+.2*j-.35*f+stats::rnorm(n,0,.3))
    data.table(date=days,asset=cfg$symbols[j],open=op,high=pmax(cp,op)*(1+span),
      low=pmin(cp,op)/(1+span),close=cp,adjusted=cp,volume=round(vv))
  })
  out[[length(out)+1L]]<-data.table(date=days,asset="^VIX",open=vix,high=vix,low=vix,
                                  close=vix,adjusted=vix,volume=NA_real_)
  liq_bind(out)
}
liq_get_data <- function(cfg) {
  liq_dir(cfg$cache_dir)
  if(nzchar(cfg$membership_file)) {
    mem <- data.table::fread(cfg$membership_file)
    liq_assert(all(c("asset","start_date","end_date","source") %in% names(mem)),
               "Membership CSV needs asset,start_date,end_date,source.")
    cfg$symbols <- sort(unique(mem$asset))
  }
  if(cfg$data_mode=="synthetic") {
    raw<-liq_synthetic_raw(cfg)
    manifest<-data.table(asset=unique(raw$asset),source="SYNTHETIC_TEST_DATA",
                         retrieved_utc=format(Sys.time(),tz="UTC",usetz=TRUE))
  } else if(cfg$data_mode=="csv") {
    liq_assert(file.exists(cfg$input_csv),"LIQ_INPUT_CSV does not exist.")
    integrity<-liq_verify_snapshot(cfg)
    if(nrow(integrity))liq_save(integrity,"D12_snapshot_integrity",cfg$out_dir)
    raw<-liq_read_ohlcv(cfg$input_csv)
    manifest<-data.table(asset=unique(raw$asset),source=normalizePath(cfg$input_csv),
                         retrieved_utc="provided frozen input; original retrieval date requires source metadata")
    pf<-integrity[artifact=="provenance",checked_file]
    if(length(pf)==1L) {
      manifest<-data.table::fread(pf)
      liq_assert(!anyDuplicated(manifest$asset)&&setequal(manifest$asset,unique(raw$asset)),
        "Source provenance must identify exactly every frozen input series, including ^VIX.")
      counts<-raw[,.N,by=asset]
      liq_assert(all(counts$N==manifest$n_rows[match(counts$asset,manifest$asset)]),
        "Provenance row counts disagree with frozen data.")
      manifest[,`:=`(frozen_input=normalizePath(cfg$input_csv,winslash="/",mustWork=TRUE),
        frozen_input_hash=liq_hash_file(cfg$input_csv),source_record="per-asset provenance bound to snapshot lock")]
    }
  } else if(cfg$data_mode=="yahoo") {
    logs<-list(); raw_list<-list()
    for(a in c(cfg$symbols,"^VIX")) {
      fn<-file.path(cfg$cache_dir,paste0(gsub("[^A-Za-z0-9]","_",a),".csv"))
      mf<-paste0(fn,".meta.rds")
      cached<-file.exists(fn)&&!cfg$refresh
      if(!cached) {
        liq_log("Download",a)
        x<-tryCatch(quantmod::getSymbols(a,src="yahoo",from=cfg$from,to=cfg$to+1,
                                       auto.assign=FALSE),error=function(e)e)
        if(inherits(x,"error")) {
          logs[[a]]<-data.table(asset=a,source="Yahoo Finance",status="failed",message=conditionMessage(x))
          next
        }
        ad<-tryCatch(as.numeric(quantmod::Ad(x)),error=function(e)rep(NA_real_,NROW(x)))
        z<-data.table(date=as.Date(zoo::index(x)),asset=a,open=as.numeric(quantmod::Op(x)),
          high=as.numeric(quantmod::Hi(x)),low=as.numeric(quantmod::Lo(x)),
          close=as.numeric(quantmod::Cl(x)),adjusted=ad,volume=as.numeric(quantmod::Vo(x)))
        liq_write_csv(z,fn)
        saveRDS(list(retrieved_utc=format(Sys.time(),tz="UTC",usetz=TRUE),package="quantmod",
                     package_version=as.character(utils::packageVersion("quantmod")),
                     price_adjustment="provider Adjusted column; OHLC and volume retained as returned",
                     ticker=a),mf)
      }
      z<-liq_read_ohlcv(fn); raw_list[[a]]<-z
      md<-if(file.exists(mf))readRDS(mf) else list(retrieved_utc="unknown legacy cache")
      logs[[a]]<-data.table(asset=a,source="Yahoo Finance via quantmod",status="ok",
        cached=cached,retrieved_utc=md$retrieved_utc,cache_file=normalizePath(fn),
        content_hash=liq_hash_file(fn))
    }
    raw<-liq_bind(raw_list);manifest<-liq_bind(logs)
  } else stop("LIQ_DATA_MODE must be yahoo, csv or synthetic.")
  liq_save(manifest,"D02_data_manifest",cfg$out_dir)
  req<-c("date","asset","open","high","low","close","adjusted","volume")
  liq_assert(all(req%in%names(raw)),paste("Input columns required:",paste(req,collapse=",")))
  raw<-liq_numeric_schema(raw);raw[,date:=as.Date(date)]
  liq_assert(!anyNA(raw$date),"Invalid or missing input dates.")
  liq_assert(!anyDuplicated(raw[,.(asset,date)]),"Duplicate asset-date observations in input.")
  raw<-raw[date>=cfg$from & date<=cfg$to]
  missing<-setdiff(cfg$symbols,unique(raw$asset))
  if(length(missing)&&!cfg$allow_missing_assets) stop("Missing assets: ",paste(missing,collapse=","))
  cfg$symbols<-intersect(cfg$symbols,unique(raw$asset))
  liq_assert("SPY"%in%raw$asset,"SPY is required as the frozen trading-session calendar.")
  calendar<-sort(unique(raw[asset=="SPY",date]))
  liq_assert(length(calendar)>500,"Too few reference trading sessions.")
  liq_assert(max(calendar)>=cfg$to-7L,"Reference calendar ends before requested period; refresh or supply a complete frozen snapshot.")
  grid<-data.table::CJ(asset=cfg$symbols,sid=seq_along(calendar))
  grid[,date:=calendar[sid]]
  grid<-merge(grid,raw[asset%in%cfg$symbols],by=c("asset","date"),all.x=TRUE,sort=FALSE)
  grid[,member:=TRUE]
  if(nzchar(cfg$membership_file)) {
    mem[,`:=`(start_date=as.Date(start_date),end_date=as.Date(end_date))]
    mem[is.na(end_date),end_date:=max(calendar)]
    grid[,member:=FALSE]
    for(j in seq_len(nrow(mem))) {
      jj<-which(grid$asset==mem$asset[j] & grid$date>=mem$start_date[j] & grid$date<=mem$end_date[j])
      data.table::set(grid,jj,"member",TRUE)
    }
  }
  vix<-raw[asset=="^VIX",.(date,vix=close)]
  grid<-merge(grid,vix,by="date",all.x=TRUE,sort=FALSE)
  if(!"vix"%in%names(grid))grid[,vix:=NA_real_]
  setorder(grid,asset,sid)
  grid[,observed:=is.finite(close)&close>0]
  grid[,valid_price:=observed&is.finite(adjusted)&adjusted>0&is.finite(high)&
         is.finite(low)&high>=low&low>0&high>=close&low<=close]
  grid[,valid_volume:=is.finite(volume)&volume>0]
  inv<-grid[,.(first_observed=if(any(observed))min(date[observed])else as.Date(NA),
     last_observed=if(any(observed))max(date[observed])else as.Date(NA),
     n_rows=.N,n_observed=sum(observed),n_missing=sum(!observed),
     zero_volume=sum(is.finite(volume)&volume==0),invalid_price=sum(observed&!valid_price),
     invalid_volume=sum(observed&!valid_volume),
     adjustment_ratio_changes=sum(abs(diff(log(adjusted/close)))>.01,na.rm=TRUE)),by=asset]
  inv[,`:=`(verified_inception_date=as.Date(NA),
     selection_status=if(nzchar(cfg$membership_file))"provided point-in-time membership; verify source" else
       "fixed convenience panel; historical ex-ante selection not established",
     volume_adjustment_status="provider-returned volume; split convention requires source verification")]
  if(nzchar(cfg$asset_metadata_file))inv<-merge(inv,data.table::fread(cfg$asset_metadata_file),by="asset",all.x=TRUE)
  list(panel=grid,calendar=calendar,raw=raw,manifest=manifest,inventory=inv,cfg=cfg)
}

# -------------------- Causal daily transformations ---------------------------
liq_raw_features <- function(panel,cfg) {
  p<-liq_numeric_schema(panel);setorder(p,asset,sid)
  p[,ret:={
    previous<-data.table::shift(adjusted);ans<-rep(NA_real_,.N)
    good<-valid_price & member & is.finite(previous) & previous>0
    ans[good]<-log(adjusted[good])-log(previous[good]);ans[!is.finite(ans)]<-NA_real_;ans
  },by=asset]
  p[,`:=`(abs_ret=abs(ret),rv=ret^2,
     range_pct=ifelse(valid_price,(high-low)/close,NA_real_),
     log_volume=ifelse(valid_volume,log(volume),NA_real_),
     log_dvol=ifelse(valid_volume&observed,log(close)+log(volume),NA_real_))]
  p[,vol_baseline:=data.table::shift(liq_roll(log_volume,cfg$vol_window,median)),by=asset]
  p[,volume_shock:=log_volume-vol_baseline]
  p[,pressure:=range_pct*pmax(-volume_shock,0)]
  p[,relative_log_dvol:=log_dvol-data.table::shift(liq_roll(log_dvol,60L,median)),by=asset]
  p[,absret5:=liq_roll(abs_ret,5L),by=asset]
  p[,rv5:=liq_roll(rv,5L),by=asset]
  p[,amihud:=ifelse(valid_volume&observed,abs_ret/(close*volume)*1e6,NA_real_)]
  p[,vix_lag1:=data.table::shift(vix),by=asset]
  p[,vix_change5:=data.table::shift(vix-data.table::shift(vix,5L)),by=asset]
  p[,vix_missing:=as.numeric(!is.finite(vix_lag1))]
  # Two-day Corwin-Schultz range-based spread proxy; mechanically shares OHLC.
  # Daily high/low are aligned with the provider adjustment ratio across days.
  p[,`:=`(adj_high=high*adjusted/close,adj_low=low*adjusted/close)]
  p[,cs_beta:=log(adj_high/adj_low)^2+data.table::shift(log(adj_high/adj_low)^2),by=asset]
  p[,cs_gamma:=log(pmax(adj_high,data.table::shift(adj_high))/
                         pmin(adj_low,data.table::shift(adj_low)))^2,by=asset]
  p[,cs_alpha:=(sqrt(2*cs_beta)-sqrt(cs_beta))/(3-2*sqrt(2))-
                sqrt(cs_gamma/(3-2*sqrt(2)))]
  p[,cs_spread:=pmax(0,2*tanh(cs_alpha/2))]
  p[,cs_spread:=ifelse(valid_price & data.table::shift(valid_price,fill=FALSE),
                      cs_spread,NA_real_),by=asset]
  p[!is.finite(cs_spread),cs_spread:=NA_real_]
  p[,c("adj_high","adj_low","cs_beta","cs_gamma","cs_alpha"):=NULL]
  p
}

liq_index <- function(raw_features,cfg,fold,variant=cfg$index_variant) {
  p<-liq_dt(raw_features)
  train_end<-fold$to[fold$role=="TRAIN"]
  cols<-c("abs_ret","range_pct","log_dvol","volume_shock","pressure")
  if(variant=="relative_dvol")p[,log_dvol:=relative_log_dvol]
  signs<-c(1,1,-1,-1,1); params<-list(); wf<-list()
  for(a in unique(p$asset)) {
    ii<-which(p$asset==a);tr<-ii[p$date[ii]>=fold$from[fold$role=="TRAIN"] & p$date[ii]<=train_end & p$member[ii]]
    if(sum(p$valid_price[tr]&p$valid_volume[tr])<cfg$min_daily_train)next
    for(j in seq_along(cols)) {
      ref<-p[[cols[j]]][tr];ref<-ref[is.finite(ref)]
      if(length(ref)<cfg$min_daily_train)next
      q<-as.numeric(quantile(ref,c(cfg$winsor,1-cfg$winsor),type=7))
      rr<-pmin(pmax(ref,q[1]),q[2]);mu<-mean(rr);ss<-sd(rr)
      if(!is.finite(ss)||ss<1e-12)ss<-1
      values<-p[[cols[j]]][ii];values[!is.finite(values)]<-NA_real_
      z<-signs[j]*(pmin(pmax(values,q[1]),q[2])-mu)/ss
      data.table::set(p,ii,paste0("z_lsi",j),z)
      params[[length(params)+1L]]<-data.table(asset=a,component=cols[j],sign=signs[j],
           lower=q[1],upper=q[2],mean=mu,sd=ss,fit_end=train_end)
    }
  }
  zc<-paste0("z_lsi",1:5)
  for(z in setdiff(zc,names(p)))p[,(z):=NA_real_]
  w<-rep(1/5,5)
  if(grepl("^omit_[1-5]$",variant)) {w[as.integer(sub("omit_","",variant))]<-0;w<-w/sum(w)}
  if(variant=="volume_only")w<-c(0,0,.5,.5,0)
  if(variant=="redundancy_weighted") {
    zz<-as.matrix(p[date>=fold$from[fold$role=="TRAIN"] & date<=train_end & member==TRUE,..zc])
    cc<-suppressWarnings(stats::cor(zz,use="pairwise.complete.obs"));cc[!is.finite(cc)]<-0
    w<-1/pmax(rowSums(abs(cc)),1);w<-w/sum(w)
  }
  p[,lsi:=as.numeric(as.matrix(.SD)%*%w[w>0]),.SDcols=zc[w>0]]
  # A component is never silently dropped from a daily index.
  p[member==FALSE,lsi:=NA_real_]
  p[,`:=`(lsi_lag1=data.table::shift(lsi),lsi_mom5=lsi-data.table::shift(lsi,5L)),by=asset]
  market<-p[,.(market_full=liq_mean(lsi),market_sum=sum(lsi,na.rm=TRUE),
                market_n=sum(is.finite(lsi)),volume_breadth=liq_mean(ifelse(member & is.finite(lsi),as.numeric(volume_shock < -0.5),NA_real_))),by=.(sid,date)]
  wide<-data.table::dcast(p,sid~asset,value.var="ret")
  rr<-as.matrix(wide[,-1,with=FALSE]);ac<-rep(NA_real_,nrow(rr))
  for(t in seq_len(nrow(rr))) {
    if(t<=cfg$corr_window)next
    xx<-rr[(t-cfg$corr_window):(t-1L),,drop=FALSE]
    good<-colSums(is.finite(xx))>=cfg$corr_min_obs
    if(sum(good)<cfg$corr_min_assets)next
    xx<-xx[,good,drop=FALSE];cnt<-crossprod(is.finite(xx)*1)
    cc<-suppressWarnings(stats::cor(xx,use="pairwise.complete.obs"))
    cc[cnt<cfg$corr_min_obs]<-NA_real_;ac[t]<-liq_mean(cc[upper.tri(cc)])
  }
  market[,avg_corr_lag1:=ac[match(sid,wide$sid)]]
  setorder(market,sid)
  market[,`:=`(market_full_lag1=data.table::shift(market_full),
               volume_breadth_lag1=data.table::shift(volume_breadth))]
  p<-merge(p,market,by=c("sid","date"),all.x=TRUE,sort=FALSE)
  p[,market_loo:=ifelse(is.finite(lsi)&market_n>=cfg$corr_min_assets,
                        (market_sum-lsi)/(market_n-1L),NA_real_)]
  setorder(p,asset,sid)
  p[,market_loo_lag1:=data.table::shift(market_loo),by=asset]
  p[,market_trend5:=data.table::shift(market_loo-data.table::shift(market_loo,5L)),by=asset]
  for(a in unique(p$asset)) {
    ii<-which(p$asset==a);tr<-ii[p$date[ii]>=fold$from[fold$role=="TRAIN"] & p$date[ii]<=train_end&p$member[ii]]
    data.table::set(p,ii,"shock_severity_pct",liq_ecdf(p$lsi[tr],p$lsi[ii]))
    data.table::set(p,ii,"market_percentile",liq_ecdf(p$market_loo[tr],p$market_loo[ii]))
  }
  list(panel=p,parameters=liq_bind(params),weights=data.table(component=cols,weight=w,variant=variant))
}

liq_feature_names <- function() c("lsi","lsi_lag1","lsi_mom5","shock_severity_pct",
  "abs_ret","absret5","rv5","range_pct","volume_shock","pressure","log_dvol",
  "market_loo","market_loo_lag1","market_full","market_trend5","market_percentile",
  "shock_cluster_share","shock_cluster_share_lag1","volume_breadth_lag1",
  "avg_corr_lag1","vix_lag1","vix_change5","vix_missing","is_stock","is_sector")

liq_events <- function(index_panel,calendar,cfg,fold,shock_q=cfg$shock_q,
                       recovery_q=cfg$recovery_q,k=cfg$k,max_h=cfg$max_h,
                       nonoverlap=FALSE,regime_source=cfg$regime_source) {
  p<-liq_dt(index_panel);tr_end<-fold$to[fold$role=="TRAIN"]
  thr<-p[date>=fold$from[fold$role=="TRAIN"] & date<=tr_end & member==TRUE & is.finite(lsi),
         .(shock_thr=as.numeric(quantile(lsi,shock_q)),rec_thr=as.numeric(quantile(lsi,recovery_q))),by=asset]
  p<-merge(p,thr,by="asset",all.x=TRUE,sort=FALSE)
  p[,exceed:=as.numeric(is.finite(lsi)&is.finite(shock_thr)&lsi>shock_thr&member)]
  br<-p[,.(shock_cluster_share=if(sum(is.finite(lsi)&member)>0)
      sum(exceed)/sum(is.finite(lsi)&member) else NA_real_),by=sid]
  p<-merge(p,br,by="sid",all.x=TRUE,sort=FALSE);setorder(p,asset,sid)
  p[,shock_cluster_share_lag1:=data.table::shift(shock_cluster_share),by=asset]
  # Explicit instrument definitions cover every declared expansion symbol.
  # Broad-market and style ETFs are not mislabeled as sector funds.
  p[,`:=`(is_stock=as.numeric(asset%in%cfg$equity_symbols),
           is_sector=as.numeric(asset%in%cfg$sector_etf_symbols))]
  out<-list();counter<-0L
  for(a in unique(p$asset)) {
    d<-p[asset==a];setorder(d,sid);last<- -Inf
    starts<-which(d$exceed==1)
    for(ii in starts) {
      if(d$sid[ii]<=last+if(nonoverlap)max_h else cfg$min_gap)next
      last<-d$sid[ii];counter<-counter+1L
      ix<-ii+seq_len(max_h);ix<-ix[ix<=nrow(d)]
      follow<-0L;confirmed<-NA_integer_;run<-0L
      for(jj in ix) {
        if(d$sid[jj]!=d$sid[ii]+follow+1L || !is.finite(d$lsi[jj]) || !d$member[jj])break
        follow<-follow+1L
        run<-if(d$lsi[jj]<=d$rec_thr[ii])run+1L else 0L
        if(is.na(confirmed)&&run>=k)confirmed<-follow
      }
      status<-as.integer(is.finite(confirmed))
      duration<-if(status==1L)confirmed else follow
      planned_sid<-d$sid[ii]+max_h
      planned_end<-if(planned_sid<=length(calendar))calendar[planned_sid] else as.Date(NA)
      event<-d[ii,unique(c("asset","date","sid",liq_feature_names(),
                     "market_loo_lag1","vix_lag1")),with=FALSE]
      data.table::setnames(event,"date","shock_date")
      event[,`:=`(event_id=paste(a,format(shock_date,"%Y%m%d"),sep="_"),
        duration=as.integer(duration),status=status,followup=as.integer(follow),
        recovery_start_day=if(status==1L)confirmed-k+1L else NA_integer_,
        confirmation_day=if(status==1L)confirmed else NA_integer_,
        planned_end=planned_end,
        observed_end=calendar[d$sid[ii]+follow],
        censor_reason=if(status==1L)"recovered" else if(follow>=max_h)"Hmax" else "data_end_or_gap",
        forecast_timestamp="after shock-session OHLCV become available; next-session action",
        role="OUTSIDE",analysis_eligible=FALSE,exclusion="outside_protocol")]
      for(rr in seq_len(nrow(fold))) if(event$shock_date>=fold$from[rr]&&event$shock_date<=fold$to[rr]) {
        event[,role:=fold$role[rr]]
        eligible<-!is.na(planned_end)&&planned_end<=fold$to[rr]&&follow>=max_h
        event[,`:=`(analysis_eligible=eligible,exclusion=if(eligible)"included" else
          if(is.na(planned_end)||planned_end>fold$to[rr])"window_outside_role" else "early_followup_loss")]
      }
      out[[counter]]<-event
    }
  }
  ev<-liq_bind(out)
  liq_need(nrow(ev)>0L,"No shock events under this design.")
  setorder(ev,shock_date,asset)
  vals<-ev[role=="TRAIN" & analysis_eligible==TRUE,get(regime_source)]
  vals<-vals[is.finite(vals)]
  liq_need(length(vals)>=10L,"Insufficient TRAIN regime observations.")
  cuts<-as.numeric(quantile(vals,cfg$regime_quantiles,type=7))
  ev[,regime:=ifelse(!is.finite(get(regime_source)),"Missing",
         ifelse(get(regime_source)<=cuts[1],"Low",ifelse(get(regime_source)<=cuts[2],"Normal","High")))]
  for(h in cfg$horizons) {
    y<-liq_truth(ev,h);ev[,(paste0("y",h)):=y$y];ev[,(paste0("known",h)):=y$known]
    ev[,(paste0("full_followup",h)):=y$full_followup]
  }
  list(events=ev,thresholds=thr,regime_cuts=data.table(source=regime_source,q=cfg$regime_quantiles,cut=cuts),
       context=p)
}

# -------------------- Models; all tuning remains inside TRAIN ----------------
liq_prep <- function(d,cols=liq_feature_names()) {
  out<-list();keep<-character()
  for(cc in cols) {
    x<-d[[cc]];v<-x[is.finite(x)];md<-if(length(v))median(v)else 0
    x[!is.finite(x)]<-md;ss<-sd(x);mu<-mean(x)
    if(is.finite(ss)&&ss>1e-10) {keep<-c(keep,cc);out[[cc]]<-c(median=md,mean=mu,sd=ss)}
  }
  list(columns=keep,parameters=out)
}
liq_x <- function(d,prep) {
  if(!length(prep$columns))return(matrix(0,nrow(d),2,dimnames=list(NULL,c("pad1","pad2"))))
  x<-vapply(prep$columns,function(cc) {
    z<-d[[cc]];pa<-prep$parameters[[cc]];z[!is.finite(z)]<-pa["median"]
    (z-pa["mean"])/pa["sd"]
  },numeric(nrow(d)))
  x<-matrix(x,nrow=nrow(d),dimnames=list(NULL,prep$columns))
  if(ncol(x)==1L)x<-cbind(x,padding=0)
  x
}
liq_inner_splits <- function(e,cfg) {
  dd<-sort(unique(e$shock_date));n<-length(dd);out<-list()
  ix<-unique(pmax(2L,pmin(n-1L,floor(cfg$inner_fractions*n))))
  for(j in seq_along(ix)) {
    start<-dd[ix[j]];end<-if(j<length(ix))dd[ix[j+1L]-1L]else max(dd)
    tr<-which(e$shock_date<start & e$planned_end<start)
    va<-which(e$shock_date>=start & e$shock_date<=end & e$planned_end<=end)
    if(length(tr)>=cfg$min_train && length(va)>=20L)
      out[[length(out)+1L]]<-list(train=tr,valid=va,start=start,end=end)
  }
  out
}
liq_hazard_design <- function(e,prep,H,training=TRUE) {
  lens<-if(training)pmin(e$duration,H)else rep(H,nrow(e))
  lens<-pmax(0L,as.integer(lens));ii<-rep(seq_len(nrow(e)),lens)
  day<-unlist(lapply(lens,seq_len),use.names=FALSE)
  xx<-liq_x(e,prep)[ii,,drop=FALSE]
  tb<-splines::ns(day,knots=c(H/3,2*H/3),Boundary.knots=c(1,H),intercept=FALSE)
  colnames(tb)<-paste0("hazard_time",seq_len(ncol(tb)))
  x<-cbind(xx,tb)
  y<-as.integer(e$status[ii]==1L & e$duration[ii]==day)
  list(x=x,y=y,event_row=ii,day=day)
}
liq_nested_inner_v450 <- function(raw_features,calendar,cfg,fold,variant,nonoverlap,regime_source) {
  days<-calendar[calendar>=fold$from[fold$role=="TRAIN"] & calendar<=fold$to[fold$role=="TRAIN"]]
  liq_need(length(days)>cfg$min_daily_train+cfg$max_h,"Insufficient calendar for nested daily validation.")
  cuts<-unique(pmax(2L,pmin(length(days)-1L,floor(cfg$inner_fractions*length(days)))))
  splits<-parameters<-thresholds<-audit<-list()
  for(j in seq_along(cuts)) {
    start<-days[cuts[j]];end<-if(j<length(cuts))days[cuts[j+1L]-1L]else tail(days,1)
    inner_fold<-data.frame(role=c("TRAIN","VALID"),
      from=c(days[1],start),to=c(days[cuts[j]-1L],end))
    prefix<-raw_features[date<=end]
    value<-tryCatch({
      ix<-liq_index(prefix,cfg,inner_fold,variant)
      pr<-liq_events(ix$panel,calendar,cfg,inner_fold,nonoverlap=nonoverlap,regime_source=regime_source)
      tr<-pr$events[role=="TRAIN" & analysis_eligible==TRUE]
      va<-pr$events[role=="VALID" & analysis_eligible==TRUE]
      liq_need(nrow(tr)>=cfg$min_train && nrow(va)>=20L,
        paste("Insufficient nested events:",nrow(tr),"TRAIN;",nrow(va),"VALID"))
      liq_assert(all(tr$planned_end<start) && all(va$planned_end<=end),"Nested labels cross their role boundaries.")
      if(nrow(ix$parameters))liq_assert(all(ix$parameters$fit_end<start),"Nested daily fit uses validation dates.")
      list(train=tr,valid=va,parameters=ix$parameters,thresholds=pr$thresholds,
        transform_fit_end=inner_fold$to[1],
        preprocessing="nested raw daily prefix: TRAIN-only LSI/winsor/ECDF/event and regime thresholds; inner imputation/scaling")
    },liq_insufficient_sample=function(e)e)
    if(inherits(value,"liq_insufficient_sample")) {
      audit[[length(audit)+1L]]<-data.table(inner_fold=j,train_start=inner_fold$from[1],
        transform_fit_end=inner_fold$to[1],validation_start=start,validation_end=end,
        status="insufficient_sample",reason=conditionMessage(value),n_train=NA_integer_,n_valid=NA_integer_)
      next
    }
    audit[[length(audit)+1L]]<-data.table(inner_fold=j,train_start=inner_fold$from[1],
      transform_fit_end=value$transform_fit_end,validation_start=start,validation_end=end,
      status="available",reason="",n_train=nrow(value$train),n_valid=nrow(value$valid))
    pp<-liq_dt(value$parameters);pp[,inner_fold:=j];parameters[[length(parameters)+1L]]<-pp
    tt<-liq_dt(value$thresholds);tt[,`:=`(inner_fold=j,fit_end=value$transform_fit_end)]
    thresholds[[length(thresholds)+1L]]<-tt
    value$parameters<-value$thresholds<-NULL
    splits[[length(splits)+1L]]<-value
  }
  list(splits=splits,audit=liq_bind(audit),parameters=liq_bind(parameters),thresholds=liq_bind(thresholds))
}

liq_tune <- function(e,cfg,h=NULL,hazard=FALSE,inner_bundle=NULL) {
  splits<-if(is.null(inner_bundle))lapply(liq_inner_splits(e,cfg),function(ss)
    list(train=e[ss$train],valid=e[ss$valid],transform_fit_end=as.Date(NA),
      preprocessing="fixed event-DGP covariates; inner-TRAIN imputation/scaling; mature labels"))else inner_bundle$splits
  loss<-list();audit<-list()
  for(j in seq_along(splits)) {
    ss<-splits[[j]];tr<-ss$train;va<-ss$valid;pp<-liq_prep(tr)
    if(hazard) {
      a<-liq_hazard_design(tr,pp,cfg$max_h,TRUE)
      b<-liq_hazard_design(va,pp,cfg$max_h,TRUE)
      x<-a$x;y<-a$y;vx<-b$x;vy<-b$y
    } else {
      a<-liq_truth(tr,h);b<-liq_truth(va,h)
      x<-liq_x(tr,pp)[a$known,,drop=FALSE];y<-a$y[a$known]
      vx<-liq_x(va,pp)[b$known,,drop=FALSE];vy<-b$y[b$known]
    }
    if((!hazard&&!length(pp$columns))||length(unique(y))<2L||min(table(y))<8L||length(vy)<10L||nrow(x)<40L)next
    fit<-liq_glmnet_v480(x,y,family="binomial",alpha=if(hazard)cfg$alpha_hazard else cfg$alpha_logit,
                        lambda=cfg$lambda_grid,standardize=FALSE,intercept=TRUE)
    pr<-as.matrix(stats::predict(fit,newx=vx,s=cfg$lambda_grid,type="response"))
    pr<-liq_clip(pr)
    ll<-colMeans(-vy*log(pr)-(1-vy)*log(1-pr))
    loss[[length(loss)+1L]]<-ll
    audit[[length(audit)+1L]]<-data.table(inner_fold=j,n_train=nrow(tr),n_valid=nrow(va),
      last_training_label=max(tr$planned_end),validation_start=min(va$shock_date),
      validation_end=max(va$shock_date),transform_fit_end=ss$transform_fit_end,preprocessing=ss$preprocessing)
  }
  if(!length(loss)) {
    # A declared fixed penalty; never borrow CAL_FIT, GUARD or TEST labels.
    return(list(lambda=.03,table=data.table(lambda=.03,mean_loss=NA_real_,se=NA_real_,
      selection="fixed_lambda_insufficient_inner_folds"),audit=liq_bind(audit)))
  }
  mm<-do.call(rbind,loss);mu<-colMeans(mm)
  se<-if(nrow(mm)>1L)apply(mm,2,sd)/sqrt(nrow(mm))else rep(0,ncol(mm))
  best<-which.min(mu);eligible<-which(mu<=mu[best]+se[best])
  chosen<-eligible[which.max(cfg$lambda_grid[eligible])]
  list(lambda=cfg$lambda_grid[chosen],
    table=data.table(lambda=cfg$lambda_grid,mean_loss=mu,se=se,selected=seq_along(mu)==chosen,
                     selection="forward_validation_one_SE"),audit=liq_bind(audit))
}
liq_fit_logit <- function(e,cfg,h,inner_bundle=NULL) {
  prep<-liq_prep(e);tt<-liq_truth(e,h);y<-tt$y[tt$known]
  if(!length(prep$columns) || length(unique(y))<2L || min(table(y))<8L)return(list(type="constant",p=(sum(y)+.5)/(length(y)+1),prep=prep))
  tune<-liq_tune(e,cfg,h,inner_bundle=inner_bundle)
  fit<-liq_glmnet_v480(liq_x(e,prep)[tt$known,,drop=FALSE],y,family="binomial",
        alpha=cfg$alpha_logit,lambda=sort(unique(c(cfg$lambda_grid,tune$lambda)),decreasing=TRUE),
        standardize=FALSE,intercept=TRUE)
  list(type="glmnet",fit=fit,lambda=tune$lambda,prep=prep,tuning=tune)
}
liq_predict_logit <- function(fit,e) {
  if(fit$type=="constant")return(rep(fit$p,nrow(e)))
  as.numeric(stats::predict(fit$fit,newx=liq_x(e,fit$prep),s=fit$lambda,type="response"))
}
liq_fit_hazard <- function(e,cfg,inner_bundle=NULL) {
  prep<-liq_prep(e);hz<-liq_hazard_design(e,prep,cfg$max_h,TRUE)
  if(length(unique(hz$y))<2L || min(table(hz$y))<8L)return(list(type="constant",p=(sum(hz$y)+.5)/(length(hz$y)+1),prep=prep,H=cfg$max_h))
  tune<-liq_tune(e,cfg,hazard=TRUE,inner_bundle=inner_bundle)
  fit<-liq_glmnet_v480(hz$x,hz$y,family="binomial",alpha=cfg$alpha_hazard,
       lambda=sort(unique(c(cfg$lambda_grid,tune$lambda)),decreasing=TRUE),standardize=FALSE)
  list(type="glmnet",fit=fit,lambda=tune$lambda,prep=prep,H=cfg$max_h,tuning=tune)
}
liq_predict_hazard <- function(fit,e,horizons) {
  if(fit$type=="constant") {
    ans<-outer(rep(1,nrow(e)),1-(1-fit$p)^horizons);colnames(ans)<-horizons;return(ans)
  }
  xx<-liq_hazard_design(e,fit$prep,fit$H,FALSE)
  hz<-as.numeric(stats::predict(fit$fit,newx=xx$x,s=fit$lambda,type="response"))
  hz<-matrix(liq_clip(hz),nrow=nrow(e),ncol=fit$H,byrow=TRUE)
  ans<-vapply(horizons,function(h)1-exp(rowSums(log1p(-hz[,seq_len(h),drop=FALSE]))),numeric(nrow(e)))
  colnames(ans)<-horizons;ans
}
liq_fit_cox <- function(e,cfg) {
  prep<-liq_prep(e);xx<-liq_x(e,prep)
  qrfit<-qr(xx);keep<-if(qrfit$rank)sort(qrfit$pivot[seq_len(qrfit$rank)])else integer()
  if(!length(keep)||sum(e$status)<5L)return(list(type="unavailable",reason="insufficient Cox information"))
  xx<-xx[,keep,drop=FALSE]
  dd<-data.frame(time=e$duration,status=e$status,asset=e$asset,xx,check.names=FALSE)
  f<-stats::as.formula(paste("survival::Surv(time,status) ~",paste(colnames(xx),collapse=" + ")))
  warnings<-character()
  fit<-withCallingHandlers(tryCatch(survival::coxph(f,data=dd,cluster=asset,ties="breslow",
       x=TRUE,y=TRUE,model=TRUE,singular.ok=FALSE,control=survival::coxph.control(iter.max=50)),
       error=function(e)e),warning=function(w){warnings<<-c(warnings,conditionMessage(w));invokeRestart("muffleWarning")})
  if(inherits(fit,"error")||any(!is.finite(stats::coef(fit))))
    return(list(type="unavailable",reason=if(inherits(fit,"error"))conditionMessage(fit)else "non-finite Cox coefficients",warnings=warnings))
  ph<-tryCatch(survival::cox.zph(fit),error=function(e)list(error=conditionMessage(e)))
  list(type="cox",fit=fit,prep=prep,keep=keep,base=survival::basehaz(fit,centered=FALSE),PH=ph,warnings=warnings)
}
liq_predict_cox <- function(fit,e,horizons) {
  xx<-liq_x(e,fit$prep)[,fit$keep,drop=FALSE]
  lp<-as.numeric(xx%*%stats::coef(fit$fit));risk<-exp(pmin(pmax(lp,-35),35))
  bh<-fit$base;ii<-findInterval(horizons,bh$time)
  H0<-ifelse(ii>0,bh$hazard[pmax(ii,1)],0)
  ans<-1-exp(-outer(risk,H0));colnames(ans)<-horizons;ans
}
liq_empirical <- function(train,new,horizons,regime=FALSE) {
  ans<-matrix(NA_real_,nrow(new),length(horizons),dimnames=list(NULL,horizons))
  for(j in seq_along(horizons)) {
    tt<-liq_truth(train,horizons[j]);y<-tt$y
    base<-(sum(y[tt$known])+.5)/(sum(tt$known)+1)
    ans[,j]<-base
    if(regime)for(r in unique(new$regime)) {
      ii<-which(train$regime==r & tt$known)
      ans[new$regime==r,j]<-if(length(ii))(sum(y[ii])+.5)/(length(ii)+1)else base
    }
  }
  ans
}
liq_cal_fit <- function(y,score,cfg) {
  ok<-is.finite(y)&is.finite(score);y<-y[ok];score<-score[ok]
  liq_assert(length(y)>0L,"No CAL_FIT labels for calibration.")
  reason<-if(length(y)<cfg$min_cal)"insufficient_CAL_events"else
    if(min(sum(y==1),sum(y==0))<cfg$min_class)"small_CAL_class"else
      if(uniqueN(score)<2L)"constant_score"else"CAL_FIT_only"
  common<-list(n=length(y),positive=sum(y==1),negative=sum(y==0),unique_scores=uniqueN(score),reason=reason)
  if(reason!="CAL_FIT_only")return(c(list(type="constant",p=(sum(y)+.5)/(length(y)+1)),common))
  nb<-min(10L,max(3L,floor(length(y)/30L)))
  br<-unique(as.numeric(quantile(score,seq(0,1,length.out=nb+1L))))
  if(length(br)<3L)br<-sort(unique(score))
  if(uniqueN(score)<=10L)d<-data.table(x=score,y=y)[,.(p=mean(y),w=.N),by=x][order(x)]else {
    bin<-findInterval(score,br,all.inside=TRUE)
    d<-data.table(bin=bin,x=score,y=y)[,.(x=mean(x),p=mean(y),w=.N),by=bin][order(x)]
  }
  c(list(type="isotonic",x=d$x,p=liq_clip(liq_pava(d$p,d$w)),weights=d$w),common)
}

liq_cal_predict <- function(map,s) {
  if(map$type=="constant")return(rep(map$p,length(s)))
  ii<-findInterval(s,map$x,all.inside=FALSE)
  ii<-pmax(1L,pmin(length(map$p),ii));liq_clip(map$p[ii])
}
liq_candidates_v440 <- function(train,cal,guard,test,cfg,inner_bundle=NULL) {
  H<-cfg$horizons;datasets<-list(cal=cal,guard=guard,test=test)
  raw<-lapply(datasets,function(d)list(Historical_raw=liq_empirical(train,d,H),
                                     Regime_raw=liq_empirical(train,d,H,TRUE)))
  fits<-list();diagnostics<-list();tuning<-list();inner<-list()
  lf<-lapply(H,function(h)liq_fit_logit(train,cfg,h,inner_bundle));names(lf)<-H;fits$Logit<-lf
  for(ds in names(datasets))raw[[ds]]$Logit_raw<-do.call(cbind,lapply(lf,liq_predict_logit,e=datasets[[ds]]))
  hf<-liq_fit_hazard(train,cfg,inner_bundle);fits$Hazard<-hf
  for(ds in names(datasets))raw[[ds]]$Hazard_raw<-liq_predict_hazard(hf,datasets[[ds]],H)
  cf<-liq_fit_cox(train,cfg);fits$Cox<-cf
  if(cf$type=="cox")for(ds in names(datasets))raw[[ds]]$Cox_raw<-liq_predict_cox(cf,datasets[[ds]],H)
  diagnostics[[1]]<-data.table(model="Cox_raw",status=cf$type,
       detail=if(cf$type=="cox")paste(cf$warnings,collapse=" | ")else cf$reason)
  maps<-list();pred<-raw
  for(m in names(raw$cal)) {
    mm<-sub("_raw$","_cal",m);maps[[mm]]<-vector("list",length(H))
    for(ds in names(datasets)) {
      raw[[ds]][[m]]<-liq_cdf(raw[[ds]][[m]])
      pred[[ds]][[m]]<-raw[[ds]][[m]]
      pred[[ds]][[mm]]<-matrix(NA_real_,nrow(datasets[[ds]]),length(H),dimnames=list(NULL,H))
    }
    for(j in seq_along(H)) {
      tt<-liq_truth(cal,H[j]);mp<-liq_cal_fit(tt$y[tt$known],raw$cal[[m]][tt$known,j],cfg)
      maps[[mm]][[j]]<-mp
      for(ds in names(datasets))pred[[ds]][[mm]][,j]<-liq_cal_predict(mp,raw[[ds]][[m]][,j])
    }
    for(ds in names(datasets))pred[[ds]][[mm]]<-liq_cdf(pred[[ds]][[mm]])
  }
  for(j in seq_along(lf))if(!is.null(lf[[j]]$tuning)) {
    tt<-liq_dt(lf[[j]]$tuning$table);tt[,`:=`(model="Logit",horizon=H[j])];tuning[[length(tuning)+1L]]<-tt
    aa<-liq_dt(lf[[j]]$tuning$audit);if(nrow(aa)) {aa[,`:=`(model="Logit",horizon=H[j])];inner[[length(inner)+1L]]<-aa}
  }
  if(!is.null(hf$tuning)) {
    tt<-liq_dt(hf$tuning$table);tt[,`:=`(model="Hazard",horizon=NA_integer_)];tuning[[length(tuning)+1L]]<-tt
    aa<-liq_dt(hf$tuning$audit);if(nrow(aa)){aa[,model:="Hazard"];inner[[length(inner)+1L]]<-aa}
  }
  ans<-list(pred=pred,fits=fits,maps=maps,diagnostics=liq_bind(diagnostics),tuning=liq_bind(tuning),inner=liq_bind(inner))
  liq_add_train_mixture(ans,train,cal,guard,test,cfg,inner_bundle)
}
liq_loss_vector <- function(e,p,H,auc=FALSE) {
  vapply(seq_along(H),function(j){tt<-liq_truth(e,H[j]);ok<-tt$known
    if(auc)liq_auc(tt$y[ok],p[ok,j])else mean((tt$y[ok]-p[ok,j])^2)},numeric(1))
}
liq_heads_v440 <- function(candidates,guard,cfg) {
  H<-cfg$horizons;g<-candidates$pred$guard;t<-candidates$pred$test
  rm<-intersect(c("Historical_raw","Regime_raw","Logit_raw","Hazard_raw","Cox_raw"),names(g))
  cm<-intersect(sub("_raw$","_cal",rm),names(g));base_pool<-c(rm,cm)
  L<-vapply(base_pool,function(m)mean(liq_loss_vector(guard,g[[m]],H)),numeric(1))
  single<-base_pool[which.min(L)]
  for(ds in c("g","t")) {
    z<-get(ds);z$Single_Brier_Guard<-z[[single]]
    z$Equal_Raw<-liq_cdf(Reduce(`+`,z[rm])/length(rm))
    z$Equal_Calibrated<-liq_cdf(Reduce(`+`,z[cm])/length(cm));assign(ds,z)
  }
  proposed<-intersect(c("TRAIN_Mixture_raw","TRAIN_Mixture_cal"),names(g))
  scores<-vapply(proposed,function(m)mean(liq_loss_vector(guard,g[[m]],H)),numeric(1))
  proposal<-proposed[which.min(scores)]
  gate<-liq_guard_delta(guard,g[[proposal]],g[[single]],cfg)
  selected<-if(gate$accepted)proposal else single
  g$LIQ_Brier<-g[[selected]];t$LIQ_Brier<-t[[selected]]
  rank_names<-c("Legacy_Rank_Router","Single_Rank_Guard","LIQ_Rank_Guard")
  for(nm in rank_names) {
    g[[nm]]<-matrix(NA_real_,nrow(guard),length(H),dimnames=list(NULL,H))
    t[[nm]]<-matrix(NA_real_,nrow(t[[1]]),length(H),dimnames=list(NULL,H))
  }
  choices<-list();counter<-0L
  for(j in seq_along(H)) {
    y<-liq_truth(guard,H[j])$y;pos<-is.finite(y)&y==1L;neg<-is.finite(y)&y==0L
    selection_allowed<-min(sum(pos),sum(neg))>=cfg$min_class &&
      min(uniqueN(guard$shock_date[pos]),uniqueN(guard$shock_date[neg]))>=cfg$selection_min_dates &&
      min(uniqueN(guard$asset[pos]),uniqueN(guard$asset[neg]))>=cfg$selection_min_assets
    aa<-vapply(rm,function(m)liq_auc(y,g[[m]][,j]),numeric(1))
    aa[!is.finite(aa)|!selection_allowed]<- -Inf
    best<-if(all(aa== -Inf))"Historical_raw"else rm[which.max(aa)]
    emp<-intersect(c("Historical_raw","Regime_raw"),rm)
    legacy<-if(H[j]>5)"Regime_raw"else if(selection_allowed&&aa["Logit_raw"]>=max(aa[emp]))"Logit_raw"else best
    for(pair in list(c("Legacy_Rank_Router",legacy),c("Single_Rank_Guard",best))) {
      nm<-pair[1];src<-pair[2];g[[nm]][,j]<-g[[src]][,j];t[[nm]][,j]<-t[[src]][,j]
      counter<-counter+1L;choices[[counter]]<-data.table(head=nm,horizon=H[j],component1=src,component2=NA_character_,weight1=1)
    }
    chosen<-list(m1=best,m2=best,w=1);best_auc<-aa[best]
    if(selection_allowed)for(ab in utils::combn(rm,2,simplify=FALSE))for(w in cfg$rank_mix_grid) {
      score<-liq_auc(y,w*g[[ab[1]]][,j]+(1-w)*g[[ab[2]]][,j])
      if(is.finite(score)&&score>best_auc+1e-12) {
        chosen<-list(m1=ab[1],m2=ab[2],w=w);best_auc<-score
      }
    }
    if(selection_allowed && best_auc<=aa[best]+cfg$rank_min_gain)
      chosen<-list(m1=best,m2=best,w=1)
    nm<-"LIQ_Rank_Guard"
    g[[nm]][,j]<-chosen$w*g[[chosen$m1]][,j]+(1-chosen$w)*g[[chosen$m2]][,j]
    t[[nm]][,j]<-chosen$w*t[[chosen$m1]][,j]+(1-chosen$w)*t[[chosen$m2]][,j]
    counter<-counter+1L;choices[[counter]]<-data.table(head=nm,horizon=H[j],component1=chosen$m1,
      component2=chosen$m2,weight1=chosen$w,guard_positive=sum(pos),guard_negative=sum(neg),
      selection_allowed=selection_allowed,minimum_pair_AUC_gain=cfg$rank_min_gain)
  }
  for(h in H) {
    counter<-counter+1L;choices[[counter]]<-data.table(head="Single_Brier_Guard",horizon=h,component1=single,weight1=1)
    counter<-counter+1L;choices[[counter]]<-data.table(head="LIQ_Brier",horizon=h,component1=single,
      component2=proposal,weight1=NA_real_,selected_source=selected,
      note="compare with GUARD-selected raw/calibrated single; output identity is tested directly")
  }
  top<-c(base_pool,proposed)
  weights<-liq_bind(lapply(H,function(h)data.table(horizon=h,component=top,weight=as.numeric(top==selected),
    retained_ensemble=gate$accepted,guard_baseline=single,selected_source=selected,
    guard_rule="paired block-margin heuristic; not a confidence guarantee")))
  gate_table<-data.table(proposal=proposal,single=single,selected=selected,
    delta_Brier=gate$estimate,block_SE=gate$se,n_blocks=gate$blocks,
    margin_z=cfg$guard_margin_z,min_gain=cfg$guard_min_gain,accepted=gate$accepted,
    interpretation="GUARD selection heuristic; only TEST inference assesses out-of-sample difference")
  list(guard=g,test=t,choices=liq_bind(choices),weights=weights,rank_names=rank_names,gate=gate_table)
}

liq_metrics <- function(y,p,w,ref_hist,ref_reg,rank_only=FALSE,costs=c(1,2,5)) {
  ok<-is.finite(y)&is.finite(p)&is.finite(w)&w>0
  empty<-c(n=0,weight_n=0,observed_rate=NA_real_,mean_output=NA_real_,Brier=NA_real_,AUC=NA_real_,
           BSS_historical=NA_real_,BSS_regime=NA_real_,log_loss=NA_real_,cal_error=NA_real_,
           CITL=NA_real_,cal_intercept=NA_real_,cal_slope=NA_real_)
  empty<-c(empty,stats::setNames(rep(NA_real_,length(costs)),paste0("decision_cost_r",costs)))
  if(!any(ok))return(empty)
  y<-y[ok];p<-p[ok];w<-w[ok];rh<-ref_hist[ok];rr<-ref_reg[ok]
  av<-function(z)sum(w*z)/sum(w)
  ans<-empty;ans[c("n","weight_n","observed_rate","mean_output","AUC")]<-
    c(length(y),sum(w),av(y),av(p),liq_auc(y,p,w))
  if(rank_only)return(ans)
  p<-liq_clip(p);bs<-av((y-p)^2);bh<-av((y-rh)^2);br<-av((y-rr)^2)
  ans[c("Brier","BSS_historical","BSS_regime","log_loss","cal_error")]<-
    c(bs,if(bh>1e-12)1-bs/bh else NA_real_,if(br>1e-12)1-bs/br else NA_real_,
      av(-y*log(p)-(1-y)*log(1-p)),av(p-y))
  ans[names(liq_calibration(y,p,w))]<-liq_calibration(y,p,w)
  for(r in costs) {
    action<-p>=r/(r+1)
    ans[paste0("decision_cost_r",r)]<-av(r*action*(1-y)+(1-action)*y)
  }
  ans
}
liq_evaluate <- function(e,pred,cfg,rank_names,w=rep(1,nrow(e))) {
  out<-list();ii<-0L
  for(m in names(pred))for(j in seq_along(cfg$horizons)) {
    h<-cfg$horizons[j];tt<-liq_truth(e,h);ww<-w*tt$known
    vv<-liq_metrics(tt$y,pred[[m]][,j],ww,pred$Historical_cal[,j],pred$Regime_cal[,j],
                    m%in%rank_names,cfg$cost_ratios)
    ii<-ii+1L;out[[ii]]<-cbind(data.table(model=m,horizon=h,
      output_type=if(m%in%rank_names)"ranking score"else"probability"),as.data.table(as.list(vv)))
  }
  liq_bind(out)
}
liq_boot_weights <- function(e,calendar,B,L,seed,crossed=FALSE) {
  set.seed(seed);dd<-calendar[calendar>=min(e$shock_date)&calendar<=max(e$shock_date)]
  T<-length(dd);idx<-match(e$shock_date,dd)
  liq_assert(!anyNA(idx),"Bootstrap calendar alignment failed.")
  assets<-sort(unique(e$asset));ai<-match(e$asset,assets)
  w<-matrix(0,nrow(e),B)
  for(b in seq_len(B)) {
    starts<-sample.int(T,ceiling(T/L),replace=TRUE)
    sampled<-as.vector(outer(0:(L-1L),starts,`+`))
    sampled<-((sampled-1L)%%T)+1L;sampled<-sampled[seq_len(T)]
    cw<-tabulate(sampled,nbins=T);ww<-cw[idx]
    if(crossed)ww<-ww*tabulate(sample.int(length(assets),length(assets),replace=TRUE),nbins=length(assets))[ai]
    w[,b]<-ww
  }
  w
}
liq_interval <- function(x) {
  x<-x[is.finite(x)]
  if(length(x)<10L)return(c(lower=NA_real_,upper=NA_real_,valid=length(x)))
  c(lower=as.numeric(quantile(x,.025,names=FALSE)),upper=as.numeric(quantile(x,.975,names=FALSE)),valid=length(x))
}
liq_comparison_pairs <- function(pred,choices,H) {
  rows<-list();i<-0L
  refs<-intersect(c("Historical_raw","Regime_raw","Logit_raw","Hazard_raw","Cox_raw","Historical_cal","Regime_cal","Logit_cal","Equal_Raw","Equal_Calibrated","Single_Brier_Guard"),names(pred))
  for(m in names(pred))for(ref in refs)for(h in H)if(m!=ref) {
    i<-i+1L;rows[[i]]<-data.table(model=m,reference=ref,horizon=h,family="reference_comparison")
  }
  for(j in seq_len(nrow(choices)))for(ref in unique(c(choices$component1[j],choices$component2[j]))) {
    if(is.na(ref)||!ref%in%names(pred)||choices$head[j]==ref)next
    i<-i+1L;rows[[i]]<-data.table(model=choices$head[j],reference=ref,
                 horizon=choices$horizon[j],family="selected_component_increment")
  }
  unique(liq_bind(rows))
}
liq_inference <- function(e,pred,choices,cfg,calendar,rank_names,B=cfg$boot_reps,
                         L=cfg$block_length,crossed=FALSE) {
  tag<-paste0(if(crossed)"crossed_asset_date"else"date_block","_L",L)
  point<-liq_evaluate(e,pred,cfg,rank_names)
  w<-liq_boot_weights(e,calendar,B,L,cfg$seed+L+if(crossed)10000L else 0L,crossed)
  rows<-vector("list",B)
  for(b in seq_len(B)) {
    if(b%%250L==0L)liq_log("Bootstrap",tag,b,"/",B)
    z<-liq_evaluate(e,pred,cfg,rank_names,w[,b]);z[,replicate:=b];rows[[b]]<-z
  }
  samples<-liq_bind(rows)
  fields<-setdiff(names(point),c("model","horizon","output_type","n","weight_n"))
  ll<-data.table::melt(samples,id.vars=c("model","horizon","replicate"),measure.vars=fields,
                      variable.name="metric",value.name="value")
  ci<-ll[,as.list(liq_interval(value)),by=.(model,horizon,metric)]
  pl<-data.table::melt(point,id.vars=c("model","horizon","output_type"),measure.vars=fields,
                      variable.name="metric",value.name="estimate")
  ci<-merge(pl,ci,by=c("model","horizon","metric"),all.x=TRUE)
  ci[,`:=`(method=tag,B_requested=B,inference=cfg$inference_scope)]
  pairs<-liq_comparison_pairs(pred,choices,cfg$horizons);dr<-list();counter<-0L
  comp_metrics<-c("Brier","AUC","log_loss",paste0("decision_cost_r",cfg$cost_ratios))
  for(k in seq_len(nrow(pairs))) {
    pa<-pairs[k];aa<-samples[model==pa$model & horizon==pa$horizon][order(replicate)]
    bb<-samples[model==pa$reference & horizon==pa$horizon][order(replicate)]
    ap<-point[model==pa$model & horizon==pa$horizon];bp<-point[model==pa$reference & horizon==pa$horizon]
    j<-match(pa$horizon,cfg$horizons)
    same<-isTRUE(all.equal(pred[[pa$model]][,j],pred[[pa$reference]][,j],tolerance=0,check.attributes=FALSE))
    for(metric in comp_metrics) {
      est<-ap[[metric]]-bp[[metric]];ds<-aa[[metric]]-bb[[metric]]
      iv<-liq_interval(ds);vv<-ds[is.finite(ds)]
      pv<-if(length(vv)>=10L&&is.finite(est))
        (1+sum(abs(vv-est)>=abs(est)))/(length(vv)+1) else NA_real_
      counter<-counter+1L;dr[[counter]]<-cbind(pa,data.table(metric=metric,estimate=est,
        lower=iv["lower"],upper=iv["upper"],valid=iv["valid"],p_value=pv,
        identical_output=same,method=tag,B_requested=B))
    }
  }
  diffs<-liq_bind(dr)
  diffs[,p_holm:=stats::p.adjust(p_value,method="holm"),by=.(family,metric)]
  support<-liq_class_support(e,cfg,roles="TEST")[,role:=NULL]
  ci<-merge(ci,support,by="horizon",all.x=TRUE)
  diffs<-merge(diffs,support,by="horizon",all.x=TRUE)
  list(point=point,intervals=ci,differences=diffs,samples=samples,weights=w,method=tag)
}
liq_reliability <- function(e,pred,cfg,rank_names,weights) {
  rows<-list();ii<-0L
  for(m in setdiff(names(pred),rank_names))for(j in seq_along(cfg$horizons)) {
    tt<-liq_truth(e,cfg$horizons[j]);p<-pred[[m]][,j]
    bin<-cut(p,seq(0,1,by=.1),include.lowest=TRUE,labels=FALSE)
    for(bn in 1:10) {
      ok<-which(bin==bn&tt$known)
      if(!length(ok))next
      sw<-colSums(weights[ok,,drop=FALSE]);yy<-colSums(weights[ok,,drop=FALSE]*tt$y[ok])/sw
      yy[sw==0]<-NA_real_;iv<-liq_interval(yy)
      ii<-ii+1L;rows[[ii]]<-data.table(model=m,horizon=cfg$horizons[j],bin=bn,n=length(ok),
        mean_prediction=mean(p[ok]),observed=mean(tt$y[ok]),lower=iv["lower"],upper=iv["upper"],
        valid=iv["valid"],small_bin=length(ok)<10L)
    }
  }
  liq_bind(rows)
}
liq_km <- function(e,H,w=rep(1,nrow(e))) {
  ans<-rep(1,H+1L);risk<-rep(0,H+1L)
  if(!nrow(e)||sum(w)<=0)return(list(survival=rep(NA_real_,H+1L),risk=risk))
  risk[1]<-sum(w)
  for(h in seq_len(H)) {
    nr<-sum(w*(e$duration>=h));ne<-sum(w*(e$status==1L&e$duration==h))
    risk[h+1L]<-nr;ans[h+1L]<-ans[h]*if(nr>0)1-ne/nr else 1
  }
  list(survival=ans,risk=risk)
}
liq_km_report <- function(e,cfg,weights) {
  H<-cfg$max_h;curves<-list();dist<-list();ii<-0L
  for(r in c("Low","Normal","High","Missing")) {
    idx<-which(e$regime==r);if(!length(idx))next
    pt<-liq_km(e[idx],H);sim<-vapply(seq_len(ncol(weights)),function(b)
                liq_km(e[idx],H,weights[idx,b])$survival,numeric(H+1L))
    iv<-t(apply(sim,1,liq_interval));ii<-ii+1L
    curves[[ii]]<-data.table(regime=r,day=0:H,non_recovery=pt$survival,n_at_risk=pt$risk,
           lower=iv[,1],upper=iv[,2],valid=iv[,3],population="eligible full-window TEST events")
    dist[[r]]<-sim
  }
  contrasts<-list()
  if(all(c("High","Low")%in%names(dist)))for(h in intersect(c(5L,10L,20L,30L),seq_len(H))) {
    cr<-liq_bind(curves);delta<-cr[regime=="High"&day==h,non_recovery]-cr[regime=="Low"&day==h,non_recovery]
    ds<-dist$High[h+1L,]-dist$Low[h+1L,];iv<-liq_interval(ds);vv<-ds[is.finite(ds)]
    contrasts[[length(contrasts)+1L]]<-data.table(horizon=h,contrast="High minus Low non-recovery",
       estimate=delta,lower=iv[1],upper=iv[2],valid=iv[3],p_value=if(length(vv)>=10)
       (1+sum(abs(vv-delta)>=abs(delta)))/(length(vv)+1)else NA_real_)
  }
  ct<-liq_bind(contrasts);if(nrow(ct))ct[,p_holm:=p.adjust(p_value,"holm")]
  list(curves=liq_bind(curves),contrasts=ct)
}

liq_long_predictions <- function(e,pred,cfg,rank_names) {
  out<-list();i<-0L
  for(m in names(pred))for(j in seq_along(cfg$horizons)) {
    h<-cfg$horizons[j];tt<-liq_truth(e,h);i<-i+1L
    out[[i]]<-data.table(event_id=e$event_id,asset=e$asset,shock_date=e$shock_date,
      model=m,horizon=h,y=tt$y,known=tt$known,output=pred[[m]][,j],regime=e$regime,
      output_type=if(m%in%rank_names)"ranking score; higher = faster recovery"else"recovery probability")
  }
  liq_bind(out)
}
liq_describe <- function(d,cols,group="asset") {
  liq_bind(lapply(cols,function(cc) {
    if(!cc%in%names(d))return(NULL)
    d[,{
      x<-get(cc);x<-x[is.finite(x)];nn<-length(x);mu<-if(nn)mean(x)else NA_real_;ss<-if(nn>1)sd(x)else NA_real_
      .(variable=cc,n=nn,mean=mu,sd=ss,q01=if(nn)as.numeric(quantile(x,.01))else NA_real_,
        median=if(nn)as.numeric(median(x))else NA_real_,q99=if(nn)as.numeric(quantile(x,.99))else NA_real_,
        skewness=if(nn>2&&ss>0)mean((x-mu)^3)/ss^3 else NA_real_,
        excess_kurtosis=if(nn>3&&ss>0)mean((x-mu)^4)/ss^4-3 else NA_real_,
        lag1_correlation=if(nn>10&&ss>0)suppressWarnings(cor(x[-1],x[-nn]))else NA_real_)
    },by=group]
  }))
}
liq_proxy_validation <- function(p,fold) {
  d<-liq_dt(p);d[,period:="OUTSIDE"]
  for(j in seq_len(nrow(fold)))d[date>=fold$from[j]&date<=fold$to[j],period:=fold$role[j]]
  out<-list();i<-0L
  for(proxy in c("amihud","cs_spread"))for(index in c("lsi",paste0("z_lsi",1:5))) {
    i<-i+1L
    z<-d[,{
      xx<-get(index);yy<-get(proxy);ok<-is.finite(xx)&is.finite(yy)
      reason<-if(sum(ok)<=20L)"insufficient_paired_observations"else
        if(uniqueN(xx[ok])<2L)"constant_index"else if(uniqueN(yy[ok])<2L)"constant_proxy"else"estimated"
      .(n=sum(ok),spearman=if(reason=="estimated")cor(xx[ok],yy[ok],method="spearman")else NA_real_,reason=reason)
    },by=.(asset,period)]
    z[,`:=`(index=index,proxy=proxy,
      interpretation="convergent validity; shared inputs; not independent execution-cost evidence")]
    out[[i]]<-z
  }
  liq_bind(out)
}

liq_feature_spec <- function() {
  cols<-liq_feature_names()
  data.table(feature=cols,
    timestamp=ifelse(cols%in%c("lsi_lag1","market_loo_lag1","market_trend5",
       "shock_cluster_share_lag1","volume_breadth_lag1","avg_corr_lag1","vix_lag1","vix_change5"),
       "at or before preceding reference session","shock session after finalized daily data"),
    missing_rule="TRAIN median plus explicit VIX missing flag; no OHLCV forward fill",
    scaling="TRAIN mean/SD; independently refitted in supervised forward-validation folds",
    selection_sample="TRAIN only; feature list fixed in configuration")
}
liq_coefficients <- function(candidates,H) {
  rows<-list();i<-0L
  for(j in seq_along(H)) {
    ff<-candidates$fits$Logit[[j]];if(ff$type!="glmnet")next
    co<-as.matrix(stats::coef(ff$fit,s=ff$lambda))
    i<-i+1L;rows[[i]]<-data.table(model="Logit_raw",horizon=H[j],term=rownames(co),coefficient=co[,1])
  }
  ff<-candidates$fits$Hazard
  if(ff$type=="glmnet") {
    co<-as.matrix(stats::coef(ff$fit,s=ff$lambda));i<-i+1L
    rows[[i]]<-data.table(model="Hazard_raw",horizon=NA_integer_,term=rownames(co),coefficient=co[,1])
  }
  ff<-candidates$fits$Cox
  if(ff$type=="cox") {co<-stats::coef(ff$fit);i<-i+1L
    rows[[i]]<-data.table(model="Cox_raw",horizon=NA_integer_,term=names(co),coefficient=co)}
  liq_bind(rows)
}
liq_model_spec_v440 <- function(cfg) data.table(
  item=c("forecast_origin","target","horizons","calibration","logit_penalty","hazard_penalty",
         "hazard_time_basis","lambda_selection","Cox_ties","probability_combination",
         "probability_guard","rank_router","rank_ensemble","duration_diagnostic","economic_cost",
         "BSS_references","inference","sample_selection","historical_test"),
  value=c("after complete shock-day OHLCV; actions from next trading session",
    "first completed k-session recovery confirmation; early followup is separately censored",
    paste(cfg$horizons,collapse=","),
    "CAL_FIT-only binned weighted isotonic maps; flat endpoint extension; CDF projection for all probability models",
    paste0("elastic net alpha=",cfg$alpha_logit),paste0("ridge alpha=",cfg$alpha_hazard),
    "natural spline with fixed knots H/3,2H/3 and boundaries 1,H",
    if(isTRUE(cfg$strict_inner))"nested daily TRAIN validation: daily transforms/thresholds/regimes and supervised preprocessing refit before validation; one-SE lambda"else
      "conditional validation on outer-TRAIN event definition; not full nested daily reconstruction",
    "Breslow; TRAIN Schoenfeld diagnostic; robust asset cluster variance",
    "global raw-model weights from nested TRAIN validation; TRAIN-only eta/shrinkage tuning; separate CAL_FIT isotonic map",
    "GUARD raw/calibrated proposal vs best raw/calibrated single; paired block-margin heuristic; no finite-sample guarantee",
    "legacy <=5 guard-competitive logit, >5 regime; retrospective comparator, no original preregistration claim",
    "GUARD raw single/pair AUC with fixed minimum gain and class/cluster support; no probability interpretation",
    "probability models only: first >=0.5 horizon; capped grid diagnostic, uncensored subset only",
    "resume if p>=r/(r+1); false recovery cost r, unnecessary caution cost 1; fixed scenario ratios",
    "Historical_cal and Regime_cal; updated using CAL_FIT without TEST labels",
    cfg$inference_scope,
    if(nzchar(cfg$membership_file))"provided historical membership, source still requires verification"else
       "fixed convenience panel; survivorship and ex-post selection remain limitations",
    "already inspected; all historical results are re-analysis"))

liq_runtime_checks <- function(e,pred,heads,cfg) {
  chk<-list();i<-0L
  add<-function(name,pass,detail="") {
    i<<-i+1L;chk[[i]]<<-data.table(check=name,pass=isTRUE(pass),detail=detail)
  }
  add("unique_event_ids",!anyDuplicated(e$event_id))
  add("four_separate_roles",all(c("TRAIN","CAL_FIT","GUARD","TEST")%in%e$role))
  for(r in c("TRAIN","CAL_FIT","GUARD","TEST")) {
    d<-e[role==r&analysis_eligible==TRUE]
    add(paste0("full_followup_",r),nrow(d)>0&&all(d$followup>=cfg$max_h))
    add(paste0("labels_closed_",r),nrow(d)>0&&all(d$planned_end<=cfg$fold$to[cfg$fold$role==r]))
  }
  neg<-e[analysis_eligible==TRUE & status==0L & followup>=cfg$max_h]
  add("Hmax_negatives_retained",all(liq_truth(neg,cfg$max_h)$known),
      paste(nrow(neg),"full-window non-recoveries"))
  for(m in names(pred)) {
    add(paste0("finite_output_",m),all(is.finite(pred[[m]])))
    if(!m%in%heads$rank_names)add(paste0("coherent_CDF_",m),
      all(pred[[m]]>=0&pred[[m]]<=1)&&all(apply(pred[[m]],1,function(z)all(diff(z)>= -1e-12))))
  }
  add("probability_weights_sum_one",all(abs(heads$weights[,sum(weight),by=horizon]$V1-1)<1e-10))
  j<-which(cfg$horizons>5)
  add("legacy_long_rank_is_regime",!length(j)||
    isTRUE(all.equal(pred$Legacy_Rank_Router[,j,drop=FALSE],pred$Regime_raw[,j,drop=FALSE],tolerance=0)))
  liq_bind(chk)
}
liq_duration_diagnostics <- function(e,pred,cfg,rank_names,train) {
  recovered<-train$duration[train$status==1L]
  cut<-if(length(recovered))median(recovered)else NA_real_
  slow_h<-if(is.finite(cut))cfg$horizons[which.min(abs(cfg$horizons-cut))]else NA_integer_
  j<-match(slow_h,cfg$horizons)
  truth_slow<-if(is.finite(slow_h))1-liq_truth(e,slow_h)$y else rep(NA_real_,nrow(e))
  liq_bind(lapply(setdiff(names(pred),rank_names),function(m) {
    pp<-pred[[m]];times<-apply(pp,1,function(z){hit<-which(z>=.5);if(length(hit))cfg$horizons[hit[1]]else cfg$max_h})
    ok<-e$status==1L;er<-times[ok]-e$duration[ok]
    cc<-if(length(unique(times))>1L)tryCatch(
      survival::concordance(survival::Surv(e$duration,e$status)~times,reverse=FALSE)$concordance,
      error=function(x)NA_real_)else NA_real_
    data.table(model=m,n_uncensored=sum(ok),MAE_uncensored=if(any(ok))mean(abs(er))else NA_real_,
      RMSE_uncensored=if(any(ok))sqrt(mean(er^2))else NA_real_,C_index=cc,
      slow_horizon=slow_h,slow_AUC=if(is.finite(j))liq_auc(truth_slow,1-pp[,j])else NA_real_,
      definition="grid median capped at Hmax; slow means not recovered by TRAIN-derived nearest grid horizon")
  }))
}
liq_draw_intervals <- function(x,lo,hi,col) {
  ok<-is.finite(x)&is.finite(lo)&is.finite(hi)&hi>lo+1e-12
  if(any(ok))arrows(x[ok],lo[ok],x[ok],hi[ok],angle=90,code=3,length=.035,col=col)
}
liq_plot_file <- function(out,name,draw,width=7.2,height=5.2) {
  dd<-liq_dir(file.path(out,"figures"))
  grDevices::pdf(file.path(dd,paste0(name,".pdf")),width=width,height=height,family="Helvetica",useDingbats=FALSE)
  tryCatch(draw(),finally=grDevices::dev.off())
  grDevices::png(file.path(dd,paste0(name,".png")),width=width,height=height,units="in",res=300)
  tryCatch(draw(),finally=grDevices::dev.off())
}
liq_figures <- function(result,cfg,out) {
  sel<-intersect(c("LIQ_Brier","Single_Brier_Guard","Logit_cal","Regime_cal","Historical_cal",
                   "Legacy_Rank_Router","LIQ_Rank_Guard"),names(result$heads$test))
  cols<-setNames(c("#0072B2","#E69F00","#009E73","#CC79A7","#666666","#D55E00","#56B4E9")[seq_along(sel)],sel)
  market<-unique(result$problem$context[,.(date,market_full)])[order(date)]
  liq_plot_file(out,"F1_market_stress",function(){
    par(mar=c(4,4,2,1));plot(market$date,market$market_full,type="l",lwd=.6,col="#333333",
       xlab="Date",ylab="Market liquidity-stress index");abline(h=0,col="grey80",lty=3)
  })
  for(metric in c("Brier","AUC","BSS_historical")) {
    metric_name<-metric
    dd<-result$inference$intervals[as.character(get("metric"))==metric_name & model%in%sel]
    rng<-range(c(dd$lower,dd$upper,dd$estimate),finite=TRUE)
    if(!all(is.finite(rng)))next
    if(metric=="AUC")rng<-c(0,1)
    if(diff(rng)<1e-6)rng<-rng+c(-.05,.05)
    this_metric<-metric;this_dd<-liq_dt(dd);this_rng<-rng
    this_models<-intersect(sel,dd[is.finite(estimate),unique(model)])
    liq_plot_file(out,paste0("F2_",metric),local({met<-this_metric;d<-this_dd;rr<-this_rng;ms<-this_models;function(){
      par(mar=c(4,4,2,1));plot(range(cfg$horizons),rr,type="n",xlab="Recovery horizon (trading sessions)",ylab=met)
      if(met=="AUC")abline(h=.5,lty=3,col="grey70")
      if(grepl("BSS",met))abline(h=0,lty=3,col="grey70")
      for(mm in ms){z<-d[model==mm][order(horizon)];if(!nrow(z)||all(!is.finite(z$estimate)))next
        lines(z$horizon,z$estimate,type="b",pch=16,lwd=1,col=cols[mm]);
        liq_draw_intervals(z$horizon,z$lower,z$upper,cols[mm])}
      legend("topright",legend=ms,col=cols[ms],lty=1,pch=16,cex=.60,bg="white",bty="n")
    }}))
  }
  for(h in cfg$horizons) {
    d<-result$reliability[horizon==h & model%in%c("LIQ_Brier","Logit_cal","Regime_cal")]
    hh<-h;dd<-liq_dt(d)
    liq_plot_file(out,paste0("F3_reliability_h",h),local({z<-dd;hl<-hh;function(){
      par(mar=c(4,4,2,1));plot(c(0,1),c(0,1),type="n",xlab="Mean forecast probability",
        ylab="Observed recovery fraction",main=paste("Horizon",hl));abline(0,1,lty=2,col="grey70")
      for(mm in unique(z$model)){a<-z[model==mm][order(mean_prediction)]
        lines(a$mean_prediction,a$observed,type="b",pch=16,col=cols[mm]);
        liq_draw_intervals(a$mean_prediction,a$lower,a$upper,cols[mm])}
      legend("topleft",unique(z$model),col=cols[unique(z$model)],lty=1,pch=16,bty="n",cex=.8)
    }}))
  }
  km<-result$km$curves
  liq_plot_file(out,"F4_KM_regimes",function(){
    layout(matrix(1:2,2,1),heights=c(3,1));par(mar=c(2,4,2,1))
    plot(c(0,cfg$max_h),c(0,1),type="n",xlab="",ylab="Probability not yet recovered")
    rg<-intersect(c("Low","Normal","High"),unique(km$regime));co<-c("#009E73","#0072B2","#D55E00")
    for(j in seq_along(rg)){a<-km[regime==rg[j]][order(day)];
      polygon(c(a$day,rev(a$day)),c(a$lower,rev(a$upper)),col=adjustcolor(co[j],alpha.f=.12),border=NA)
      lines(a$day,a$non_recovery,type="s",lwd=1.4,col=co[j])}
    legend("topright",rg,col=co[seq_along(rg)],lty=1,bty="n",cex=.8)
    par(mar=c(3,4,0,1));plot(c(0,cfg$max_h),c(.5,length(rg)+.5),type="n",yaxt="n",xlab="Trading sessions",ylab="At risk")
    axis(2,at=seq_along(rg),labels=rg,las=1,cex.axis=.7)
    ticks<-unique(c(0,cfg$horizons));for(j in seq_along(rg)) {
      a<-km[regime==rg[j]&day%in%ticks];text(a$day,j,labels=a$n_at_risk,cex=.7)}
    layout(1)
  },height=6.2)
  lp<-result$long[model%in%c("LIQ_Brier","Logit_cal")]
  lp[,quarter:=paste0(format(shock_date,"%Y"),"-Q",(as.integer(format(shock_date,"%m"))-1L)%/%3L+1L)]
  drift<-lp[,.(n=.N,observed=mean(y),predicted=mean(output)),by=.(model,horizon,quarter)]
  liq_save(drift,"A12_quarterly_recovery_predictions",out)
  for(h in cfg$horizons) {
    d<-drift[horizon==h];hh<-h;dd<-liq_dt(d)
    liq_plot_file(out,paste0("F5_temporal_h",h),local({z<-dd;hl<-hh;function(){
      qs<-sort(unique(z$quarter));par(mar=c(6,4,2,1));plot(seq_along(qs),rep(NA_real_,length(qs)),ylim=c(0,1),
        xaxt="n",xlab="",ylab="Recovery fraction / probability",main=paste("Horizon",hl))
      axis(1,at=seq_along(qs),labels=qs,las=2,cex.axis=.65)
      a<-z[model=="LIQ_Brier"];lines(match(a$quarter,qs),a$observed,type="b",col="black",pch=1)
      for(mm in unique(z$model)){a<-z[model==mm];lines(match(a$quarter,qs),a$predicted,type="b",col=cols[mm],pch=16)}
      legend("topleft",c("Observed",unique(z$model)),col=c("black",cols[unique(z$model)]),lty=1,bty="n",cex=.75)
    }}))
  }
  invisible(TRUE)
}

liq_outer <- function(raw_features,calendar,cfg,fold=cfg$fold,variant=cfg$index_variant,
                      nonoverlap=FALSE,regime_source=cfg$regime_source,out=NULL,
                      inference=FALSE,prepared_index=NULL) {
  cfg$fold<-fold
  ix<-if(is.null(prepared_index))liq_index(raw_features,cfg,fold,variant)else prepared_index
  pr<-liq_events(ix$panel,calendar,cfg,fold,nonoverlap=nonoverlap,regime_source=regime_source)
  ev<-pr$events
  if(!is.null(out)) {liq_dir(out);liq_save(ev,"T01_event_dictionary",out)}
  blocks<-lapply(c("TRAIN","CAL_FIT","GUARD","TEST"),function(r)ev[role==r&analysis_eligible==TRUE])
  names(blocks)<-c("TRAIN","CAL_FIT","GUARD","TEST")
  minimum<-c(TRAIN=cfg$min_train,CAL_FIT=cfg$min_cal,GUARD=cfg$min_guard,TEST=30L)
  for(r in names(blocks))liq_need(nrow(blocks[[r]])>=minimum[r],
    paste("Too few eligible",r,"events:",nrow(blocks[[r]]),"required",minimum[r],"No calibration/guard pooling is allowed."))
  support<-liq_class_support(ev,cfg)
  if(!is.null(out))liq_save(support,"A24_class_and_cluster_support",out)
  if(isTRUE(cfg$require_class_support)) {
    bad<-support[role%in%c("CAL_FIT","GUARD")&class_supported==FALSE]
    liq_need(!nrow(bad),paste("CAL/GUARD class support failed:",paste(bad$role,bad$horizon,bad$positive,bad$negative,collapse="; "),"No pooling or threshold relaxation."))
  }
  inner_bundle<-if(isTRUE(cfg$strict_inner)&&!nzchar(cfg$frozen_file))liq_nested_inner(raw_features,calendar,cfg,fold,
    variant,nonoverlap,regime_source)else NULL
  cand<-liq_candidates(blocks$TRAIN,blocks$CAL_FIT,blocks$GUARD,blocks$TEST,cfg,inner_bundle)
  heads<-liq_heads(cand,blocks$GUARD,cfg)
  pt<-liq_evaluate(blocks$TEST,heads$test,cfg,heads$rank_names)
  checks<-liq_runtime_checks(ev,heads$test,heads,cfg)
  liq_assert(all(checks$pass),paste("Runtime integrity failure:",paste(checks[pass==FALSE,check],collapse=", ")))
  long<-liq_long_predictions(blocks$TEST,heads$test,cfg,heads$rank_names)
  result<-list(point=pt,problem=pr,index=ix,inner_bundle=inner_bundle,blocks=blocks,candidates=cand,heads=heads,checks=checks,long=long)
  if(inference) {
    result$inference<-liq_inference(blocks$TEST,heads$test,heads$choices,cfg,calendar,heads$rank_names)
    result$reliability<-liq_reliability(blocks$TEST,heads$test,cfg,heads$rank_names,result$inference$weights)
    result$km<-liq_km_report(blocks$TEST,cfg,result$inference$weights)
  }
  result$self_normalized<-liq_sn_pairs(blocks$TEST,heads$test,cfg,calendar,heads$choices,cand$fits$Correction)
  result$batch_inference<-liq_batch_pairs(blocks$TEST,heads$test,cfg,calendar,heads$choices,cand$fits$Correction)
  if(!is.null(out)) {
    liq_dir(out);liq_dir(file.path(out,"objects"))
    liq_save(result$self_normalized,"T15_self_normalized_paired_differences",out)
    liq_save(result$batch_inference,"T16_calendar_batch_influence_t",out)
    if(!is.null(cand$fits$Correction)) {
      liq_save(cand$fits$Correction$tuning,"A32_correction_TRAIN_tuning",out)
      liq_save(cand$fits$Correction$validation,"A33_correction_meta_validation",out)
      liq_save(cand$fits$Correction$audit,"A34_correction_forward_audit",out)
      liq_save(data.table(type=cand$fits$Correction$type,lambda=cand$fits$Correction$lambda,
        gamma=cand$fits$Correction$gamma,n_oof=cand$fits$Correction$n_oof,
        selection=cand$fits$Correction$selection),"A35_correction_status",out)
    }
    liq_save(ev,"T01_event_dictionary",out)
    split<-ev[,.(n_origins=.N,n_eligible=sum(analysis_eligible),n_early_followup=sum(followup<cfg$max_h),
      first_origin=min(shock_date),last_origin=max(shock_date)),by=role]
    included<-ev[analysis_eligible==TRUE,.(first_eligible=min(shock_date),last_eligible=max(shock_date),
        last_label=max(planned_end),recovery_rate=mean(status),median_duration=median(duration)),by=role]
    liq_save(merge(split,included,by="role",all.x=TRUE),"T02_four_role_summary",out)
    liq_save(ev[,.N,by=.(role,exclusion)],"A01_event_exclusions",out)
    liq_save(ev[,.N,by=.(asset,role,analysis_eligible)],"A02_asset_event_counts",out)
    liq_save(pt,"T03_horizon_performance",out)
    compact<-pt[,.(horizons=paste(horizon,collapse=","),n_valid_Brier=sum(is.finite(Brier)),
      n_valid_AUC=sum(is.finite(AUC)),avg_Brier=liq_mean(Brier),
      avg_AUC=liq_mean(AUC),avg_BSS_historical=liq_mean(BSS_historical),avg_abs_cal_error=liq_mean(abs(cal_error)),
      weighting="equal horizon weights; per-horizon results are primary"),by=.(model,output_type)]
    liq_save(compact,"T04_equal_horizon_summary",out)
    liq_save(pt[horizon%in%c(5,10,20),.(avg_Brier=liq_mean(Brier),avg_AUC=liq_mean(AUC)),by=model],
             "A03_legacy_three_horizon_summary",out)
    liq_save(heads$weights,"T05_probability_weights",out)
    liq_save(heads$choices,"T06_selected_components",out)
    liq_save(long,"T07_frozen_test_predictions",out)
    liq_save(checks,"T08_runtime_checks",out)
    liq_save(ix$parameters,"A04_LSI_training_parameters",out)
    liq_save(ix$weights,"A05_LSI_weights",out)
    liq_save(pr$thresholds,"A06_asset_thresholds",out)
    liq_save(pr$regime_cuts,"A07_regime_thresholds",out)
    liq_save(liq_feature_spec(),"A08_feature_timestamp_specification",out)
    liq_save(liq_model_spec(cfg),"A09_full_model_specification",out)
    liq_save(cand$tuning,"A10_forward_tuning",out)
    liq_save(cand$inner,"A11_inner_time_boundaries",out)
    if(!is.null(inner_bundle)) {
      liq_save(inner_bundle$audit,"A21_nested_daily_fold_audit",out)
      liq_save(inner_bundle$parameters,"A22_inner_LSI_parameters",out)
      liq_save(inner_bundle$thresholds,"A23_inner_event_thresholds",out)
    }
    liq_save(cand$diagnostics,"A13_model_status",out)
    liq_save(liq_calibration_status(cand,cfg),"A25_calibration_status",out)
    liq_save(cand$combiner$weights,"A26_TRAIN_combination_weights",out)
    liq_save(cand$combiner$tuning,"A27_TRAIN_combination_tuning",out)
    liq_save(cand$combiner$audit,"A28_TRAIN_combination_fold_audit",out)
    liq_save(cand$combiner$fold_loss,"A29_TRAIN_combination_fold_losses",out)
    liq_save(heads$gate,"A30_GUARD_probability_gate",out)
    liq_save(liq_saturation(ix$panel,ix$parameters,fold),"A31_TRAIN_bound_saturation",out)
    liq_save(liq_coefficients(cand,cfg$horizons),"A14_model_coefficients",out)
    if(cand$fits$Cox$type=="cox"&&!is.null(cand$fits$Cox$PH$table)) {
      z<-as.data.table(cand$fits$Cox$PH$table,keep.rownames="term")
      liq_save(z,"A15_Cox_proportional_hazards_diagnostic",out)
    }
    liq_save(liq_duration_diagnostics(blocks$TEST,heads$test,cfg,heads$rank_names,blocks$TRAIN),
             "A16_secondary_duration_diagnostics",out)
    reg<-lapply(unique(blocks$TEST$regime),function(r){
      ii<-which(blocks$TEST$regime==r);z<-liq_evaluate(blocks$TEST[ii],lapply(heads$test,function(p)p[ii,,drop=FALSE]),cfg,heads$rank_names)
      z[,regime:=r];z})
    liq_save(liq_bind(reg),"A17_within_regime_performance",out)
    te<-blocks$TEST
    economic_baselines<-liq_bind(lapply(cfg$horizons,function(h){y<-liq_truth(te,h)$y
      data.table(horizon=h,cost_ratio=cfg$cost_ratios,always_resume=cfg$cost_ratios*mean(1-y),always_cautious=mean(y))}))
    liq_save(economic_baselines,"A18_fixed_action_costs",out)
    if(inference) {
      liq_save(result$inference$intervals,"T09_performance_confidence_intervals",out)
      liq_save(result$inference$differences,"T10_paired_model_differences",out)
      liq_save(result$reliability,"T11_reliability_with_block_bands",out)
      liq_save(result$km$curves,"T12_KM_curves_and_risk_counts",out)
      liq_save(result$km$contrasts,"T13_regime_contrasts",out)
      saveRDS(result$inference$samples,file.path(out,"objects","bootstrap_draws.rds"))
      saveRDS(result$inference$weights,file.path(out,"objects","bootstrap_event_weights.rds"))
      liq_figures(result,cfg,out)
    }
    stored<-if(isTRUE(cfg$save_large_objects))result else list(point=pt,blocks=blocks,
      fits=cand$fits,maps=cand$maps,checks=checks,choices=heads$choices,weights=heads$weights)
    liq_save_rds_atomic(stored,file.path(out,"objects","outer_experiment.rds"))
  }
  result
}




# -------------------- Completed runners, checkpointing and diagnostics --------
liq_fold_on_calendar <- function(calendar,fractions=c(.55,.70,.85)) {
  ix<-floor(length(calendar)*fractions)
  data.frame(role=c("TRAIN","CAL_FIT","GUARD","TEST"),
    from=calendar[c(1L,ix+1L)],to=calendar[c(ix,length(calendar))])
}
liq_artifacts <- function(path) {
  ff<-list.files(path,recursive=TRUE,full.names=TRUE)
  ff<-ff[!grepl("^checkpoint[.]rds([.]tmp)?$",basename(ff)) & !dir.exists(ff)]
  if(!length(ff))return(data.table(file=character(),md5=character()))
  relative<-substring(ff,nchar(path)+2L)
  data.table(file=relative,md5=unname(tools::md5sum(ff)))
}
liq_artifacts_valid <- function(path,stored) {
  if(is.null(stored))return(FALSE)
  if(!nrow(stored))return(TRUE)
  ff<-file.path(path,stored$file)
  all(file.exists(ff)) && all(unname(tools::md5sum(ff))==stored$md5)
}
liq_task_manager <- function(cfg,data_id) {
  status<-list();base<-liq_dir(file.path(cfg$out_dir,"tasks"))
  run<-function(id,kind,work,signature=list()) {
    path<-liq_dir(file.path(base,id));receipt<-file.path(path,"checkpoint.rds")
    source_identity<-liq_source_identity(cfg)
    implementation<-source_identity$hash
    runtime<-list(R=R.version.string,packages=vapply(c("data.table","glmnet","survival"),
      function(p)as.character(utils::packageVersion(p)),character(1)))
    key<-liq_hash(list(version=cfg$version,implementation=implementation,runtime=runtime,
      data=data_id,id=id,kind=kind,signature=signature))
    previous<-if(file.exists(receipt))tryCatch(readRDS(receipt),error=function(e)NULL)else NULL
    if(!is.null(previous)&&identical(previous$key,key)&&identical(previous$status,"completed")&&
       liq_artifacts_valid(path,previous$artifacts)) {
      liq_log("Resume",id)
      status[[id]]<<-data.table(task=id,kind=kind,status="completed",resumed=TRUE,reason="",warnings=previous$warnings)
      liq_save(liq_bind(status),"RUN_STATUS",cfg$out_dir)
      return(previous$value)
    }
    if(length(list.files(path,all.files=TRUE,no..=TRUE))) {
      archive<-tempfile(paste0(id,"_"),tmpdir=liq_dir(file.path(cfg$out_dir,"superseded")))
      liq_assert(file.rename(path,archive),paste("Cannot preserve previous task outputs:",id))
      liq_dir(path)
    }
    liq_log("Start",id);warn<-character();started<-Sys.time()
    value<-tryCatch(withCallingHandlers(work(path),warning=function(w) {
      warn<<-unique(c(warn,conditionMessage(w)));invokeRestart("muffleWarning")
    }),error=function(e)e)
    if(inherits(value,"error")) {
      state<-if(inherits(value,"liq_insufficient_sample"))"insufficient_sample"else"failed"
      status[[id]]<<-data.table(task=id,kind=kind,status=state,resumed=FALSE,
        reason=conditionMessage(value),warnings=paste(warn,collapse=" | "))
      writeLines(conditionMessage(value),file.path(path,"ERROR.txt"))
      liq_log(state,id,conditionMessage(value));value<-NULL
    } else {
      record<-list(key=key,status="completed",value=value,completed=Sys.time(),
        implementation=implementation,source_identity=source_identity,runtime=runtime,artifacts=liq_artifacts(path),warnings=paste(warn,collapse=" | "))
      temp<-paste0(receipt,".tmp");saveRDS(record,temp)
      liq_assert(file.rename(temp,receipt),paste("Cannot commit checkpoint:",id))
      status[[id]]<<-data.table(task=id,kind=kind,status="completed",resumed=FALSE,reason="",
        warnings=paste(warn,collapse=" | "))
      liq_log("Completed",id,"in",round(as.numeric(difftime(Sys.time(),started,units="secs")),1),"seconds")
    }
    liq_save(liq_bind(status),"RUN_STATUS",cfg$out_dir)
    value
  }
  list(run=run,status=function()liq_bind(status))
}

liq_economic_report <- function(result,cfg) {
  e<-result$blocks$TEST;pred<-result$heads$test;weights<-result$inference$weights
  ans<-list();i<-0L
  for(m in setdiff(names(pred),result$heads$rank_names))for(j in seq_along(cfg$horizons)) {
    y<-liq_truth(e,cfg$horizons[j])$y;p<-pred[[m]][,j]
    for(r in cfg$cost_ratios) {
      action<-p>=r/(1+r);loss<-r*action*(1-y)+(1-action)*y
      for(baseline in c("always_resume","always_cautious")) {
        reference<-if(baseline=="always_resume")r*(1-y)else y
        delta<-loss-reference
        sampled<-colSums(weights*delta)/colSums(weights);sampled[colSums(weights)==0]<-NA_real_
        iv<-liq_interval(sampled);i<-i+1L
        ans[[i]]<-data.table(model=m,horizon=cfg$horizons[j],cost_ratio=r,reference=baseline,
          mean_cost=mean(loss),cost_difference=mean(delta),lower=iv[1],upper=iv[2],valid=iv[3],
          interpretation="scenario loss, not realized trading profit; negative differences favor model")
      }
    }
  }
  liq_bind(ans)
}
liq_event_coverage <- function(e,calendar,cfg) {
  train_end<-cfg$fold$to[cfg$fold$role=="TRAIN"]
  # Align measurement/tuning windows through this table rather than event quantiles.
  liq_bind(lapply(cfg$horizons,function(h) {
    tr<-liq_truth(e,h)
    data.table(role=e$role,eligible=e$analysis_eligible,known=tr$known,y=tr$y)[,
      .(n_origins=.N,n_known=sum(known),positive=sum(y[known]),negative=sum(1-y[known])),
      by=.(role,eligible)][,horizon:=h]
  }))
}
liq_simulated_events <- function(cfg,scenario,replication) {
  # A declared confirmation-time DGP. Shared calendar shocks induce overlapping
  # outcome dependence. This DGP does not model order-book liquidity.
  set.seed(cfg$seed+replication)
  n<-max(700L,cfg$simulation_days);A<-cfg$simulation_assets
  calendar<-seq(as.Date("2005-01-03"),by="day",length.out=ceiling(n*1.5))
  calendar<-calendar[as.POSIXlt(calendar)$wday%in%1:5][seq_len(n)]
  fold<-liq_fold_on_calendar(calendar);train_end<-fold$to[1]
  common<-as.numeric(stats::arima.sim(list(ar=.90),n=n+cfg$max_h))
  common<-common*sqrt(1-.90^2);time_noise<-rnorm(n+cfg$max_h)
  origin<-seq.int(80L,n-1L,by=5L);asset_effect<-rnorm(A,0,.25)
  cuts<-c(-.5,.5);rows<-list();oracle<-list();z<-0L
  for(t in origin)for(a in seq_len(A)) {
    z<-z+1L;x<-rnorm(1);market<-common[t];shifted<-calendar[t]>train_end
    beta<-if(scenario=="no_regime")0 else .75
    if(scenario=="regime_reversal"&&shifted)beta<- -.75
    offset<-if(scenario=="prevalence_shift"&&shifted)1.1 else 0
    rho<-if(scenario=="strong_dependence").9 else .55
    days<-seq_len(cfg$max_h)
    effect_x<-if(scenario=="non_PH")ifelse(days<=10,.9,-.9)else rep(.65,length(days))
    hazard<-plogis(qlogis(.045)+effect_x*x+beta*market+asset_effect[a]+offset)
    hazard[days<cfg$k]<-0
    uniform<-pnorm(rho*time_noise[t+days]+sqrt(1-rho^2)*rnorm(length(days)))
    hit<-which(uniform<hazard);follow<-min(cfg$max_h,n-t)
    duration<-if(length(hit)&&hit[1]<=follow)hit[1]else follow
    recovered<-as.integer(length(hit)>0&&hit[1]<=follow)
    e<-as.data.table(setNames(rep(list(0),length(liq_feature_names())),liq_feature_names()))
    e[,`:=`(lsi=2+abs(x),lsi_lag1=1+abs(x),lsi_mom5=x,shock_severity_pct=pnorm(x),
      abs_ret=abs(rnorm(1,.01,.005)),absret5=.01,rv5=.0001,
      range_pct=.02+abs(x)*.005,volume_shock=-x,pressure=pmax(x,0)*.02,
      log_dvol=16+x*.2,market_loo=market,market_loo_lag1=common[t-1L],market_full=market,
      market_trend5=market-common[t-5L],market_percentile=pnorm(market),
      shock_cluster_share=plogis(market),shock_cluster_share_lag1=plogis(common[t-1L]),
      volume_breadth_lag1=plogis(common[t-1L]),avg_corr_lag1=.3,vix_lag1=20+3*market,
      vix_change5=3*(market-common[t-5L]),is_stock=as.numeric(a>A/2),is_sector=as.numeric(a<=A/2),
      event_id=paste0("SIM_",replication,"_",t,"_",a),asset=paste0("A",a),
      shock_date=calendar[t],sid=t,duration=as.integer(duration),status=recovered,
      followup=as.integer(follow),planned_end=if(t+cfg$max_h<=n)calendar[t+cfg$max_h]else as.Date(NA),
      observed_end=calendar[t+follow],role="OUTSIDE",analysis_eligible=FALSE,
      confirmation_day=if(recovered)duration else NA_integer_,
      recovery_start_day=if(recovered)duration-cfg$k+1L else NA_integer_,
      censor_reason=if(recovered)"recovered"else if(follow==cfg$max_h)"Hmax"else"data_end")]
    for(j in seq_len(nrow(fold)))if(calendar[t]>=fold$from[j]&&calendar[t]<=fold$to[j]) {
      e[,role:=fold$role[j]]
      e[,analysis_eligible:=!is.na(planned_end)&&planned_end<=fold$to[j]&&followup>=cfg$max_h]
    }
    e[,regime:=if(market<=cuts[1])"Low"else if(market<=cuts[2])"Normal"else"High"]
    rows[[z]]<-e
    oracle[[z]]<-data.table(event_id=e$event_id,horizon=cfg$horizons,
      true_probability=(1-cumprod(1-hazard))[cfg$horizons])
  }
  e<-liq_bind(rows)
  # The observed regime boundaries are TRAIN-only, regardless of true DGP effects.
  q<-quantile(e[role=="TRAIN" & analysis_eligible==TRUE,market_loo],cfg$regime_quantiles)
  e[,regime:=ifelse(market_loo<=q[1],"Low",ifelse(market_loo<=q[2],"Normal","High"))]
  list(events=e,oracle=liq_bind(oracle),calendar=calendar,fold=fold,
    scenario=scenario,replication=replication,
    dgp_context=list(asset_effect=asset_effect,regime_cuts=q,scenario=scenario,seed=cfg$seed+replication))
}
liq_run_simulation <- function(cfg,run) {
  all<-coverage<-batch<-list();k<-0L
  for(scenario in cfg$simulation_scenarios)for(replication in seq_len(cfg$simulation_reps)) {
    id<-sprintf("simulation_%s_%03d",scenario,replication)
    value<-run(id,"simulation",function(path) {
      d<-liq_simulated_events(cfg,scenario,replication);e<-d$events
      bb<-lapply(c("TRAIN","CAL_FIT","GUARD","TEST"),function(r)e[role==r&analysis_eligible==TRUE])
      names(bb)<-c("TRAIN","CAL_FIT","GUARD","TEST")
      liq_require_simulation_support(e,bb,cfg)
      cand<-liq_candidates(bb$TRAIN,bb$CAL_FIT,bb$GUARD,bb$TEST,cfg)
      hd<-liq_heads(cand,bb$GUARD,cfg)
      pt<-liq_evaluate(bb$TEST,hd$test,cfg,hd$rank_names)
      pt[,`:=`(scenario=scenario,replication=replication)]
      liq_save(pt,"performance",path)
      liq_save(e,"events",path);liq_save(d$oracle,"oracle_probabilities",path)
      liq_save(cand$tuning,"forward_tuning",path);liq_save(cand$inner,"inner_time_boundaries",path)
      liq_save(cand$fits$Correction$tuning,"correction_TRAIN_tuning",path)
      liq_save(cand$fits$Correction$audit,"correction_forward_audit",path)
      bi<-liq_batch_pairs(bb$TEST,hd$test,cfg,d$calendar,hd$choices,cand$fits$Correction)
      bi[,`:=`(scenario=scenario,replication=replication)]
      liq_save(bi,"calendar_batch_paired_intervals",path)
      # Conditional Brier interval coverage for the same fitted prediction rules.
      cv<-list();tests<-intersect(c("LIQ_Brier","Logit_cal","Regime_cal"),names(hd$test))
      for(crossed in c(FALSE,TRUE)) {
      method<-if(crossed)"crossed_asset_date"else"date_block"
      w<-liq_boot_weights(bb$TEST,d$calendar,if(cfg$mode=="smoke")39L else 199L,
                          cfg$block_length,cfg$seed+replication+if(crossed)10000L else 0L,crossed=crossed)
      for(j in seq_along(cfg$horizons)) {
        h<-cfg$horizons[j];q<-d$oracle[horizon==h]$true_probability[match(bb$TEST$event_id,d$oracle[horizon==h]$event_id)]
        y<-liq_truth(bb$TEST,h)$y;ref<-hd$test$Regime_cal[,j]
        for(m in tests) {
          p<-hd$test[[m]][,j];loss<-(p-y)^2-(ref-y)^2
          exact<-mean((p-q)^2-(ref-q)^2)
          draw<-colSums(w*loss)/colSums(w);iv<-liq_interval(draw)
          cv[[length(cv)+1L]]<-data.table(scenario=scenario,replication=replication,model=m,
            horizon=h,method=method,true_conditional_delta_Brier=exact,estimate=mean(loss),lower=iv[1],upper=iv[2],
            identical_output=identical(as.numeric(p),as.numeric(ref)),
            eligible_for_coverage=!identical(as.numeric(p),as.numeric(ref)),
            covered=if(!identical(as.numeric(p),as.numeric(ref))&&all(is.finite(iv[1:2])))iv[1]<=exact&&iv[2]>=exact else NA,
            interpretation="Monte Carlo diagnostic for conditional expected loss; fixed fitted forecasts")
        }
      }
      }
      cv<-liq_bind(cv);liq_save(cv,"conditional_interval_coverage",path)
      saveRDS(list(fits=cand$fits,maps=cand$maps,heads=hd$choices),file.path(path,"fitted_models.rds"))
      list(point=pt,coverage=cv,batch=bi)
    },signature=list(scenario=scenario,replication=replication,cfg=cfg))
    if(!is.null(value)) {k<-k+1L;all[[k]]<-value$point;coverage[[k]]<-value$coverage;batch[[k]]<-value$batch}
  }
  if(length(all)) {
    d<-liq_bind(all);liq_save(d,"S01_all_simulation_replications",cfg$out_dir)
    fields<-intersect(c("Brier","AUC","BSS_historical","log_loss"),names(d))
    ll<-melt(d,id.vars=c("scenario","replication","model","horizon"),measure.vars=fields,
             variable.name="metric",value.name="value")
    summary<-ll[,.(n_completed=sum(is.finite(value)),mean=liq_mean(value),
      mc_se=if(sum(is.finite(value))>1)sd(value[is.finite(value)])/sqrt(sum(is.finite(value)))else NA_real_),
      by=.(scenario,model,horizon,metric)]
    liq_save(summary,"S02_simulation_summary",cfg$out_dir)
    cv<-liq_bind(coverage)
    liq_save(cv,"S03_interval_coverage_replications",cfg$out_dir)
    liq_save(cv[,.(n_total=.N,excluded_identity=sum(identical_output),n_completed=sum(!is.na(covered)),
      coverage=if(any(!is.na(covered)))mean(covered,na.rm=TRUE)else NA_real_,
      mc_se=if(sum(!is.na(covered))>1L)sqrt(mean(covered,na.rm=TRUE)*(1-mean(covered,na.rm=TRUE))/sum(!is.na(covered)))else NA_real_),
      by=.(scenario,model,horizon,method)],"S04_interval_coverage_summary",cfg$out_dir)
  }
  if(length(batch)) {
    bd<-liq_bind(batch);liq_save(bd,"S05_calendar_batch_paired_intervals",cfg$out_dir)
    liq_save(bd[,.(n_total=.N,n_algebraic=sum(algebraic_identity),
      n_stochastic_supported=sum(supported&!algebraic_identity),n_abstained=sum(!supported)),
      by=.(scenario,model,reference,metric,horizon)],"S06_calendar_batch_support_summary",cfg$out_dir)
  }
  invisible(TRUE)
}
liq_run_extended <- function(features,calendar,cfg,primary,run) {
  fit_case<-function(id,kind,cc=cfg,fold=cfg$fold,variant="equal",regime=cfg$regime_source,
                    nonoverlap=FALSE,ff=features,index=NULL,rolling_role=NA_character_) {
    run(id,kind,function(path) {
      value<-liq_outer(ff,calendar,cc,fold,variant,nonoverlap,regime,out=path,prepared_index=index)
      liq_save(liq_event_coverage(value$problem$events,calendar,cc),"A20_endpoint_counts",path)
      z<-value$point;z[,`:=`(design=id,rolling_role=rolling_role)]
      list(point=z,events=nrow(value$problem$events),test_long=value$long)
    },signature=list(cfg=cc,fold=fold,variant=variant,regime=regime,nonoverlap=nonoverlap,
                     assets=sort(unique(ff$asset)),rolling_role=rolling_role))
  }
  summaries<-list();rolling<-list()
  add<-function(x)if(!is.null(x))summaries[[length(summaries)+1L]]<<-x$point
  if(cfg$run_panel_checks) {
    add(fit_case("nonoverlap","nonoverlap",nonoverlap=TRUE,index=primary$index))
    for(rg in c("market_full","market_loo_lag1","vix_lag1"))
      add(fit_case(paste0("regime_",rg),"regime",regime=rg,index=primary$index))
    reference<-intersect(cfg$reference_symbols,unique(features$asset))
    if(length(reference)>=cfg$corr_min_assets&&!setequal(reference,unique(features$asset))) {
      cc<-cfg;cc$symbols<-reference;cc$universe_name<-"declared_baseline29_reference"
      add(fit_case("baseline29_reference_panel","panel",cc=cc,ff=features[asset%in%reference]))
    }
    inventory<-features[,.(first=if(any(observed))min(date[observed])else as.Date(NA),
      last=if(any(observed))max(date[observed])else as.Date(NA)),by=asset]
    keep<-inventory[!is.na(first)&first<=min(calendar)+30L&last>=max(calendar)-30L,asset]
    liq_save(data.table(asset=unique(features$asset),common_history=unique(features$asset)%in%keep),
             "P01_common_history_members",cfg$out_dir)
    if(length(keep)>=cfg$corr_min_assets)add(fit_case("common_history_panel","panel",ff=features[asset%in%keep]))
  }
  if(cfg$run_ablations) {
    variants<-if(cfg$mode=="smoke")c("omit_1","relative_dvol")else
      c(paste0("omit_",1:5),"relative_dvol","volume_only","redundancy_weighted")
    for(v in variants)add(fit_case(paste0("index_",v),"index",variant=v))
  }
  if(cfg$run_sensitivity) {
    grid<-liq_design_grid();liq_save(grid,"G01_complete_81_design_grid",cfg$out_dir)
    selected<-if(cfg$mode=="smoke")unique(c(1L,nrow(grid)))else seq_len(nrow(grid))
    for(j in selected) {
      cc<-cfg;cc$shock_q<-grid$shock_q[j];cc$recovery_q<-grid$recovery_q[j]
      cc$k<-grid$k[j];cc$max_h<-grid$max_h[j];cc$horizons<-cfg$horizons[cfg$horizons<=cc$max_h]
      add(fit_case(grid$design[j],"sensitivity",cc=cc,index=primary$index))
    }
  }
  if(cfg$run_rolling) {
    schedule<-liq_rolling_schedule(calendar,cfg);liq_save(schedule,"R01_rolling_schedule",cfg$out_dir)
    if(!nrow(schedule))run("rolling_unavailable","rolling",function(path)
      liq_need(FALSE,paste("Insufficient rolling calendar:",length(calendar),"sessions; need",cfg$rolling_span)),
      signature=list(cfg=cfg,calendar_length=length(calendar)))
    selected<-if(cfg$mode=="smoke")tail(seq_len(nrow(schedule)),2L)else seq_len(nrow(schedule))
    for(j in selected) {
      cal<-calendar[schedule$first_sid[j]:schedule$last_sid[j]]
      fold<-liq_fold_on_calendar(cal,cfg$rolling_fractions)
      id<-schedule$design[j]
      value<-fit_case(id,"rolling",fold=fold,rolling_role=schedule$rolling_role[j])
      add(value)
      if(!is.null(value))rolling[[id]]<-value
    }
    liq_rolling_report(rolling,primary,cfg)
  }
  if(length(summaries))liq_save(liq_bind(summaries),"G02_all_completed_extended_results",cfg$out_dir)
  for(L in setdiff(cfg$block_grid,cfg$block_length))run(paste0("inference_date_L",L),"inference",function(path) {
    z<-liq_inference(primary$blocks$TEST,primary$heads$test,primary$heads$choices,cfg,calendar,
      primary$heads$rank_names,B=cfg$boot_robust_reps,L=L)
    liq_save(z$intervals,"intervals",path);liq_save(z$differences,"paired_differences",path)
    list(method=z$method,rows=nrow(z$intervals))
  },signature=list(cfg=cfg,L=L))
  run("inference_crossed_asset_date","inference",function(path) {
    z<-liq_inference(primary$blocks$TEST,primary$heads$test,primary$heads$choices,cfg,calendar,
      primary$heads$rank_names,B=cfg$boot_robust_reps,crossed=TRUE)
    liq_save(z$intervals,"intervals",path);liq_save(z$differences,"paired_differences",path)
    list(method=z$method,rows=nrow(z$intervals))
  },signature=list(cfg=cfg,crossed=TRUE))
  invisible(TRUE)
}

liq_validate_config <- function(cfg) {
  liq_assert(nrow(cfg$fold)==4L && all(c("TRAIN","CAL_FIT","GUARD","TEST")%in%cfg$fold$role) && !anyDuplicated(cfg$fold$role),"Exactly four unique roles are required.")
  liq_assert(!anyNA(cfg$fold$from)&&!anyNA(cfg$fold$to),"Missing role dates.")
  liq_assert(length(cfg$horizons)>0L && all(is.finite(cfg$horizons)) && all(cfg$horizons==as.integer(cfg$horizons)) &&
    all(cfg$horizons>0L & cfg$horizons<=cfg$max_h) && !is.unsorted(cfg$horizons,strictly=TRUE),"Horizons must be unique increasing positive integers no greater than Hmax.")
  liq_assert(cfg$recovery_q>0 && cfg$shock_q<1 && cfg$recovery_q<cfg$shock_q,"Require 0 < recovery quantile < shock quantile < 1.")
  liq_assert(cfg$k>=1L && cfg$k<=cfg$max_h && cfg$k==as.integer(cfg$k),"Invalid recovery confirmation length.")
  liq_assert(is.finite(cfg$dt_threads)&&cfg$dt_threads>=1L,"LIQ_THREADS must be a positive integer.")
  liq_assert(length(cfg$mix_eta_grid)>0L&&all(cfg$mix_eta_grid>=0),"Invalid TRAIN mixture eta grid.")
  liq_assert(length(cfg$mix_shrink_grid)>0L&&all(cfg$mix_shrink_grid>=0&cfg$mix_shrink_grid<=1),"Invalid TRAIN shrinkage grid.")
  liq_assert(cfg$rolling_span>cfg$max_h&&cfg$rolling_step>0&&length(cfg$rolling_fractions)==3L&&
    all(diff(cfg$rolling_fractions)>0)&&all(cfg$rolling_fractions>0&cfg$rolling_fractions<1),"Invalid rolling schedule.")
  liq_assert(length(cfg$lambda_grid)>0L && all(is.finite(cfg$lambda_grid)&cfg$lambda_grid>0),"Lambda grid must be positive and finite.")
  liq_assert(cfg$boot_reps>=10L && cfg$boot_reps==as.integer(cfg$boot_reps) && cfg$boot_robust_reps>=10L,"Invalid bootstrap counts.")
  invisible(TRUE)
}
liq_main <- function(cfg=liq_config()) {
  liq_validate_config(cfg);liq_packages(cfg);liq_dir(cfg$out_dir);set.seed(cfg$seed)
  old_log<-getOption("liq.log.file");options(liq.log.file=file.path(cfg$out_dir,"run.log"))
  on.exit(options(liq.log.file=old_log),add=TRUE)
  source_identity<-liq_source_identity(cfg)
  liq_log("LIQ-REC",cfg$version,"output:",normalizePath(cfg$out_dir,winslash="/",mustWork=TRUE))
  liq_dir(file.path(cfg$out_dir,"source"))
  liq_assert(file.copy(source_identity$path,file.path(cfg$out_dir,"source",basename(source_identity$path)),overwrite=TRUE),"Cannot archive source file.")
  liq_save(as.data.table(source_identity),"D00_source_identity",cfg$out_dir)
  liq_assert(cfg$boot_reps>=10L,"Use at least 10 bootstrap draws (1999 in the full default).")
  liq_assert(all(diff(cfg$fold$from)>0)&all(cfg$fold$from<=cfg$fold$to),"Invalid role boundaries.")
  liq_assert(all(head(cfg$fold$to,-1)<tail(cfg$fold$from,-1)),"Roles overlap.")
  data<-liq_get_data(cfg);cfg<-data$cfg
  liq_universe_audit(data,cfg)
  set.seed(cfg$seed)
  liq_save(data$inventory,"D01_ticker_inventory",cfg$out_dir)
  liq_save(data$manifest,"D02_data_manifest",cfg$out_dir)
  liq_write_csv(data$raw,file.path(cfg$out_dir,"frozen_ohlcv.csv"))
  saveRDS(cfg,file.path(cfg$out_dir,"configuration.rds"))
  liq_save(as.data.table(cfg$fold),"D03_calendar_roles",cfg$out_dir)
  capture.output(utils::sessionInfo(),file=file.path(cfg$out_dir,"sessionInfo.txt"))
  features<-liq_raw_features(data$panel,cfg)
  data_id<-liq_hash(data$raw)
  saveRDS(list(version=cfg$version,data_hash=data_id,configuration_hash=liq_hash(cfg),
    historical_test_seen=TRUE,created_utc=format(Sys.time(),tz="UTC",usetz=TRUE),
    source_mode=cfg$data_mode,source_identity=source_identity,
    input_file_hash=if(cfg$data_mode=="csv")liq_hash_file(cfg$input_csv)else NA_character_),file.path(cfg$out_dir,"run_manifest.rds"))
  liq_save(liq_describe(features,c("ret","abs_ret","range_pct","log_dvol","volume_shock","amihud","cs_spread")),
           "D04_daily_descriptive_statistics",cfg$out_dir)
  preflight<-liq_preflight(features,data$calendar,cfg)
  if(isTRUE(cfg$preflight_only)) {
    writeLines(c("Preflight only: no prediction model fitted.",
      paste(sum(preflight$summary$count_and_class_supported),"of 81 designs pass role count/class checks.")),
      file.path(cfg$out_dir,"PREFLIGHT_SUMMARY.txt"))
    return(invisible(list(config=cfg,preflight=preflight$summary)))
  }
  manager<-liq_task_manager(cfg,data_id);run<-manager$run
  primary_info<-run("primary","primary",function(path) {
    cc<-cfg;cc$save_large_objects<-TRUE
    p<-liq_outer(features,data$calendar,cc,out=path,inference=TRUE)
    liq_save(liq_event_coverage(p$problem$events,data$calendar,cc),"A20_endpoint_counts",path)
    liq_save(liq_economic_report(p,cc),"T14_decision_cost_vs_fixed_actions",path)
    liq_save(liq_proxy_validation(p$index$panel,cc$fold),"D05_LSI_proxy_validation",path)
    liq_save(liq_describe(p$problem$events,c("duration","followup","lsi","market_loo"),group="role"),
             "D08_event_descriptive_statistics",path)
    liq_save(liq_context_report(p,cc),"D09_subperiod_context_performance",path)
    pp<-p$index$panel
    flow<-pp[,.(calendar_rows=.N,observed=sum(observed),valid_price=sum(valid_price),valid_volume=sum(valid_volume),
      lsi_available=sum(is.finite(lsi)),correlation_available=sum(is.finite(avg_corr_lag1)),
      first_lsi=if(any(is.finite(lsi)))min(date[is.finite(lsi)])else as.Date(NA),
      first_correlation=if(any(is.finite(avg_corr_lag1)))min(date[is.finite(avg_corr_lag1)])else as.Date(NA)),by=asset]
    liq_save(flow,"D06_daily_availability_waterfall",path)
    mat<-liq_x(p$blocks$TRAIN,liq_prep(p$blocks$TRAIN))
    corr<-as.data.table(cor(mat),keep.rownames="feature")
    liq_save(corr,"D07_TRAIN_feature_correlations",path)
    list(object=file.path(path,"objects","outer_experiment.rds"),point=p$point,
      events=nrow(p$problem$events),prediction_rows=nrow(p$long),checks=nrow(p$checks))
  },signature=list(cfg=cfg))
  if(is.null(primary_info))stop("Primary experiment failed. Read tables/RUN_STATUS.csv before proceeding.")
  primary<-readRDS(primary_info$object)
  liq_run_extended(features,data$calendar,cfg,primary,run)
  if(cfg$run_simulation)liq_run_simulation(cfg,run)
  if(isTRUE(cfg$publication_export))liq_publication_export(primary,cfg,cfg$out_dir)
  st<-manager$status()
  liq_save(st,"RUN_STATUS",cfg$out_dir)
  summary<-c(paste("LIQ-REC-Fin",cfg$version),paste("Data:",cfg$data_mode),
    paste("Completed:",sum(st$status=="completed"),"Insufficient sample:",sum(st$status=="insufficient_sample"),"Failed:",sum(st$status=="failed")),
    "Completed means software execution, not evidence of predictive superiority.",
    "Historical results are re-analysis. Public archival, literature revision, independent corporate-action",
    "verification, point-in-time universe evidence and sourced crisis labels remain separate tasks.",
    if(cfg$mode=="smoke")"SMOKE: synthetic/selected diagnostics do not constitute a full empirical run."else
      "FULL: inspect every task status, class count, CI and robustness result before manuscript claims.")
  writeLines(summary,file.path(cfg$out_dir,"RUN_SUMMARY.txt"))
  liq_log("Finished.",sum(st$status=="completed"),"completed;",sum(st$status=="insufficient_sample"),"insufficient;",sum(st$status=="failed"),"failed.")
  invisible(list(config=cfg,status=st,primary=primary_info))
}
liq_context_report <- function(primary,cfg) {
  e<-primary$blocks$TEST;pred<-primary$heads$test;out<-list()
  periods<-data.table(label=sort(unique(format(e$shock_date,"%Y"))))
  for(label in periods$label) {
    ii<-which(format(e$shock_date,"%Y")==label)
    z<-liq_evaluate(e[ii],lapply(pred,function(p)p[ii,,drop=FALSE]),cfg,primary$heads$rank_names)
    z[,`:=`(context=label,source="calendar year; descriptive subperiod",context_type="calendar")]
    out[[length(out)+1L]]<-z
  }
  if(nzchar(cfg$context_file)) {
    d<-data.table::fread(cfg$context_file)
    liq_assert(all(c("label","start_date","end_date","source")%in%names(d)),
      "Context input requires label,start_date,end_date,source.")
    liq_assert(all(nzchar(d$source)),"Each contextual window needs a source; no inferred crisis labels.")
    for(j in seq_len(nrow(d))) {
      ii<-which(e$shock_date>=as.Date(d$start_date[j])&e$shock_date<=as.Date(d$end_date[j]))
      if(!length(ii))next
      z<-liq_evaluate(e[ii],lapply(pred,function(p)p[ii,,drop=FALSE]),cfg,primary$heads$rank_names)
      z[,`:=`(context=d$label[j],source=d$source[j],context_type="provided window; non-causal")]
      out[[length(out)+1L]]<-z
    }
  }
  liq_bind(out)
}


# New 4.6.0 functions. Merged into the standalone release by build_release.py.
liq_numeric_schema <- function(raw) {
  raw<-liq_dt(raw)
  required<-c("date","asset","open","high","low","close","adjusted","volume")
  liq_assert(all(required%in%names(raw)),"OHLCV schema is incomplete.")
  for(nm in c("open","high","low","close","adjusted","volume")) {
    before<-raw[[nm]]
    if(inherits(before,"integer64")) {
      liq_assert(requireNamespace("bit64",quietly=TRUE),
        "An integer64 OHLCV column requires bit64 for safe decoding; reload through liq_read_ohlcv().")
      before<-as.character(before)
    }
    if(is.factor(before))before<-as.character(before)
    after<-suppressWarnings(as.numeric(before))
    liq_assert(!any(!is.na(before)&is.na(after)),paste("Unparseable numeric input:",nm))
    liq_assert(!any(is.infinite(after)),paste("Infinite OHLCV input:",nm))
    if(nm=="volume") {
      liq_assert(all(abs(after[is.finite(after)])<2^53),
        "Volumes >= 2^53 are rejected before arithmetic; supply exact supported counts.")
      liq_assert(all(after[is.finite(after)]==trunc(after[is.finite(after)])),
        "Volume must contain integral share/unit counts; verify provider units.")
    }
    data.table::set(raw,j=nm,value=after)
  }
  raw[,asset:=as.character(asset)]
  liq_assert(!anyNA(raw$asset)&&all(nzchar(raw$asset)),"Missing asset identifiers.")
  raw
}
liq_read_ohlcv <- function(path) {
  # Explicit volume type also covers rare int32 overflows outside fread's sample.
  # Older data.table versions can otherwise widen this column to integer64 on reread.
  liq_numeric_schema(data.table::fread(file=path,colClasses=c(volume="character"),integer64="character"))
}

liq_source_identity <- function(cfg=NULL) {
  path<-if(!is.null(cfg)&&!is.null(cfg$source_path))cfg$source_path else LIQ_SOURCE_PATH
  liq_assert(length(path)==1L&&nzchar(path)&&file.exists(path),
    "Source R file required for provenance. Save the .R file and run source(file), not a pasted console body.")
  path<-normalizePath(path,winslash="/",mustWork=TRUE)
  list(path=path,hash=liq_hash_file(path),md5=unname(tools::md5sum(path)),
       algorithm=if(requireNamespace("digest",quietly=TRUE))"sha256"else"md5",scope="entire source file bytes")
}

liq_class_support <- function(e,cfg,roles=c("TRAIN","CAL_FIT","GUARD","TEST")) {
  out<-list();k<-0L
  for(r in roles)for(h in cfg$horizons) {
    d<-e[role==r&analysis_eligible==TRUE];y<-liq_truth(d,h)$y
    pos<-is.finite(y)&y==1L;neg<-is.finite(y)&y==0L
    k<-k+1L
    out[[k]]<-data.table(role=r,horizon=h,n_events=nrow(d),positive=sum(pos),negative=sum(neg),
      n_assets=uniqueN(d$asset),n_dates=uniqueN(d$shock_date),
      positive_assets=uniqueN(d$asset[pos]),negative_assets=uniqueN(d$asset[neg]),
      positive_dates=uniqueN(d$shock_date[pos]),negative_dates=uniqueN(d$shock_date[neg]),
      class_supported=min(sum(pos),sum(neg))>=cfg$min_class,
      inference_fragile=min(sum(pos),sum(neg))<cfg$min_class ||
        min(uniqueN(d$shock_date[pos]),uniqueN(d$shock_date[neg]))<10L ||
        min(uniqueN(d$asset[pos]),uniqueN(d$asset[neg]))<5L,
      diagnostic="fragility flag is descriptive, not a validity theorem")
  }
  liq_bind(out)
}

liq_design_grid <- function() {
  z<-data.table::CJ(shock_q=c(.85,.90,.95),recovery_q=c(.50,.60,.70),k=c(2L,3L,5L),max_h=c(20L,30L,45L))
  z[,design:=sprintf("sensitivity_%03d",.I)];z
}

liq_preflight <- function(features,calendar,cfg,out=cfg$out_dir) {
  # No TEST data, labels or performance enter this feasibility calculation.
  last<-max(cfg$fold$to[cfg$fold$role%in%c("TRAIN","CAL_FIT","GUARD")])
  cal<-calendar[calendar<=last]
  ix<-liq_index(features[date<=last],cfg,cfg$fold)
  panel<-ix$panel;grid<-liq_design_grid();rows<-list();i<-0L
  origins<-new.env(parent=emptyenv());runs<-new.env(parent=emptyenv())
  roles<-cfg$fold[cfg$fold$role%in%c("TRAIN","CAL_FIT","GUARD"),]
  for(j in seq_len(nrow(grid))) {
    cc<-cfg;cc$shock_q<-grid$shock_q[j];cc$recovery_q<-grid$recovery_q[j]
    cc$k<-grid$k[j];cc$max_h<-grid$max_h[j];cc$horizons<-cfg$horizons[cfg$horizons<=cc$max_h]
    records<-list()
    for(a in unique(panel$asset)) {
      d<-panel[asset==a][order(sid)];x<-d$lsi;n<-nrow(d)
      ref<-x[d$date>=cfg$fold$from[1]&d$date<=cfg$fold$to[1]&d$member&is.finite(x)]
      if(length(ref)<cfg$min_daily_train)next
      key<-paste(a,cc$shock_q,sep="_")
      if(!exists(key,origins,inherits=FALSE)) {
        eligible<-which(is.finite(x)&d$member&x>as.numeric(quantile(ref,cc$shock_q)))
        starts<-integer(length(eligible));z<-0L;last_i<- -Inf
        for(v in eligible)if(v>last_i+cc$min_gap){z<-z+1L;starts[z]<-v;last_i<-v}
        assign(key,starts[seq_len(z)],origins)
      }
      starts<-get(key,origins,inherits=FALSE)
      key2<-paste(a,cc$recovery_q,cc$k,sep="_")
      if(!exists(key2,runs,inherits=FALSE)) {
        below<-is.finite(x)&d$member&x<=as.numeric(quantile(ref,cc$recovery_q))
        cs<-c(0L,cumsum(below));kk<-cc$k
        hit<-which(cs[(kk+1L):(n+1L)]-cs[seq_len(n-kk+1L)]==kk)+kk-1L
        bad<-c(which(!is.finite(x)|!d$member),n+1L)
        assign(key2,list(hit=hit,bad=bad),runs)
      }
      rr<-get(key2,runs,inherits=FALSE)
      next_bad<-rr$bad[findInterval(starts,rr$bad)+1L]
      follow<-pmin(cc$max_h,n-starts,next_bad-starts-1L)
      next_hit<-findInterval(starts+cc$k-1L,rr$hit)+1L
      confirm<-rep(NA_integer_,length(starts));has<-next_hit<=length(rr$hit)
      confirm[has]<-rr$hit[next_hit[has]]-starts[has]
      confirm[is.finite(confirm)&confirm>follow]<-NA_integer_
      for(r in seq_len(nrow(roles))) {
        last_sid<-max(which(cal<=roles$to[r]))
        keep<-d$date[starts]>=roles$from[r]&d$date[starts]<=roles$to[r]&follow>=cc$max_h&d$sid[starts]+cc$max_h<=last_sid
        # Empty asset/role cells contribute zero records, never a recycled NA row.
        nk<-sum(keep)
        records[[length(records)+1L]]<-data.table(asset=rep(a,nk),shock_date=d$date[starts[keep]],
          role=rep(roles$role[r],nk),confirm=confirm[keep])
      }
    }
    ev<-liq_bind(records)
    for(r in roles$role)for(h in cc$horizons) {
      d<-ev[role==r];pos<-is.finite(d$confirm)&d$confirm<=h;neg<-!pos;i<-i+1L
      rows[[i]]<-data.table(design=grid$design[j],shock_q=cc$shock_q,recovery_q=cc$recovery_q,
        k=cc$k,max_h=cc$max_h,role=r,horizon=h,n_events=nrow(d),positive=sum(pos),negative=sum(neg),
        n_assets=uniqueN(d$asset),n_dates=uniqueN(d$shock_date),positive_assets=uniqueN(d$asset[pos]),
        negative_assets=uniqueN(d$asset[neg]),positive_dates=uniqueN(d$shock_date[pos]),negative_dates=uniqueN(d$shock_date[neg]))
    }
  }
  detail<-liq_bind(rows)
  minimum<-c(TRAIN=cfg$min_train,CAL_FIT=cfg$min_cal,GUARD=cfg$min_guard)
  detail[,count_supported:=n_events>=minimum[role]]
  detail[,class_supported:=role=="TRAIN"|pmin(positive,negative)>=cfg$min_class]
  summary<-detail[,.(role_count_supported=all(count_supported),
    CAL_class_supported=all(class_supported[role=="CAL_FIT"]),
    GUARD_class_supported=all(class_supported[role=="GUARD"]),
    count_and_class_supported=all(count_supported&class_supported),
    n_TRAIN=min(n_events[role=="TRAIN"]),n_CAL_FIT=min(n_events[role=="CAL_FIT"]),n_GUARD=min(n_events[role=="GUARD"]),
    CAL_min_class=min(c(positive[role=="CAL_FIT"],negative[role=="CAL_FIT"])),
    GUARD_min_class=min(c(positive[role=="GUARD"],negative[role=="GUARD"]))),by=.(design,shock_q,recovery_q,k,max_h)]
  liq_save(grid,"G01_complete_81_design_grid",out)
  liq_save(detail,"F01_preTEST_81_design_horizon_counts",out)
  liq_save(summary,"F02_preTEST_81_design_feasibility",out)
  liq_save(data.table(latest_data_used=max(cal),TEST_labels_used=FALSE,models_fitted=FALSE,
    eligible_designs=sum(summary$count_and_class_supported),total_designs=nrow(summary),
    criterion="role N minima plus >=min_class in both CAL/GUARD classes; not a model-success guarantee"),"F03_preflight_scope",out)
  liq_log("Preflight",sum(summary$count_and_class_supported),"/",nrow(summary),"designs pass count/class checks; no TEST labels used.")
  list(detail=detail,summary=summary,index=ix)
}

liq_saturation <- function(panel,parameters,fold) {
  d<-liq_dt(panel);d[,period:="OUTSIDE"]
  for(j in seq_len(nrow(fold)))d[date>=fold$from[j]&date<=fold$to[j],period:=fold$role[j]]
  out<-list()
  for(j in seq_len(nrow(parameters))) {
    z<-parameters[j];x<-d[asset==z$asset]
    x[,value:=get(z$component)]
    out[[j]]<-x[,{
      v<-value[is.finite(value)];nn<-length(v)
      .(n=nn,below_TRAIN_bound=sum(v<z$lower),above_TRAIN_bound=sum(v>z$upper),
        fraction_below=if(nn)mean(v<z$lower)else NA_real_,fraction_above=if(nn)mean(v>z$upper)else NA_real_,
        TRAIN_lower=z$lower,TRAIN_upper=z$upper,component=z$component)
    },by=.(asset,period)]
  }
  liq_bind(out)
}

liq_fixed_predictions <- function(train,valid,cfg,outer_fits) {
  # Penalties were selected wholly within outer TRAIN. These validation draws
  # tune the combiner; they are not an independent performance estimate.
  H<-cfg$horizons;prep<-liq_prep(train)
  out<-list(Historical_raw=liq_empirical(train,valid,H),Regime_raw=liq_empirical(train,valid,H,TRUE))
  lp<-tryCatch(do.call(cbind,lapply(seq_along(H),function(j) {
    y<-liq_truth(train,H[j])$y;ok<-is.finite(y);y<-y[ok]
    if(!length(prep$columns)||length(unique(y))<2L||min(table(y))<8L)
      return(rep((sum(y)+.5)/(length(y)+1),nrow(valid)))
    lambda<-outer_fits$Logit[[j]]$lambda
    if(is.null(lambda))lambda<-.03
    ff<-liq_glmnet_v480(liq_x(train,prep)[ok,,drop=FALSE],y,family="binomial",alpha=cfg$alpha_logit,
      lambda=sort(unique(c(cfg$lambda_grid,lambda)),decreasing=TRUE),standardize=FALSE)
    as.numeric(predict(ff,newx=liq_x(valid,prep),s=lambda,type="response"))
  })),error=function(e)NULL)
  if(!is.null(lp)&&all(is.finite(lp)))out$Logit_raw<-lp
  hp<-tryCatch({
    z<-liq_hazard_design(train,prep,cfg$max_h,TRUE);lambda<-outer_fits$Hazard$lambda
    if(is.null(lambda))lambda<-.03
    if(length(unique(z$y))<2L||min(table(z$y))<8L) {
      ff<-list(type="constant",p=(sum(z$y)+.5)/(length(z$y)+1),prep=prep,H=cfg$max_h)
    }else {
      ff<-list(type="glmnet",fit=liq_glmnet_v480(z$x,z$y,family="binomial",alpha=cfg$alpha_hazard,
        lambda=sort(unique(c(cfg$lambda_grid,lambda)),decreasing=TRUE),standardize=FALSE),
        prep=prep,H=cfg$max_h,lambda=lambda)
    }
    liq_predict_hazard(ff,valid,H)
  },error=function(e)NULL)
  if(!is.null(hp)&&all(is.finite(hp)))out$Hazard_raw<-hp
  cf<-liq_fit_cox(train,cfg)
  if(cf$type=="cox")out$Cox_raw<-liq_predict_cox(cf,valid,H)
  lapply(out,liq_cdf)
}

liq_train_weights <- function(loss,eta,shrinkage) {
  ss<-sd(loss);if(!is.finite(ss)||ss<1e-10)ss<-1
  w<-exp(-eta*(loss-min(loss))/ss);w<-w/sum(w)
  (1-shrinkage)/length(w)+shrinkage*w
}

liq_add_train_mixture <- function(candidates,train,cal,guard,test,cfg,inner_bundle=NULL) {
  splits<-if(!is.null(inner_bundle))inner_bundle$splits else lapply(liq_inner_splits(train,cfg),function(s)
    list(train=train[s$train],valid=train[s$valid],transform_fit_end=as.Date(NA)))
  available<-grep("_raw$",names(candidates$pred$cal),value=TRUE)
  folds<-list();audit<-list()
  for(j in seq_along(splits)) {
    ss<-splits[[j]]
    pr<-liq_fixed_predictions(ss$train,ss$valid,cfg,candidates$fits)
    folds[[length(folds)+1L]]<-list(events=ss$valid,pred=pr)
    audit[[j]]<-data.table(inner_fold=j,n_train=nrow(ss$train),n_valid=nrow(ss$valid),
      last_training_label=max(ss$train$planned_end),validation_start=min(ss$valid$shock_date),
      validation_end=max(ss$valid$planned_end),models=paste(names(pr),collapse=","),
      penalty_source="outer TRAIN-only nested tuning; combiner tuning data, not an independent test")
  }
  common<-if(length(folds))Reduce(intersect,lapply(folds,function(z)names(z$pred)))else available
  common<-intersect(available,common)
  liq_assert(length(common)>=2L,"No common empirical models for the TRAIN mixture.")
  loss<-if(length(folds))t(vapply(folds,function(z)vapply(common,function(m)
    mean(liq_loss_vector(z$events,z$pred[[m]],cfg$horizons)),numeric(1)),numeric(length(common))))else
      matrix(0,1,length(common),dimnames=list(NULL,common))
  colnames(loss)<-common
  ns<-if(length(folds))vapply(folds,function(z)nrow(z$events),integer(1))else 1L
  grid<-data.table::CJ(eta=cfg$mix_eta_grid,shrinkage=cfg$mix_shrink_grid);grid[,candidate:=.I]
  validation<-list();ii<-0L
  if(length(folds)>=2L)for(j in 2:length(folds)) {
    prior<-colSums(loss[seq_len(j-1L),,drop=FALSE]*ns[seq_len(j-1L)])/sum(ns[seq_len(j-1L)])
    for(k in seq_len(nrow(grid))) {
      ww<-liq_train_weights(prior,grid$eta[k],grid$shrinkage[k])
      pp<-Reduce(`+`,lapply(seq_along(common),function(m)folds[[j]]$pred[[common[m]]]*ww[m]))
      ii<-ii+1L;validation[[ii]]<-data.table(candidate=k,inner_fold=j,
        mean_Brier=mean(liq_loss_vector(folds[[j]]$events,pp,cfg$horizons)))
    }
  }
  if(length(validation)) {
    vv<-liq_bind(validation)
    scores<-vv[,.(mean_loss=mean(mean_Brier),se=if(.N>1L)sd(mean_Brier)/sqrt(.N)else 0,
      n_meta_folds=.N),by=candidate]
    scores<-merge(grid,scores,by="candidate")
    best<-which.min(scores$mean_loss);cutoff<-scores$mean_loss[best]+scores$se[best]
    chosen<-scores[mean_loss<=cutoff+1e-15][order(eta*shrinkage,shrinkage,eta)][1]
    eta<-chosen$eta;shrinkage<-chosen$shrinkage;selection<-"TRAIN chronological meta-validation; one-SE complexity preference"
    scores[,selected:=candidate==chosen$candidate]
  }else {
    eta<-0;shrinkage<-0;selection<-"fixed equal weights: fewer than two usable TRAIN validation folds"
    vv<-data.table();scores<-data.table(eta=0,shrinkage=0,mean_loss=NA_real_,se=NA_real_,selected=TRUE)
  }
  all_loss<-colSums(loss*ns)/sum(ns)
  ww<-liq_train_weights(all_loss,eta,shrinkage)
  weights<-setNames(rep(0,length(available)),available);weights[common]<-ww
  for(ds in c("cal","guard","test")) {
    pp<-Reduce(`+`,lapply(available,function(m)candidates$pred[[ds]][[m]]*weights[m]))
    candidates$pred[[ds]]$TRAIN_Mixture_raw<-liq_cdf(pp)
  }
  maps<-vector("list",length(cfg$horizons))
  for(j in seq_along(cfg$horizons)) {
    tt<-liq_truth(cal,cfg$horizons[j])
    maps[[j]]<-liq_cal_fit(tt$y[tt$known],candidates$pred$cal$TRAIN_Mixture_raw[tt$known,j],cfg)
  }
  for(ds in c("cal","guard","test")) {
    pp<-candidates$pred[[ds]]$TRAIN_Mixture_raw
    cp<-do.call(cbind,lapply(seq_along(cfg$horizons),function(j)liq_cal_predict(maps[[j]],pp[,j])))
    candidates$pred[[ds]]$TRAIN_Mixture_cal<-liq_cdf(cp)
  }
  candidates$maps$TRAIN_Mixture_cal<-maps
  candidates$combiner<-list(weights=data.table(component=available,weight=as.numeric(weights),
      eta=eta,shrinkage=shrinkage,selection=selection,fit_sample="TRAIN validation predictions only"),
    tuning=scores,validation=vv,audit=liq_bind(audit),
    fold_loss=liq_bind(lapply(seq_len(nrow(loss)),function(j)data.table(inner_fold=j,
      component=common,mean_Brier=as.numeric(loss[j,]),n_events=ns[j]))))
  candidates
}

liq_guard_delta <- function(events,p,reference,cfg) {
  yy<-vapply(cfg$horizons,function(h)liq_truth(events,h)$y,numeric(nrow(events)))
  delta<-rowMeans((p-yy)^2-(reference-yy)^2)
  block<-floor((events$sid-min(events$sid))/cfg$block_length)
  z<-data.table(block=block,delta=delta)[,.(total=sum(delta),n=.N),by=block]
  estimate<-mean(delta);G<-nrow(z)
  se<-if(G>1L)sqrt(G/(G-1)*sum((z$total-z$n*estimate)^2)/sum(z$n)^2)else Inf
  list(estimate=estimate,se=se,blocks=G,
    accepted=is.finite(se)&&estimate+cfg$guard_margin_z*se < -cfg$guard_min_gain)
}

liq_rolling_schedule <- function(calendar,cfg) {
  span<-cfg$rolling_span;T<-length(calendar)
  if(T<span)return(data.table(design=character(),rolling_role=character(),first_sid=integer(),last_sid=integer()))
  ends<-seq.int(span,T,by=cfg$rolling_step);role<-rep("regular",length(ends))
  if(cfg$rolling_append_tail&&tail(ends,1)!=T){ends<-c(ends,T);role<-c(role,"appended_tail_diagnostic")}
  data.table(design=paste0(ifelse(role=="regular","rolling_","rolling_tail_"),format(calendar[ends],"%Y%m%d")),
    rolling_role=role,first_sid=ends-span+1L,last_sid=ends,
    first_date=calendar[ends-span+1L],last_date=calendar[ends])
}

liq_rolling_report <- function(rolling,primary,cfg) {
  if(!length(rolling))return(invisible(NULL))
  point<-liq_bind(lapply(rolling,function(z)z$point))
  reg<-point[rolling_role=="regular"]
  if(nrow(reg)) {
    summary<-reg[,.(n_windows=uniqueN(design),mean_Brier=liq_mean(Brier),mean_AUC=liq_mean(AUC),
      n_Brier=sum(is.finite(Brier)),n_AUC=sum(is.finite(AUC)),
      weighting="equal regular-window weights; appended tail excluded"),by=.(model,horizon)]
    liq_save(summary,"R02_regular_window_summary",cfg$out_dir)
  }
  sets<-lapply(rolling,function(z)unique(z$test_long[,.(event_id,asset,shock_date,horizon,y)]))
  sets<-c(list(primary=unique(primary$long[,.(event_id,asset,shock_date,horizon,y)])),sets)
  pairs<-utils::combn(names(sets),2,simplify=FALSE);out<-list()
  for(j in seq_along(pairs)) {
    a<-sets[[pairs[[j]][1]]];b<-sets[[pairs[[j]][2]]]
    z<-merge(a,b,by=c("event_id","horizon"),suffixes=c("_a","_b"))
    out[[j]]<-data.table(window_a=pairs[[j]][1],window_b=pairs[[j]][2],
      shared_event_ids=length(intersect(unique(a$event_id),unique(b$event_id))),
      shared_event_horizons=nrow(z),changed_labels=sum(z$y_a!=z$y_b,na.rm=TRUE),
      note="fold-specific TRAIN transformations can change labels for a shared origin; do not pool as independent repeats")
  }
  liq_save(liq_bind(out),"R03_window_origin_overlap",cfg$out_dir)
  invisible(TRUE)
}

liq_calibration_status <- function(candidates,cfg) {
  out<-list();i<-0L
  for(m in names(candidates$maps))for(j in seq_along(cfg$horizons)) {
    z<-candidates$maps[[m]][[j]];i<-i+1L
    out[[i]]<-data.table(model=m,horizon=cfg$horizons[j],type=z$type,n=z$n,
      positive=z$positive,negative=z$negative,unique_scores=z$unique_scores,reason=z$reason,
      guard_unique_predictions=uniqueN(candidates$pred$guard[[m]][,j]),
      test_unique_predictions=uniqueN(candidates$pred$test[[m]][,j]))
  }
  liq_bind(out)
}

# ---------------- Declared universe and frozen snapshot checks ---------------
liq_verify_snapshot <- function(cfg) {
  lock<-paste0(cfg$input_csv,".lock.csv")
  if(!file.exists(lock)) {
    liq_assert(!isTRUE(cfg$require_snapshot_lock),
      "Frozen input lock is missing. Extract the complete package, including data/*.lock.csv. For an independently documented external snapshot, explicitly set LIQ_REQUIRE_SNAPSHOT_LOCK=false.")
    return(data.table(artifact=character(),checked_file=character(),md5=character(),bytes=numeric(),pass=logical()))
  }
  z<-data.table::fread(lock)
  liq_assert(all(c("artifact","relative_path","md5","bytes")%in%names(z))&&!anyDuplicated(z$artifact),
    "Malformed frozen-input lock.")
  liq_assert(all(c("data","provenance","universe")%in%z$artifact),"Incomplete frozen-input lock.")
  z[,checked_file:=file.path(dirname(cfg$input_csv),relative_path)]
  liq_assert(all(file.exists(z$checked_file)),"Snapshot artifact missing; extract the entire ZIP.")
  z[,checked_file:=normalizePath(checked_file,winslash="/",mustWork=TRUE)]
  liq_assert(identical(z[artifact=="data",checked_file],normalizePath(cfg$input_csv,winslash="/",mustWork=TRUE)),
    "Snapshot lock refers to another data file.")
  actual<-unname(tools::md5sum(z$checked_file))
  z[,pass:=actual==md5 & as.numeric(file.info(checked_file)$size)==bytes]
  liq_assert(all(z$pass),paste("Frozen snapshot changed:",paste(z[pass==FALSE,artifact],collapse=", "),
    "Use a separately named snapshot and output directory; do not combine checkpoints."))
  z[,.(artifact,checked_file,md5,bytes,pass)]
}

liq_universe_audit <- function(data,cfg) {
  # Report eligibility from TRAIN OHLCV only; never choose a ticker by TEST loss.
  requested<-data.table(asset=cfg$symbols)
  if(file.exists(cfg$universe_file)) {
    roster<-data.table::fread(cfg$universe_file)
    liq_assert(!anyDuplicated(roster$asset),"Duplicate asset in universe definition.")
    requested<-merge(requested,roster,by="asset",all.x=TRUE,sort=FALSE)
  }
  requested[,`:=`(requested=TRUE,universe=cfg$universe_name,
    model_is_stock=as.numeric(asset%in%cfg$equity_symbols),
    model_is_sector=as.numeric(asset%in%cfg$sector_etf_symbols),
    historical_membership_file_supplied=nzchar(cfg$membership_file),
    selection_basis="fixed declared panel; no selection by CAL/GUARD/TEST performance")]
  liq_save(requested,"D11_declared_model_universe",cfg$out_dir)
  p<-liq_dt(data$panel);p[,role:="OUTSIDE"]
  for(j in seq_len(nrow(cfg$fold)))p[date>=cfg$fold$from[j]&date<=cfg$fold$to[j],role:=cfg$fold$role[j]]
  coverage<-p[,.(n_calendar=.N,n_observed=sum(observed),
    n_valid_OHLCV=sum(valid_price&valid_volume&member),
    first_observed=if(any(observed))min(date[observed])else as.Date(NA),
    last_observed=if(any(observed))max(date[observed])else as.Date(NA)),by=.(asset,role)]
  coverage[,`:=`(TRAIN_OHLCV_minimum=cfg$min_daily_train,
    TRAIN_supported=role!="TRAIN"|n_valid_OHLCV>=cfg$min_daily_train)]
  liq_save(coverage,"D10_asset_role_OHLCV_coverage",cfg$out_dir)
  bad<-coverage[role=="TRAIN"&TRAIN_supported==FALSE]
  liq_assert(!nrow(bad),paste("Declared assets lack the required TRAIN OHLCV support:",
    paste(bad$asset,collapse=","),"No automatic ticker removal or replacement is permitted."))
  liq_log("Declared model universe:",length(cfg$symbols),"assets; ^VIX is a reference covariate.")
  invisible(coverage)
}



# Self-normalized intervals: marginal future-origin risk, conditional on fixed
# fitted models and this asset panel. Stationarity/influence-FCLT assumptions;
# diagnostic addition, never a finite-sample or conditional-path guarantee.
liq_sn_critical <- function(K=1L) {
  kk<-c(1L,4L,8L,16L);vv<-c(45.5167134530104,90.27406153868213,118.4881171719588,149.9210390775354)
  liq_assert(K>=1&&K<=16,"SN family exceeds calibrated range.")
  vv[which(kk>=K)[1]]
}
liq_auc_influence <- function(y,p) {
  out<-rep(NA_real_,length(y));ok<-is.finite(y)&is.finite(p)
  yy<-y[ok];ss<-p[ok];n<-length(yy);n1<-sum(yy==1);n0<-sum(yy==0)
  if(!n1||!n0)return(out)
  d<-data.table(y=yy,s=ss,i=seq_len(n))
  g<-d[,.(a=sum(y==1),b=sum(y==0)),by=s][order(s)]
  g[,v1:=(cumsum(b)-b+.5*b)/n0]
  g[,v0:=(n1-cumsum(a)+.5*a)/n1]
  au<-liq_auc(yy,ss);ii<-match(ss,g$s)
  out[ok]<-ifelse(yy==1,(g$v1[ii]-au)/(n1/n),(g$v0[ii]-au)/(n0/n))
  out
}
liq_sn_interval <- function(e,calendar,influence,estimate,cfg,K=1L,identity=FALSE,auc=FALSE,y=NULL) {
  if(identity&&is.finite(estimate))return(list(estimate=estimate,lower=0,upper=0,
    supported=TRUE,reason="algebraically identical outputs; not a coverage success",n_dates=uniqueN(e$shock_date),
    calendar_span=as.integer(max(e$sid)-min(e$sid)+1L),critical=liq_sn_critical(K)))
  date_idx<-match(e$shock_date,calendar);T<-max(date_idx)-min(date_idx)+1L
  nd<-uniqueN(e$shock_date);reason<-"estimated under stationary influence-FCLT assumptions"
  supported<-is.finite(estimate)&&all(is.finite(influence))&&nd>=cfg$sn_min_dates&&T>=10L*cfg$max_h
  if(!supported)reason<-"insufficient independent time span, dates, or finite influence"
  if(auc&&(min(sum(y==1),sum(y==0))<10L||
    min(uniqueN(e$shock_date[y==1]),uniqueN(e$shock_date[y==0]))<10L)) {
    supported<-FALSE;reason<-"insufficient AUC class or class-date support"
  }
  bounds<-c(NA_real_,NA_real_)
  if(supported) {
    v<-influence-mean(influence);z<-numeric(T)
    zz<-rowsum(v,date_idx-min(date_idx)+1L,reorder=FALSE)
    z[as.integer(rownames(zz))]<-zz[,1]
    partial<-cumsum(z)-seq_len(T)/T*sum(z)
    V<-sum(partial^2)/length(v)^2
    if(is.finite(V)&&V>1e-20)bounds<-estimate+c(-1,1)*sqrt(liq_sn_critical(K)*V/T)else {
      supported<-FALSE;reason<-"degenerate influence normalizer; no stochastic interval"
    }
  }
  list(estimate=estimate,lower=bounds[1],upper=bounds[2],supported=supported,reason=reason,
    n_dates=nd,calendar_span=T,critical=liq_sn_critical(K))
}
liq_sn_pairs <- function(e,pred,cfg,calendar,choices=NULL,correction=NULL) {
  pairs<-list(c("LIQ_Brier","Single_Brier_Guard","Brier","primary"),
    c("LIQ_Brier","Cox_raw","Brier","primary"),
    c("LIQ_Rank_Guard","Single_Rank_Guard","AUC","primary"),
    c("LIQ_Rank_Guard","Cox_raw","AUC","primary"),
    c("CoxResidual_raw","Cox_raw","Brier","diagnostic"))
  rows<-list()
  for(pair in pairs)if(all(pair[1:2]%in%names(pred)))for(j in seq_along(cfg$horizons)) {
    y<-liq_truth(e,cfg$horizons[j])$y;ok<-is.finite(y);p<-pred[[pair[1]]][ok,j];q<-pred[[pair[2]]][ok,j]
    same<-identical(as.numeric(p),as.numeric(q));auc<-pair[3]=="AUC"
    algebraic<-FALSE
    is_cox<-function(src)src=="Cox_raw"||
      (src=="CoxResidual_raw"&&!is.null(correction)&&
       (correction$type=="identity"||correction$gamma==0))
    if(pair[1]=="CoxResidual_raw"&&pair[2]=="Cox_raw")
      algebraic<-!is.null(correction)&&(correction$type=="identity"||correction$gamma==0)
    if(!is.null(choices)&&nrow(choices)) {
      ch<-choices[head==pair[1]&horizon==cfg$horizons[j]]
      reference_choice<-choices[head==pair[2]&horizon==cfg$horizons[j]]
      if(nrow(ch)==1L) {
        src<-if(pair[1]=="LIQ_Brier"&&!is.na(ch$selected_source))ch$selected_source else ch$component1
        if(pair[2]=="Cox_raw")algebraic<-is_cox(src)
        if(nrow(reference_choice)==1L)algebraic<-src==reference_choice$component1
        if(auc&&!is.na(ch$weight1)&&ch$weight1!=1&&
          !is.na(ch$component2)&&ch$component1!=ch$component2)algebraic<-FALSE
      }
    }
    algebraic<-isTRUE(algebraic)&&same
    estimate<-if(auc)liq_auc(y[ok],p)-liq_auc(y[ok],q)else mean((p-y[ok])^2-(q-y[ok])^2)
    inf<-if(auc)liq_auc_influence(y[ok],p)-liq_auc_influence(y[ok],q)else (p-y[ok])^2-(q-y[ok])^2
    # The two comparators and all horizons form one family per output/metric.
    K<-length(cfg$horizons)*if(pair[4]=="primary")2L else 1L
    iv<-liq_sn_interval(e[ok],calendar,inf,estimate,cfg,K,algebraic,auc,y[ok])
    rows[[length(rows)+1L]]<-cbind(data.table(model=pair[1],reference=pair[2],metric=pair[3],
      horizon=cfg$horizons[j],family=pair[4],family_size=K,identical_output=same,algebraic_identity=algebraic,
      target="marginal future-origin paired risk; fixed fitted models and asset panel",
      interpretation="asymptotic stationary influence-FCLT; conditional-path coverage not asserted"),
      as.data.table(iv))
  }
  liq_bind(rows)
}


# Cox-anchored residual correction. All parameters are selected within TRAIN.
liq_correction_design <- function(e,anchor,prep=NULL) {
  cols<-c("lsi","market_loo","market_trend5","volume_shock","lsi_mom5",
    "avg_corr_lag1","log_dvol","is_stock","is_sector")
  xx<-as.matrix(e[,..cols]);xx<-cbind(xx,anchor_logit=qlogis(liq_clip(anchor)))
  if(is.null(prep)) {
    md<-apply(xx,2,function(x)if(any(is.finite(x)))median(x[is.finite(x)])else 0)
    for(j in seq_len(ncol(xx)))xx[!is.finite(xx[,j]),j]<-md[j]
    mu<-colMeans(xx);ss<-apply(xx,2,sd);ss[!is.finite(ss)|ss<1e-8]<-1
    prep<-list(median=md,mean=mu,sd=ss)
  }
  for(j in seq_len(ncol(xx)))xx[!is.finite(xx[,j]),j]<-prep$median[j]
  xx<-sweep(sweep(xx,2,prep$mean),2,prep$sd,"/");xx<-pmin(pmax(xx,-6),6)
  xx<-cbind(xx,lsi_sq=xx[,"lsi"]^2,market_sq=xx[,"market_loo"]^2,
    volume_sq=xx[,"volume_shock"]^2,
    anchor_by_market=xx[,"anchor_logit"]*xx[,"market_loo"],
    lsi_by_market=xx[,"lsi"]*xx[,"market_loo"])
  list(x=xx,prep=prep)
}
liq_correction_path <- function(e,anchor,cfg) {
  fits<-lapply(seq_along(cfg$horizons),function(j) {
    y<-liq_truth(e,cfg$horizons[j])$y;ok<-is.finite(y)
    if(sum(ok)<cfg$min_train||length(unique(y[ok]))<2L||min(table(y[ok]))<8L)return(NULL)
    d<-liq_correction_design(e[ok],anchor[ok,j])
    ff<-liq_glmnet_v480(d$x,y[ok],family="binomial",alpha=0,
      offset=qlogis(liq_clip(anchor[ok,j])),lambda=cfg$correction_lambda_grid,
      standardize=FALSE,intercept=TRUE)
    list(fit=ff,prep=d$prep)
  })
  list(type=if(any(vapply(fits,is.null,logical(1))))"identity"else"ridge",
    fits=fits,lambda=max(cfg$correction_lambda_grid),gamma=0)
}
liq_correction_predict <- function(fit,e,anchor,cfg,lambda=fit$lambda,gamma=fit$gamma) {
  if(fit$type!="ridge"||gamma==0)return(anchor)
  ans<-vapply(seq_along(cfg$horizons),function(j) {
    z<-liq_correction_design(e,anchor[,j],fit$fits[[j]]$prep)
    offset<-qlogis(liq_clip(anchor[,j]))
    link<-as.numeric(predict(fit$fits[[j]]$fit,newx=z$x,s=lambda,
      newoffset=offset,type="link"))
    plogis(offset+gamma*(link-offset))
  },numeric(nrow(e)))
  colnames(ans)<-cfg$horizons;liq_cdf(ans)
}
liq_add_cox_correction <- function(candidates,train,cal,guard,test,cfg,inner_bundle) {
  if(is.null(candidates$pred$cal$Cox_raw))return(candidates)
  if(!is.null(inner_bundle$correction))inner_bundle<-inner_bundle$correction
  split_cfg<-cfg;split_cfg$inner_fractions<-cfg$correction_inner_fractions
  splits<-if(is.null(inner_bundle))lapply(liq_inner_splits(train,split_cfg),function(s)
    list(train=train[s$train],valid=train[s$valid],transform_fit_end=as.Date(NA)))else inner_bundle$splits
  folds<-audit<-list()
  for(k in seq_along(splits)) {
    ss<-splits[[k]];ff<-liq_fit_cox(ss$train,cfg)
    if(ff$type!="cox")next
    pp<-liq_cdf(liq_predict_cox(ff,ss$valid,cfg$horizons))
    liq_assert(all(ss$train$planned_end<min(ss$valid$shock_date)),"Correction OOF label leakage.")
    folds[[length(folds)+1L]]<-list(events=ss$valid,anchor=pp)
    audit[[length(audit)+1L]]<-data.table(inner_fold=k,n_train=nrow(ss$train),n_valid=nrow(ss$valid),
      last_training_label=max(ss$train$planned_end),first_validation=min(ss$valid$shock_date),
      transform_fit_end=ss$transform_fit_end,scope="nested forward TRAIN only; Cox penalties fixed")
  }
  grid<-CJ(lambda=cfg$correction_lambda_grid,gamma=cfg$correction_gamma_grid)
  grid[,candidate:=.I];validation<-list()
  if(length(folds)>=2L)for(k in 2:length(folds)) {
    tr<-liq_bind(lapply(folds[seq_len(k-1L)],`[[`,"events"))
    ap<-do.call(rbind,lapply(folds[seq_len(k-1L)],`[[`,"anchor"))
    keep<-tr$planned_end<min(folds[[k]]$events$shock_date)
    ff<-liq_correction_path(tr[keep],ap[keep,,drop=FALSE],cfg)
    for(z in seq_len(nrow(grid))) {
      pp<-liq_correction_predict(ff,folds[[k]]$events,folds[[k]]$anchor,cfg,grid$lambda[z],grid$gamma[z])
      validation[[length(validation)+1L]]<-data.table(candidate=z,inner_fold=k,
        mean_Brier=mean(liq_loss_vector(folds[[k]]$events,pp,cfg$horizons)))
    }
  }
  vv<-liq_bind(validation)
  if(nrow(vv)) {
    tuning<-merge(grid,vv[,.(mean_loss=mean(mean_Brier),se=if(.N>1L)sd(mean_Brier)/sqrt(.N)else 0,
      n_meta_folds=.N),by=candidate],by="candidate")
    best<-tuning$candidate[which.min(tuning$mean_loss)]
    paired<-merge(vv,vv[candidate==best,.(inner_fold,best_loss=mean_Brier)],by="inner_fold")
    paired<-paired[,.(paired_gap=mean(mean_Brier-best_loss),
      paired_se=if(.N>1L)sd(mean_Brier-best_loss)/sqrt(.N)else 0),by=candidate]
    tuning<-merge(tuning,paired,by="candidate")
    tuning[,eligible_paired_one_SE:=paired_gap<=paired_se+1e-15]
    chosen<-tuning[eligible_paired_one_SE==TRUE][order(gamma,-lambda)][1]
    tuning[,selected:=candidate==chosen$candidate]
  } else {
    chosen<-data.table(lambda=max(cfg$correction_lambda_grid),gamma=0)
    tuning<-data.table(lambda=chosen$lambda,gamma=0,mean_loss=NA_real_,se=NA_real_,selected=TRUE)
  }
  if(length(folds)) {
    oo<-liq_bind(lapply(folds,`[[`,"events"));aa<-do.call(rbind,lapply(folds,`[[`,"anchor"))
    fit<-liq_correction_path(oo,aa,cfg)
  } else {oo<-train[0];fit<-list(type="identity")}
  fit$lambda<-chosen$lambda;fit$gamma<-chosen$gamma
  fit$n_oof<-nrow(oo);fit$tuning<-tuning;fit$validation<-vv;fit$audit<-liq_bind(audit)
  fit$selection<-paste0("shared lambda/gamma: ",length(folds)," forward TRAIN folds, ",uniqueN(vv$inner_fold)," meta-validation periods; paired-difference one-SE heuristic; smaller gamma then stronger ridge")
  candidates$fits$Correction<-fit
  datasets<-list(cal=cal,guard=guard,test=test)
  for(ds in names(datasets))candidates$pred[[ds]]$CoxResidual_raw<-
    liq_correction_predict(fit,datasets[[ds]],candidates$pred[[ds]]$Cox_raw,cfg)
  maps<-lapply(seq_along(cfg$horizons),function(j) {
    y<-liq_truth(cal,cfg$horizons[j])$y;liq_cal_fit(y,candidates$pred$cal$CoxResidual_raw[,j],cfg)
  })
  candidates$maps$CoxResidual_cal<-maps
  for(ds in names(datasets))candidates$pred[[ds]]$CoxResidual_cal<-liq_cdf(do.call(cbind,
    lapply(seq_along(cfg$horizons),function(j)liq_cal_predict(maps[[j]],candidates$pred[[ds]]$CoxResidual_raw[,j]))))
  candidates
}
liq_candidates <- function(train,cal,guard,test,cfg,inner_bundle=NULL) {
  if(nzchar(cfg$frozen_file))return(liq_restore_freeze(cfg$frozen_file,train,cal,guard,test,cfg))
  ans<-liq_candidates_v440(train,cal,guard,test,cfg,inner_bundle)
  liq_add_cox_correction(ans,train,cal,guard,test,cfg,inner_bundle)
}
liq_heads_v460 <- function(candidates,guard,cfg) {
  ans<-liq_heads_v440(candidates,guard,cfg)
  for(ds in c("guard","test")) {
    ans[[ds]]$LIQ_Brier_v440<-ans[[ds]]$LIQ_Brier
    ans[[ds]]$LIQ_Rank_v440<-ans[[ds]]$LIQ_Rank_Guard
  }
  ans$rank_names<-c(ans$rank_names,"LIQ_Rank_v440")
  proposed<-intersect(c("CoxResidual_raw","CoxResidual_cal"),names(ans$guard))
  if(!length(proposed))return(ans)
  H<-cfg$horizons;g<-ans$guard;t<-ans$test
  score<-vapply(proposed,function(m)mean(liq_loss_vector(guard,g[[m]],H)),numeric(1))
  proposal<-proposed[which.min(score)]
  single<-ans$choices[head=="Single_Brier_Guard",component1][1]
  gate<-liq_guard_delta(guard,g[[proposal]],g[[single]],cfg)
  selected<-if(gate$accepted)proposal else single
  for(ds in c("guard","test"))ans[[ds]]$LIQ_Brier<-ans[[ds]][[selected]]
  ans$choices<-ans$choices[!head%in%c("LIQ_Brier","LIQ_Rank_Guard")]
  for(j in seq_along(H)) {
    y<-liq_truth(guard,H[j])$y;pos<-is.finite(y)&y==1;neg<-is.finite(y)&y==0
    allowed<-min(sum(pos),sum(neg))>=cfg$min_class &&
      min(uniqueN(guard$shock_date[pos]),uniqueN(guard$shock_date[neg]))>=cfg$selection_min_dates &&
      min(uniqueN(guard$asset[pos]),uniqueN(guard$asset[neg]))>=cfg$selection_min_assets
    base<-ans$choices[head=="Single_Rank_Guard"&horizon==H[j],component1][1]
    gain<-liq_auc(y,g$CoxResidual_raw[,j])-liq_auc(y,g[[base]][,j])
    rank_src<-if(allowed&&is.finite(gain)&&gain>cfg$rank_min_gain)"CoxResidual_raw"else base
    for(ds in c("guard","test"))ans[[ds]]$LIQ_Rank_Guard[,j]<-ans[[ds]][[rank_src]][,j]
    ans$choices<-rbind(ans$choices,data.table(head="LIQ_Rank_Guard",horizon=H[j],
      component1=rank_src,component2=rank_src,weight1=1,selection_allowed=allowed,
      minimum_pair_AUC_gain=cfg$rank_min_gain,guard_AUC_gain=gain),fill=TRUE)
    ans$choices<-rbind(ans$choices,data.table(head="LIQ_Brier",horizon=H[j],component1=single,
      component2=proposal,weight1=as.numeric(selected==single),selected_source=selected),fill=TRUE)
  }
  pool<-unique(c(ans$weights$component,proposed))
  ans$weights<-liq_bind(lapply(H,function(h)data.table(horizon=h,component=pool,
    weight=as.numeric(pool==selected),retained_ensemble=gate$accepted,guard_baseline=single,
    selected_source=selected,guard_rule="unchanged paired block-margin heuristic; not confidence guarantee")))
  ans$gate<-data.table(proposal=proposal,single=single,selected=selected,delta_Brier=gate$estimate,
    block_SE=gate$se,n_blocks=gate$blocks,margin_z=cfg$guard_margin_z,
    min_gain=cfg$guard_min_gain,accepted=gate$accepted,
    interpretation="separate GUARD; no TEST tuning; retrospective development")
  ans
}

liq_model_spec <- function(cfg) {
  d<-liq_model_spec_v440(cfg)
  d[item=="probability_combination",value:=paste0("Cox-logit offset residual correction; 15 fixed context terms; ridge alpha=0; shared lambda/gamma from nested forward TRAIN predictions; paired-difference one-SE across five meta-validation folds from six forward TRAIN folds; smaller gamma then stronger ridge. Original TRAIN mixture retained as v4.4 comparator.")]
  d[item=="rank_ensemble",value:="Cox residual raw vs GUARD-selected original raw single; accept only AUC gain >0.005 and class/date/asset support; original v4.4 rank mixture retained separately"]
  rbind(d,data.table(item=c("residual_basis","residual_zero","SN_scope"),value=c(
    "TRAIN-meta standardized lsi,market_loo,market_trend5,volume_shock,lsi_mom5,avg_corr_lag1,log_dvol,is_stock,is_sector,anchor_logit; add lsi^2,market^2,volume_shock^2,anchor_logit*market,lsi*market; medians/means/SD refitted in every meta-training prefix; standardized values clipped at +/-6",
    "gamma=0 or unavailable residual fit returns Cox exactly; CAL-FIT calibrations remain separate",
    "diagnostic stationary marginal future-origin inference conditional on fitted models and fixed panel; min40 origin dates and calendar span10Hmax; no training/universe uncertainty; no conditional-path or nonstationary finite-sample coverage claim")))
}


liq_fitted_candidate_predictions <- function(candidates,train,new,cfg) {
  H<-cfg$horizons;ff<-candidates$fits
  raw<-list(Historical_raw=liq_empirical(train,new,H),Regime_raw=liq_empirical(train,new,H,TRUE),
    Logit_raw=do.call(cbind,lapply(ff$Logit,liq_predict_logit,e=new)),
    Hazard_raw=liq_predict_hazard(ff$Hazard,new,H))
  if(ff$Cox$type=="cox")raw$Cox_raw<-liq_predict_cox(ff$Cox,new,H)
  raw<-lapply(raw,liq_cdf)
  ww<-candidates$combiner$weights
  raw$TRAIN_Mixture_raw<-liq_cdf(Reduce(`+`,lapply(seq_len(nrow(ww)),
    function(k)raw[[ww$component[k]]]*ww$weight[k])))
  if(!is.null(ff$Correction))raw$CoxResidual_raw<-liq_correction_predict(ff$Correction,new,raw$Cox_raw,cfg)
  pred<-raw
  for(m in names(candidates$maps)) {
    src<-sub("_cal$","_raw",m);maps<-candidates$maps[[m]]
    pred[[m]]<-liq_cdf(do.call(cbind,lapply(seq_along(H),function(j)liq_cal_predict(maps[[j]],raw[[src]][,j]))))
  }
  pred
}
liq_train_freeze <- function(cfg,path) {
  liq_packages(cfg);cfg$frozen_file<-"";liq_dir(cfg$out_dir)
  cutoff<-cfg$fold$to[cfg$fold$role=="GUARD"]
  dat<-liq_get_data(cfg);cfg<-dat$cfg
  panel<-dat$panel[date<=cutoff];calendar<-dat$calendar[dat$calendar<=cutoff]
  ff<-liq_raw_features(panel,cfg);ix<-liq_index(ff,cfg,cfg$fold)
  ev<-liq_events(ix$panel,calendar,cfg,cfg$fold)$events
  blocks<-lapply(c("TRAIN","CAL_FIT","GUARD"),function(r)ev[role==r&analysis_eligible==TRUE])
  names(blocks)<-c("TRAIN","CAL_FIT","GUARD")
  for(r in names(blocks))liq_need(nrow(blocks[[r]])>=c(TRAIN=cfg$min_train,CAL_FIT=cfg$min_cal,GUARD=cfg$min_guard)[r],paste("Freeze:",r,"too few events"))
  inner<-liq_nested_inner(ff,calendar,cfg,cfg$fold,cfg$index_variant,FALSE,cfg$regime_source)
  cand<-liq_candidates(blocks$TRAIN,blocks$CAL_FIT,blocks$GUARD,blocks$GUARD,cfg,inner)
  hd<-liq_heads(cand,blocks$GUARD,cfg)
  receipt<-list(candidates=cand,blocks=blocks,choices=hd$choices,gate=hd$gate,
    source_md5=unname(tools::md5sum(cfg$source_path)),cfg=cfg,inner=inner,
    latest_data_used=max(panel$date),TEST_labels_used=FALSE)
  liq_dir(dirname(path));staged<-paste0(path,".tmp")
  liq_save_rds_atomic(receipt,staged)
  recovered<-readRDS(staged)
  liq_assert(identical(recovered$source_md5,receipt$source_md5)&&
    identical(recovered$TEST_labels_used,FALSE),"Freeze serialization roundtrip failed.")
  liq_assert(file.rename(staged,path),"Cannot commit validated TRAIN freeze.")
  liq_save(data.table(latest_data_used=max(panel$date),TEST_labels_used=FALSE,
    source_md5=receipt$source_md5,protocol="reanalysis; new correction frozen without post-2023 observations"),"TRAIN_FREEZE_SCOPE",cfg$out_dir)
  liq_save(cand$fits$Correction$tuning,"TRAIN_CORRECTION_TUNING",cfg$out_dir)
  liq_save(hd$choices,"GUARD_FROZEN_SELECTION",cfg$out_dir)
  liq_log("TRAIN freeze saved; latest daily observation",as.character(max(panel$date)),"TEST labels used: FALSE")
  invisible(receipt)
}
liq_restore_freeze <- function(path,train,cal,guard,test,cfg) {
  z<-readRDS(path)
  liq_assert(identical(z$source_md5,unname(tools::md5sum(cfg$source_path))),"Freeze source identity differs; refit before evaluation.")
  for(r in c("TRAIN","CAL_FIT","GUARD")) {
    current<-switch(r,TRAIN=train,CAL_FIT=cal,GUARD=guard)
    liq_assert(isTRUE(all.equal(current,z$blocks[[r]],tolerance=0,check.attributes=FALSE)),paste("Freeze block differs:",r))
  }
  cand<-z$candidates;cand$pred$test<-liq_fitted_candidate_predictions(cand,train,test,cfg)
  hd<-liq_heads(cand,guard,cfg)
  liq_assert(isTRUE(all.equal(hd$choices,z$choices,tolerance=0,check.attributes=FALSE)),"Frozen GUARD selection changed.")
  cand
}


# Self-contained English LaTeX tables and vector PDF/300 dpi PNG figures.
liq_tex_escape <- function(x) {
  vapply(as.character(x),function(s) {
    if(is.na(s))return("--")
    chars<-strsplit(s,"",fixed=TRUE)[[1]]
    map<-c("\\"="\\textbackslash{}","_"="\\_","%"="\\%","&"="\\&",
      "#"="\\#","$"="\\$","{"="\\{","}"="\\}","~"="\\textasciitilde{}","^"="\\textasciicircum{}")
    paste0(vapply(chars,function(z)if(z%in%names(map))map[[z]]else z,character(1)),collapse="")
  },character(1),USE.NAMES=FALSE)
}
liq_pub_table <- function(d,caption,note,label,dir,digits=4L) {
  d<-liq_dt(d);liq_write_csv(d,file.path(dir,paste0(label,".csv")))
  formatted<-lapply(d,function(x)if(is.numeric(x))ifelse(is.finite(x),formatC(x,format="f",digits=digits),"--")else as.character(x))
  # Counts are supplied as character columns by the caller.
  cells<-as.data.frame(lapply(formatted,liq_tex_escape),stringsAsFactors=FALSE)
  row_end<-paste0(" ",strrep(intToUtf8(92),2))
  rows<-apply(cells,1,function(z)paste0(paste(z,collapse=" & "),row_end))
  tex<-c("\\begin{table}[p]","\\centering\\small",paste0("\\caption{",liq_tex_escape(caption),"}"),
    paste0("\\label{tab:",label,"}"),"\\setlength{\\tabcolsep}{4pt}",
    "\\sbox{\\LIQtablebox}{%",paste0("\\begin{tabular}{l",paste(rep("r",ncol(d)-1L),collapse=""),"}"),
    "\\toprule",paste0(paste(liq_tex_escape(names(d)),collapse=" & "),row_end),"\\midrule",rows,
    "\\bottomrule","\\end{tabular}}",
    "\\ifdim\\wd\\LIQtablebox>\\textwidth\\resizebox{\\textwidth}{!}{\\usebox{\\LIQtablebox}}\\else\\usebox{\\LIQtablebox}\\fi",
    paste0("\\par\\smallskip\\begin{minipage}{\\textwidth}\\footnotesize ",liq_tex_escape(note),"\\end{minipage}"),"\\end{table}")
  writeLines(tex,file.path(dir,paste0(label,".tex")));tex
}
liq_pub_plot <- function(dir,name,draw,width=7.2,height=4.6) {
  pdf_file<-file.path(dir,paste0(name,".pdf"))
  if(isTRUE(capabilities("cairo")))grDevices::cairo_pdf(pdf_file,width=width,height=height,
    family="sans",onefile=TRUE)else grDevices::pdf(pdf_file,width=width,height=height,useDingbats=FALSE)
  tryCatch(draw(),finally=dev.off())
  grDevices::png(file.path(dir,paste0(name,".png")),width=width,height=height,units="in",res=300,type="cairo")
  tryCatch(draw(),finally=dev.off())
  invisible(pdf_file)
}
liq_publication_export <- function(primary,cfg,out=cfg$out_dir) {
  pub<-liq_dir(file.path(out,"publication"));td<-liq_dir(file.path(pub,"tables"));fd<-liq_dir(file.path(pub,"figures"))
  pt<-liq_dt(primary$point);sn<-liq_dt(primary$batch_inference);ev<-primary$problem$events
  names_model<-c(Historical_raw="Historical",Regime_raw="Regime",Logit_raw="Penalized logit",
    Hazard_raw="Discrete hazard",Cox_raw="Cox",CoxResidual_raw="Cox residual",CoxResidual_cal="Cox residual calibrated",
    Single_Brier_Guard="Selected single (Brier)",Single_Rank_Guard="Selected single (AUC)",
    LIQ_Brier="LIQ-P v4.6",LIQ_Rank_Guard="LIQ-R v4.6",LIQ_Brier_v440="LIQ-P v4.4",
    LIQ_Rank_v440="LIQ-R v4.4")
  pretty<-function(x)ifelse(x%in%names(names_model),unname(names_model[x]),x)
  scoped_pretty<-function(x,scope)if(grepl("archived v4.4",scope,fixed=TRUE))
    gsub("v4.6","v4.4",pretty(x),fixed=TRUE)else pretty(x)
  tables<-figures<-list();sources<-list()
  tab<-function(d,caption,note,id,source) {
    tables[[length(tables)+1L]]<<-liq_pub_table(d,caption,note,id,td)
    sources[[length(sources)+1L]]<<-data.table(artifact=id,scope=source,caption=caption)
  }
  fig<-function(id,caption,draw,source,height=4.6) {
    liq_pub_plot(fd,id,draw,height=height)
    figures[[length(figures)+1L]]<<-c("\\begin{figure}[p]","\\centering",
      paste0("\\includegraphics[width=\\textwidth]{figures/",id,".pdf}"),
      paste0("\\caption{",liq_tex_escape(caption),"}"),paste0("\\label{fig:",id,"}"),"\\end{figure}")
    sources[[length(sources)+1L]]<<-data.table(artifact=id,scope=source,caption=caption)
  }
  archived<-file.path(dirname(cfg$source_path),"ARCHIVED_V440","tables")
  optional<-function(name) {
    new<-file.path(out,"tables",paste0(name,".csv"));old<-file.path(archived,paste0(name,".csv"))
    if(file.exists(new))list(data=fread(new),scope=paste0("new v",cfg$version))else
      if(file.exists(old))list(data=fread(old),scope="archived v4.4")else NULL
  }
  archived_note<-function(scope,old,new)if(grepl("archived",scope,fixed=TRUE))old else new
  scopes<-"new v4.6 primary, historical reanalysis"
  role<-ev[analysis_eligible==TRUE,.(N=as.character(.N),Assets=as.character(uniqueN(asset)),
    Dates=as.character(uniqueN(shock_date)),`30 positive`=as.character(sum(status==1L&duration<=30L)),
    `30 negative`=as.character(sum(!(status==1L&duration<=30L))),
    `First origin`=as.character(min(shock_date)),`Last label`=as.character(max(planned_end))),by=role]
  role<-role[match(c("TRAIN","CAL_FIT","GUARD","TEST"),role)]
  tab(role,"Eligible recovery events by temporal role (v4.6 primary).",
    "Recovery is the first completed three-session confirmation. Full-window non-recoveries are negative; incomplete windows and windows crossing role ends are excluded from this complete-window primary analysis. Horizons are reference trading sessions. No CAL-FIT/GUARD pooling. Historical TEST is a reanalysis.","T01_roles",scopes)
  selected<-intersect(c("Historical_raw","Regime_raw","Logit_raw","Hazard_raw","Cox_raw","CoxResidual_raw","CoxResidual_cal","LIQ_Brier"),pt$model)
  wide<-dcast(pt[model%in%selected],model~horizon,value.var="Brier");wide<-wide[match(selected,model)];wide[,model:=pretty(model)]
  tab(wide,"Brier scores at each recovery horizon (v4.6 primary).",
    "Lower is better. All models use identical eligible TEST events. The residual correction uses paired-difference one-SE selection only within TRAIN and calibrated only on CAL-FIT; final acceptance uses GUARD. Equal predictions are reported without implying added value.","T02_Brier",scopes)
  auc_models<-c("Regime_raw","Logit_raw","Hazard_raw","Cox_raw","CoxResidual_raw","Single_Rank_Guard","LIQ_Rank_Guard")
  wide<-dcast(pt[model%in%auc_models],model~horizon,value.var="AUC");wide<-wide[match(intersect(auc_models,wide$model),model)];wide[,model:=pretty(model)]
  tab(wide,"Discrimination by recovery horizon (v4.6 primary).",
    "Higher AUC is better; ties receive half credit. Rank outputs have no probability interpretation. The single-model comparator is selected on GUARD using the original five raw component models.","T03_AUC",scopes)
  avg<-pt[model%in%c(selected,"Single_Brier_Guard","LIQ_Brier_v440","LIQ_Rank_Guard","Single_Rank_Guard"),
    .(Brier=liq_mean(Brier),AUC=liq_mean(AUC),`BSS vs cal. historical`=liq_mean(BSS_historical)),by=model]
  avg[,model:=pretty(model)]
  tab(avg,"Equal-horizon descriptive summaries (v4.6 primary).",
    "Each of 5, 10, 20 and 30 sessions receives weight 1/4. Per-horizon results remain primary. BSS uses the CAL-FIT-calibrated historical probability, not raw historical frequency. Missing Brier/BSS cells denote ranking scores.","T04_means",scopes)
  id_proven<-if("algebraic_identity"%in%names(sn))sn$algebraic_identity else sn$identical_output
  si<-sn[,.(Model=pretty(model),Reference=pretty(reference),Metric=metric,H=as.character(horizon),
    Delta=estimate,Lower=lower,Upper=upper)]
  si[,Identity:=ifelse(id_proven,"yes","no")]
  tab(si,"Paired increments and calendar-batch t intervals (v4.6 primary).",
    "Delta is candidate minus comparator: negative Brier and positive AUC favor the candidate. Primary intervals use a Bonferroni family of two comparators times four horizons for each output/metric. Cox-residual diagnostics use four horizons. Identity rows require a proven common fitted source, not only equal observed values, and are not coverage successes. Missing bounds mean unsupported inference. Intervals assume a stationary influence functional central limit theorem for marginal future-origin risk conditional on fitted models and the fixed asset panel; they do not establish finite-sample or conditional-path coverage.","T05_increments",scopes)
  ch<-primary$heads$choices
  choices<-ch[head%in%c("LIQ_Brier","LIQ_Rank_Guard"),.(Output=ifelse(head=="LIQ_Brier","Probability","Rank"),
    H=as.character(horizon),Source=pretty(ifelse(!is.na(selected_source),selected_source,component1)))]
  fit<-primary$candidates$fits$Correction
  note<-paste0("Correction TRAIN choice: lambda=",fit$lambda,", gamma=",fit$gamma,", OOF events=",fit$n_oof,
    ". Gamma zero gives exactly Cox. Brier acceptance retains the original paired block-margin heuristic; rank acceptance requires GUARD AUC gain >0.005 plus class/cluster support. These selection rules are not confidence guarantees.")
  tab(choices,"Frozen GUARD selections and TRAIN correction choice (v4.6).",note,"T06_selection",scopes)
  # Construct costs directly from the same frozen TEST forecasts.
  dc<-liq_bind(lapply(seq_along(cfg$horizons),function(j) {
    y<-liq_truth(primary$blocks$TEST,cfg$horizons[j])$y;p<-primary$heads$test$LIQ_Brier[,j]
    liq_bind(lapply(cfg$cost_ratios,function(r) {
      action<-p>=r/(r+1);cc<-mean(r*action*(1-y)+(1-action)*y)
      data.table(H=as.character(cfg$horizons[j]),Ratio=as.character(r),`Model cost`=cc,
        `Always resume`=r*mean(1-y),`Always cautious`=mean(y),`Best fixed minus model`=min(r*mean(1-y),mean(y))-cc)
    }))
  }))
  liq_write_csv(dc,file.path(out,"tables","T14_decision_cost_points_only.csv"))
  tab(dc,"Scenario decision costs (v4.6 primary).",
    "Resume when p >= r/(r+1); false recovery costs r and unnecessary caution costs 1. Positive best-fixed-minus-model values favor the probability model. Ratios 1, 2 and 5 are declared scenarios, not estimated market execution costs.","T07_decisions",scopes)
  ex<-optional("G02_all_completed_extended_results");sim<-optional("S01_all_simulation_replications");cov<-optional("S04_interval_coverage_summary")
  if(!is.null(ex)) {
    roll<-ex$data[!is.na(rolling_role)&rolling_role=="regular_nonoverlapping"]
    if(!nrow(roll))roll<-ex$data[!is.na(rolling_role)&grepl("regular",rolling_role)]
    roll<-roll[!grepl("tail",rolling_role)]
    rr<-roll[,.(Brier=liq_mean(Brier),AUC=liq_mean(AUC),Windows=as.character(uniqueN(design))),by=model]
    rr<-rr[model%in%c("Logit_raw","Hazard_raw","Cox_raw","Single_Brier_Guard","LIQ_Brier","Single_Rank_Guard","LIQ_Rank_Guard")]
    rr[,model:=scoped_pretty(model,ex$scope)]
    tab(rr,paste0("Regular rolling results (",ex$scope,")."),
      paste("Equal weights over horizons and completed regular non-overlapping TEST windows. Appended tail diagnostics are excluded. Overlapping TRAIN/calibration histories mean window results are not independent replications.",
        archived_note(ex$scope,"Archived v4.4 results do not validate the new residual correction.","These results were generated by the current code; inspect the saved window status and class-support reports.")),"T08_rolling",ex$scope)
    se<-ex$data[grepl("^sensitivity_",design)]
    ss<-list()
    for(pair in list(c("LIQ_Brier","Single_Brier_Guard","Brier"),c("LIQ_Brier","Cox_raw","Brier"),
      c("LIQ_Rank_Guard","Single_Rank_Guard","AUC"),c("LIQ_Rank_Guard","Cox_raw","AUC"))) {
      metric<-pair[3]
      a<-se[model==pair[1],.(design,horizon,value=get(metric))]
      b<-se[model==pair[2],.(design,horizon,reference=get(metric))]
      dd<-merge(a,b,by=c("design","horizon"))[,.(delta=mean(value-reference)),by=design]
      sign<-if(metric=="Brier")-1 else 1
      ss[[length(ss)+1L]]<-data.table(Output=scoped_pretty(pair[1],ex$scope),Reference=pretty(pair[2]),Metric=metric,
        Designs=as.character(nrow(dd)),Better=as.character(sum(sign*dd$delta>1e-12)),
        Equal=as.character(sum(abs(dd$delta)<=1e-12)),Worse=as.character(sum(sign*dd$delta< -1e-12)),`Mean delta`=mean(dd$delta))
    }
    tab(liq_bind(ss),paste0("Sensitivity: increments over 81 designs (",ex$scope,")."),
      paste("Each design averages its available predeclared horizons; Hmax=20 designs omit 30 sessions. Better/equal/worse use a numerical tolerance of 1e-12. Designs reuse the same data and are not independent hypothesis tests.",
        archived_note(ex$scope,"This archived grid precedes v4.6.","The grid was generated by the current code; absent designs are not silently counted as completed.")),"T09_sensitivity",ex$scope)
  }
  sd<-NULL
  if(!is.null(sim)) {
    sm<-sim$data[,.(Brier=mean(Brier)),by=.(scenario,replication,model)]
    sd<-liq_bind(lapply(c("Cox_raw","Single_Brier_Guard"),function(ref) {
      a<-sm[model=="LIQ_Brier",.(scenario,replication,value=Brier)]
      b<-sm[model==ref,.(scenario,replication,reference=Brier)]
      d<-merge(a,b,by=c("scenario","replication"));d[,delta:=value-reference]
      d[,.(Reference=pretty(ref),N=as.character(.N),Delta=mean(delta),
        `MC lower`=mean(delta)-1.96*sd(delta)/sqrt(.N),`MC upper`=mean(delta)+1.96*sd(delta)/sqrt(.N)),by=scenario]
    }))
    tab(sd,paste0("Simulation paired Brier increments (",sim$scope,")."),
      paste("First average four horizons within each replication, then compute paired replication differences. Bounds are 95% normal Monte Carlo intervals for the mean paired difference across independent simulated replications, not empirical TEST risk intervals. Negative values favor the LIQ probability output.",
        archived_note(sim$scope,"These are archived v4.4 models.","These are fitted models from the current code; replication counts report actual paired completions.")),"T10_simulation",sim$scope)
  }
  if(!is.null(cov)) {
    cv<-cov$data[model=="LIQ_Brier",.(Mean=mean(coverage),Minimum=min(coverage),Maximum=max(coverage),
      `Min evaluable reps`=as.character(min(n_completed))),by=.(scenario,method)]
    tab(cv,paste0("Conditional-path interval coverage diagnostic (",cov$scope,")."),
      "Nominal coverage is 0.95; summary statistics span the four horizons. Algebraic identities are excluded. The target conditions on the realized simulated future covariate path. Marginal time-series intervals target a different quantity; these legacy undercoverage findings are retained and are not relabeled as corrected.","T11_legacy_coverage",cov$scope)
  }
  colors<-c("#0072B2","#D55E00","#009E73","#CC79A7","#666666")
  fig("F01_primary","Horizon-wise Brier score and AUC for frozen v4.6 primary predictions. The historical period has already been inspected; this is a reanalysis. Curves can overlap when outputs are identical.",function(){
    par(mfrow=c(1,2),mar=c(4,4,2,1),cex=.9)
    mods<-intersect(c("Cox_raw","CoxResidual_raw","LIQ_Brier","Logit_raw"),pt$model)
    for(met in c("Brier","AUC")) {
      vals<-pt[model%in%mods,get(met)];plot(range(cfg$horizons),range(vals,finite=TRUE),type="n",xlab="Horizon (trading sessions)",ylab=met)
      for(i in seq_along(mods)) {d<-pt[model==mods[i]][order(horizon)];lines(d$horizon,d[[met]],type="b",pch=i,lty=i,col=colors[i])}
      legend(if(met=="Brier")"topright"else"bottomright",pretty(mods),col=colors[seq_along(mods)],lty=seq_along(mods),pch=seq_along(mods),bty="n",cex=.8)
    }
  },scopes)
  fig("F02_increments","Paired v4.6 increments relative to the GUARD-selected single and Cox. Bars are family-adjusted calendar-batch t intervals under stationary influence-FCLT assumptions for marginal future-origin risk. Identity points are algebraic zero. Negative Brier and positive AUC favor the candidate.",function(){
    par(mfrow=c(2,2),mar=c(4,4,2.2,1),cex=.85)
    for(met in c("Brier","AUC"))for(ref in c("single","Cox_raw")) {
      d<-sn[family=="primary"&metric==met&if(ref=="single")grepl("^Single",reference)else reference==ref][order(horizon)]
      yr<-range(c(d$lower,d$upper,0),finite=TRUE);if(diff(yr)<1e-8)yr<-c(-.005,.005)
      plot(d$horizon,d$estimate,ylim=yr,pch=16,col=colors[1],xlab="Horizon (trading sessions)",ylab=paste("Delta",met),
        main=paste("vs",if(ref=="single")"selected single"else"Cox"));abline(h=0,col="grey65",lty=2)
      liq_draw_intervals(d$horizon,d$lower,d$upper,colors[1])
    }
  },scopes,height=6.2)
  fig("F03_reliability","Descriptive calibration of v4.6 probabilities. Points use quantile bins within the displayed TEST horizon; binning is descriptive and does not alter the fitted forecasts. The diagonal denotes perfect mean calibration. No independent-binomial uncertainty is asserted.",function(){
    par(mfrow=c(2,2),mar=c(4,4,2,1),cex=.85)
    e<-primary$blocks$TEST
    for(j in seq_along(cfg$horizons)) {
      plot(c(0,1),c(0,1),type="n",xlab="Mean forecast probability",ylab="Observed fraction",main=paste("Horizon",cfg$horizons[j]));abline(0,1,lty=2,col="grey65")
      mods<-intersect(c("Cox_raw","CoxResidual_raw","LIQ_Brier"),names(primary$heads$test))
      for(i in seq_along(mods)) {
        p<-primary$heads$test[[mods[i]]][,j];y<-liq_truth(e,cfg$horizons[j])$y
        br<-unique(quantile(p,seq(0,1,length.out=7)));bin<-if(length(br)>1L)findInterval(p,br,all.inside=TRUE)else rep(1L,length(p))
        z<-data.table(p=p,y=y,bin=bin)[,.(p=mean(p),y=mean(y)),by=bin][order(p)]
        lines(z$p,z$y,type="b",col=colors[i],pch=i,lty=i)
      }
      legend("topleft",c("Cox","Residual","LIQ-P")[seq_along(mods)],col=colors[seq_along(mods)],pch=seq_along(mods),lty=seq_along(mods),bty="n",cex=.8)
    }
  },scopes,height=6.2)
  if(!is.null(ex)&&nrow(roll))fig("F04_rolling",paste0("Rolling paired Brier increments versus Cox (",ex$scope,"). Only completed regular TEST windows are included; the appended overlapping tail is excluded. Each point averages horizons within a window. Negative values favor the displayed candidate. ",
    archived_note(ex$scope,"Archived outcomes do not evaluate v4.6.","Each window refits its daily transforms and models using its own preceding roles.")),function(){
    a<-roll[model%in%c("LIQ_Brier","Single_Brier_Guard","Cox_raw"),.(Brier=mean(Brier)),by=.(design,model)]
    w<-dcast(a,design~model,value.var="Brier");w<-w[order(design)];xx<-seq_len(nrow(w))
    yl<-range(c(0,w$LIQ_Brier-w$Cox_raw,w$Single_Brier_Guard-w$Cox_raw))
    par(mar=c(6,4,2,1),cex=.9);plot(xx,w$LIQ_Brier-w$Cox_raw,ylim=yl,type="b",pch=16,xaxt="n",xlab="",ylab="Mean delta Brier vs Cox",col=colors[1]);
    axis(1,xx,sub("^rolling_","",w$design),las=2,cex.axis=.8);abline(h=0,lty=2,col="grey65")
    lines(xx,w$Single_Brier_Guard-w$Cox_raw,type="b",pch=1,col=colors[2],lty=2)
    legend("topleft",c(scoped_pretty("LIQ_Brier",ex$scope),"Selected single"),col=colors[1:2],pch=c(16,1),lty=1:2,bty="n",cex=.8)
  },ex$scope)
  if(!is.null(sd))fig("F05_simulation",paste0("Simulation paired mean Brier differences (",sim$scope,"). Error bars are 95% Monte Carlo intervals across independent replications after averaging horizons. Negative values favor the LIQ probability output. These bars are not empirical TEST risk intervals."),function(){
    par(mfrow=c(2,1),mar=c(4,8.5,2,1),cex=.9)
    for(ref in unique(sd$Reference)) {
      d<-sd[Reference==ref][order(scenario)];yy<-seq_len(nrow(d))
      plot(d$Delta,yy,xlim=range(c(d$`MC lower`,d$`MC upper`,0)),yaxt="n",xlab="Mean delta Brier",ylab="",pch=16,col=colors[1],main=paste("vs",ref))
      axis(2,yy,gsub("_"," ",d$scenario),las=1,cex.axis=.85);abline(v=0,lty=2,col="grey65")
      keep<-is.finite(d$`MC lower`)&is.finite(d$`MC upper`)&d$`MC upper`-d$`MC lower`>1e-12
      if(any(keep))arrows(d$`MC lower`[keep],yy[keep],d$`MC upper`[keep],yy[keep],length=.03,angle=90,code=3,col=colors[1])
    }
  },sim$scope,height=6.2)
  if(!is.null(cov))fig("F06_legacy_coverage",paste0("Coverage for the probability head under the legacy conditional-path simulation target (",cov$scope,"). Horizontal line marks nominal 95%. Points report separate horizons; identity cases are excluded. Marginal self-normalized inference has a different target and does not erase these failures."),function(){
    par(mfrow=c(1,2),mar=c(7,4,2,1),cex=.85)
    z<-cov$data[model=="LIQ_Brier"];sc<-sort(unique(z$scenario))
    for(method_name in c("date_block","crossed_asset_date")) {
      d<-z[method==method_name];if(!nrow(d))d<-z[grepl(if(method_name=="date_block")"date_block"else"cross",method)]
      plot(c(.5,length(sc)+.5),c(.6,1),type="n",xaxt="n",xlab="",ylab="Coverage",main=gsub("_"," ",method_name));
      axis(1,seq_along(sc),gsub("_"," ",sc),las=2,cex.axis=.8);abline(h=.95,lty=2,col="grey50")
      for(j in seq_along(cfg$horizons)){a<-d[horizon==cfg$horizons[j]];points(match(a$scenario,sc)+(j-2.5)*.07,a$coverage,pch=j,col=colors[j])}
      legend("bottomleft",paste("H",cfg$horizons),pch=1:4,col=colors[1:4],bty="n",cex=.7)
    }
  },cov$scope)
  fig("F07_decisions","Decision value against the better fixed action for v4.6. Positive values favor the model at the declared cost ratio; values below zero indicate that a fixed action has lower cost. This is a scenario loss calculation, not a transaction-cost backtest.",function(){
    par(mar=c(4,4,2,1),cex=.9);yr<-range(c(dc$`Best fixed minus model`,0))
    plot(range(cfg$horizons),yr,type="n",xlab="Horizon (trading sessions)",ylab="Best fixed cost minus model cost");abline(h=0,lty=2,col="grey65")
    for(i in seq_along(cfg$cost_ratios)){d<-dc[Ratio==as.character(cfg$cost_ratios[i])];lines(as.integer(d$H),d$`Best fixed minus model`,type="b",col=colors[i],pch=i,lty=i)}
    legend("bottomleft",paste("Cost ratio",cfg$cost_ratios),col=colors[seq_along(cfg$cost_ratios)],pch=seq_along(cfg$cost_ratios),lty=seq_along(cfg$cost_ratios),bty="n",cex=.8)
  },scopes)
  diagnostic_file<-file.path(dirname(cfg$source_path),"VALIDATION","INFERENCE_V45","fixed_forecast_coverage.csv")
  if(file.exists(diagnostic_file)) {
    dg<-fread(diagnostic_file)
    dt<-dg[target=="marginal_future"&method%in%c("date_block","crossed_asset_date","SN_support_required"),
      .(Mean=if(any(is.finite(coverage)))mean(coverage,na.rm=TRUE)else NA_real_,
        Minimum=if(any(is.finite(coverage)))min(coverage,na.rm=TRUE)else NA_real_,
        Maximum=if(any(is.finite(coverage)))max(coverage,na.rm=TRUE)else NA_real_,
        `Reps per H`=as.character(min(n_available))),by=.(calendar_n,scenario,method)]
    dt[,calendar_n:=as.character(calendar_n)]
    # Keep the main diagnostic table short; all scenarios/horizons remain in CSV.
    liq_write_csv(dt,file.path(td,"inference_diagnostic_all_scenarios.csv"))
    tab(dt[method=="SN_support_required"],"Independent fixed-rule marginal coverage diagnostic (v4.6 development).",
      "400 independent replications per scenario and calendar length; four horizons. Mean/min/max summarize pointwise 95% intervals. Short-calendar SN intervals abstain because 20 origin dates and 96 sessions fail the fixed support rule; the longer calendar has 101 dates and 501 sessions. Fixed rules are not the fitted Cox/LIQ pipeline. Gaussian quadrature checks the marginal truth. Strong-dependence undercoverage remains; stationarity within each TEST segment does not establish robustness to abrupt breaks.","T12_SN_diagnostic","new fixed-rule diagnostic, not empirical-model validation")
    fig("F08_SN_diagnostic","Independent fixed-rule marginal coverage in the longer simulated TEST segment (101 origin dates, 501 sessions). Points show four horizons; the line marks nominal 95%. Each scenario has 400 independent replications. SN is self-normalization; the date and crossed intervals use 199 bootstrap draws. Strong-dependence undercoverage remains. This diagnostic does not validate the estimated-model pipeline or a nonstationary structural break.",function(){
      par(mfrow=c(1,3),mar=c(8,4,2,1),cex=.9,cex.main=.9)
      z<-dg[target=="marginal_future"&calendar_n==3600];sc<-sort(unique(z$scenario))
      methods<-c("date_block","crossed_asset_date","SN_support_required")
      for(m in methods) {
        d<-z[method==m]
        plot(c(.5,length(sc)+.5),c(.65,1),type="n",xaxt="n",xlab="",ylab="Coverage",main=c("Date block","Crossed asset/date","Self-normalized")[match(m,methods)])
        axis(1,seq_along(sc),gsub("_"," ",sc),las=2,cex.axis=.8);abline(h=.95,lty=2,col="grey50")
        for(j in seq_along(cfg$horizons)){a<-d[horizon==cfg$horizons[j]];points(match(a$scenario,sc)+(j-2.5)*.07,a$coverage,pch=j,col=colors[j])}
        legend("bottomleft",paste("H",cfg$horizons),pch=1:4,col=colors[1:4],bty="n",cex=.8)
      }
    },"new fixed-rule diagnostic, not empirical-model validation",height=5.2)
  }
  preamble<-c("\\documentclass[11pt,a4paper]{article}","\\usepackage[T1]{fontenc}","\\usepackage[utf8]{inputenc}",
    "\\usepackage{lmodern,booktabs,graphicx,amsmath,amssymb}","\\usepackage[margin=22mm]{geometry}",
    "\\usepackage[hidelinks]{hyperref}","\\newsavebox{\\LIQtablebox}","\\setlength{\\emergencystretch}{3em}",
    "\\setlength{\\parindent}{0pt}","\\setlength{\\parskip}{6pt}","\\begin{document}")
  opening<-c("\\title{LIQ-REC-Fin: revision tables and figures}","\\author{}\\date{25 October 2026}\\maketitle",
    "This booklet reports primary and robustness outputs with explicit version labels. If archived v4.4 robustness is used, it must be distinguished from the new v4.6 primary analysis. LIQ-P denotes the probability output and LIQ-R the rank output. This is a results insert, not a submission-ready replacement for the complete manuscript or reviewer response. The convenience panel and the historical TEST period have already been inspected.",
    "\\subsection*{Cox-anchored correction}",
    "Let $p^{C}_{ih}$ be the Cox probability and $z_i$ the fixed context basis. The candidate is $\\widetilde p_{ih}=\\operatorname{logit}^{-1}\\{\\operatorname{logit}(p^C_{ih})+\\gamma f_h(z_i)\\}$, followed by projection to a nondecreasing horizon CDF. Each ridge logistic $f_h$ uses the Cox logit as an offset, including the offset when predicting. Shared $(\\lambda,\\gamma)$ are selected by paired-difference one-standard-error meta-validation of six forward TRAIN folds with a preference for smaller $\\gamma$ and then stronger ridge. No CAL-FIT, GUARD or TEST label enters this fit. Gamma zero gives exactly Cox. CAL-FIT estimates isotonic calibration; GUARD chooses whether to retain the candidate using the existing margin and support rules.",
    "\\subsection*{Paired uncertainty and its limits}",
    "Primary intervals use two equal-calendar batches of centered paired influences, including zero-origin sessions. With pooled event count $N$, batch sums $U_g$ and $G=2$, set $s_B=\\sqrt{G\\sum_g U_g^2/(G-1)}/N$ and half-width $t_{G-1,1-0.05/(2K)}s_B$, clipped to the known difference range. The pooled point estimate is unchanged. AUC uses tie-aware two-sample influences. Require at least 40 origin dates and three maximum horizons per batch; short or degenerate series abstain. Validity is asymptotic under a stationary influence FCLT, negligible linearization remainder and independent Gaussian batch limits. It is not a guarantee under arbitrary dependence or structural breaks. Fitted models and panel are fixed; training and universe uncertainty are excluded. Old self-normalized intervals remain diagnostic outputs.",
    "Legacy simulation coverage conditions on the realized future covariate path, a different estimand from marginal future-origin risk. Its reported failures remain visible. Identity intervals are algebraic facts, not validation of interval coverage. Full new v4.6 rolling, sensitivity and estimated-model simulation runs remain to be completed unless corresponding newly generated tables replace the archived inputs.",
    "\\subsection*{Sources}",
    "Friedman, Hastie and Tibshirani (2010), Regularization Paths for Generalized Linear Models via Coordinate Descent, Journal of Statistical Software 33(1), doi:10.18637/jss.v033.i01. Ibragimov and Mueller (2010), t-Statistic Based Correlation and Heterogeneity Robust Inference, JBES 28(4), 453--468, doi:10.1198/jbes.2009.08046. Shao (2010), A self-normalized approach to confidence interval construction in time series, JRSS B 72, 343--366, doi:10.1111/j.1467-9868.2009.00737.x; see also the 2010 corrigendum and the author's 2015 review for assumptions and limitations.","\\clearpage")
  body<-unlist(lapply(c(tables,figures),function(x)c(x,"\\clearpage")))
  writeLines(c(preamble,opening,body,"\\end{document}"),file.path(pub,"LIQ_REC_tables_and_figures.tex"))
  writeLines(c(preamble,unlist(lapply(tables,function(x)c(x,"\\clearpage"))),"\\end{document}"),file.path(pub,"LIQ_REC_tables_only.tex"))
  liq_write_csv(liq_bind(sources),file.path(pub,"PUBLICATION_PROVENANCE.csv"))
  writeLines(c("Compile from this directory: pdflatex LIQ_REC_tables_and_figures.tex (twice).",
    "Tables are complete LaTeX environments, directly embedded in both master files; no table input files are required.",
    "Individual PDF figures are vector artwork; PNG figures are 300 dpi. Captions state scope/version.",
    "Archived v4.4 robustness must not be presented as validation of new v4.6 code.",
    "CSV table sources preserve full numerical precision; displayed tables round only at export."),file.path(pub,"README.txt"))
  invisible(pub)
}



# Equal-calendar batch linearization of the pooled paired estimator.
# Fixed fitted rules/panel; stationary influence FCLT and independent Gaussian
# batch limits. No finite-sample, arbitrary-dependence or training guarantee.
liq_nested_inner <- function(raw_features,calendar,cfg,fold,variant,nonoverlap,regime_source) {
  base<-liq_nested_inner_v450(raw_features,calendar,cfg,fold,variant,nonoverlap,regime_source)
  cc<-cfg;cc$inner_fractions<-cfg$correction_inner_fractions
  base$correction<-liq_nested_inner_v450(raw_features,calendar,cc,fold,variant,nonoverlap,regime_source)
  base
}
liq_batch_interval <- function(e,calendar,influence,estimate,cfg,K=1L,identity=FALSE,auc=FALSE,y=NULL) {
  G<-as.integer(cfg$batch_groups);idx<-match(e$shock_date,calendar)
  T<-if(length(idx)&&all(is.finite(idx)))max(idx)-min(idx)+1L else 0L
  critical<-qt(1-.05/(2*K),df=G-1L)
  z<-list(estimate=estimate,lower=NA_real_,upper=NA_real_,supported=FALSE,
    reason="insufficient calendar span, origin dates, or finite influence",
    n_dates=uniqueN(e$shock_date),calendar_span=T,groups=G,
    min_batch_sessions=if(T)floor(T/G)else 0L,standard_error=NA_real_,critical=critical)
  if(isTRUE(identity)&&is.finite(estimate)) {
    z$lower<-z$upper<-0;z$supported<-TRUE
    z$reason<-"algebraically identical fitted sources; excluded from coverage successes";return(z)
  }
  if(!is.finite(estimate)||!length(influence)||any(!is.finite(influence))||
     z$n_dates<cfg$sn_min_dates||T==0L||floor(T/G)<cfg$batch_min_H*cfg$max_h)return(z)
  group<-pmin(G-1L,floor((idx-min(idx))*G/T))+1L
  if(min(tabulate(group,nbins=G))<8L){z$reason<-"fewer than eight event rows in a calendar batch";return(z)}
  if(auc&&(is.null(y)||min(sum(y==1),sum(y==0))<10L||
    min(uniqueN(e$shock_date[y==1]),uniqueN(e$shock_date[y==0]))<10L)) {
    z$reason<-"insufficient AUC class or class-date support";return(z)
  }
  totals<-as.numeric(rowsum(influence-mean(influence),group,reorder=TRUE))
  se<-sqrt(G/(G-1L)*sum(totals^2))/length(influence)
  if(!is.finite(se)||se<1e-10){z$reason<-"degenerate batch influence; no stochastic interval";return(z)}
  z$standard_error<-se;bounds<-estimate+c(-1,1)*critical*se
  z$lower<-max(-1,bounds[1]);z$upper<-min(1,bounds[2]);z$supported<-TRUE
  z$reason<-"asymptotic stationary influence FCLT with independent Gaussian calendar-batch limits"
  z
}
liq_batch_pairs <- function(e,pred,cfg,calendar,choices=NULL,correction=NULL) {
  old<-liq_sn_pairs(e,pred,cfg,calendar,choices,correction)
  rows<-lapply(seq_len(nrow(old)),function(i) {
    r<-old[i];j<-match(r$horizon,cfg$horizons);y<-liq_truth(e,r$horizon)$y;ok<-is.finite(y)
    p<-pred[[r$model]][ok,j];q<-pred[[r$reference]][ok,j];a<-r$metric=="AUC"
    inf<-if(a)liq_auc_influence(y[ok],p)-liq_auc_influence(y[ok],q)else (p-y[ok])^2-(q-y[ok])^2
    iv<-liq_batch_interval(e[ok],calendar,inf,r$estimate,cfg,r$family_size,r$algebraic_identity,a,y[ok])
    meta<-r[,.(model,reference,metric,horizon,family,family_size,identical_output,algebraic_identity,target)]
    cbind(meta,as.data.table(iv))
  });liq_bind(rows)
}
liq_save_rds_atomic <- function(object,path) {
  # Explicitly flush and validate before replacing any checkpoint.
  tmp<-paste0(path,".tmp");raw<-serialize(object,NULL,version=3)
  con<-file(tmp,"wb");on.exit(if(isOpen(con))close(con),add=TRUE)
  starts<-seq.int(1L,length(raw),by=1048576L)
  for(a in starts)writeBin(raw[a:min(length(raw),a+1048575L)],con)
  close(con);on.exit(NULL,add=FALSE)
  liq_assert(file.info(tmp)$size==length(raw),"Incomplete checkpoint byte count.")
  restored<-readRDS(tmp)
  liq_assert(isTRUE(all.equal(restored,object,tolerance=0,check.attributes=FALSE)),"Checkpoint roundtrip differs.")
  liq_assert(file.rename(tmp,path),"Cannot atomically commit checkpoint.")
  invisible(path)
}

liq_require_simulation_support <- function(e,blocks,cfg) {
  minimum<-c(TRAIN=cfg$min_train,CAL_FIT=cfg$min_cal,GUARD=cfg$min_guard,TEST=30L)
  for(r in names(blocks))liq_need(nrow(blocks[[r]])>=minimum[r],
    paste("Simulation",r,"count",nrow(blocks[[r]]),"required",minimum[r],"No pooling or threshold relaxation."))
  support<-liq_class_support(e,cfg)
  bad<-support[role%in%c("CAL_FIT","GUARD")&class_supported==FALSE]
  liq_need(!nrow(bad),paste("Simulation CAL/GUARD class support failed:",
    paste(bad$role,bad$horizon,bad$positive,bad$negative,collapse="; "),"No pooling or threshold relaxation."))
  invisible(TRUE)
}




# v4.7.0: experiment protocol and diagnostics; fitted forecasting rules unchanged.
liq_config_v460 <- liq_config
liq_config <- function() {
  prior_mode<-Sys.getenv("LIQ_MODE",unset=NA_character_)
  Sys.setenv(LIQ_MODE="full")
  on.exit(if(is.na(prior_mode))Sys.unsetenv("LIQ_MODE")else Sys.setenv(LIQ_MODE=prior_mode),add=TRUE)
  cfg<-liq_config_v460();root<-dirname(cfg$source_path)
  cfg$version<-"4.7.0";cfg$frozen_file<-""
  cfg$simulation_days<-as.integer(Sys.getenv("LIQ_V470_SIM_DAYS","3600"))
  cfg$out_dir<-Sys.getenv("LIQ_V470_OUT_DIR",file.path(root,"out_liq_rec_v4_7_0_pilot"))
  cfg
}
liq_v470_config <- function(stage=c("pilot","full")) {
  stage<-match.arg(stage);cfg<-liq_config();cfg$mode<-"full";cfg$data_mode<-"csv"
  cfg$stage<-stage;cfg$seed<-if(stage=="pilot")4700000L else 5700000L
  cfg$oracle_seed<-if(stage=="pilot")14700000L else 15700000L
  cfg$simulation_reps<-as.integer(Sys.getenv(if(stage=="pilot")"LIQ_V470_PILOT_REPS"else"LIQ_V470_FULL_REPS",if(stage=="pilot")"2"else"100"))
  cfg$oracle_batches<-as.integer(Sys.getenv("LIQ_V470_ORACLE_BATCHES","8"))
  cfg$oracle_origins<-as.integer(Sys.getenv("LIQ_V470_ORACLE_ORIGINS",if(stage=="pilot")"250"else"2000"))
  cfg$conditional_boot_reps<-as.integer(Sys.getenv("LIQ_V470_BOOT_REPS",if(stage=="pilot")"39"else"199"))
  cfg$export_large<-identical(tolower(Sys.getenv("LIQ_V470_EXPORT_LARGE","false")),"true")
  cfg$simulation_scenarios<-c("signal","no_regime","prevalence_shift","regime_reversal","non_PH","strong_dependence")
  cfg$out_dir<-Sys.getenv("LIQ_V470_OUT_DIR",file.path(dirname(cfg$source_path),paste0("out_liq_rec_v4_7_0_",stage)))
  cfg$reference_dir<-Sys.getenv("LIQ_V460_RESULTS_DIR",file.path(dirname(cfg$source_path),"REFERENCE_V460"))
  cfg$run_sensitivity<-cfg$run_rolling<-cfg$run_ablations<-cfg$run_panel_checks<-FALSE
  liq_assert(cfg$simulation_days>=900L&&cfg$simulation_assets==6L,"Use the declared calendar and six fixed simulated assets.")
  liq_assert(cfg$simulation_reps>=1L&&cfg$simulation_reps<=999L,"Simulation repetitions must be 1..999.")
  liq_assert(cfg$oracle_batches>=4L&&cfg$oracle_batches<=50L&&cfg$oracle_origins>=50L,"Oracle requires >=4 independent batches and >=50 origins per batch.")
  liq_assert(cfg$conditional_boot_reps>=19L,"Conditional bootstrap requires >=19 draws.")
  cfg
}
liq_v470_protocol_key <- function(cfg) {
  liq_hash(list(source=unname(tools::md5sum(cfg$source_path)),version=cfg$version,
    sessions=cfg$simulation_days,assets=cfg$simulation_assets,H=cfg$horizons,
    correction_grid=list(cfg$correction_lambda_grid,cfg$correction_gamma_grid),
    fractions=cfg$correction_inner_fractions,groups=cfg$batch_groups,minH=cfg$batch_min_H,
    minimums=c(cfg$min_train,cfg$min_cal,cfg$min_guard,cfg$min_class,cfg$sn_min_dates),
    guard=c(cfg$guard_margin_z,cfg$guard_min_gain,cfg$rank_min_gain),
    oracle="independent stationary origin feature draws; fixed asset effects and TRAIN regime cuts; Monte Carlo proxy"))
}
liq_v470_blocks <- function(d) {
  b<-lapply(c("TRAIN","CAL_FIT","GUARD","TEST"),function(r)d$events[role==r&analysis_eligible==TRUE])
  names(b)<-c("TRAIN","CAL_FIT","GUARD","TEST");b
}
liq_v470_opportunity <- function(d,cfg) {
  b<-liq_v470_blocks(d);cc<-cfg;cc$inner_fractions<-cfg$correction_inner_fractions
  splits<-liq_inner_splits(b$TRAIN,cc);nd<-uniqueN(b$TEST$shock_date)
  span<-if(nrow(b$TEST))max(b$TEST$sid)-min(b$TEST$sid)+1L else 0L
  data.table(n_TRAIN=nrow(b$TRAIN),n_CAL_FIT=nrow(b$CAL_FIT),n_GUARD=nrow(b$GUARD),n_TEST=nrow(b$TEST),
    forward_period_opportunities=length(splits),meta_period_opportunities=max(0L,length(splits)-1L),
    TEST_origin_dates=nd,TEST_calendar_span=span,min_batch_sessions=floor(span/cfg$batch_groups),
    calendar_opportunity=nd>=cfg$sn_min_dates&&floor(span/cfg$batch_groups)>=cfg$batch_min_H*cfg$max_h,
    multiple_forward_periods=length(splits)>=3L)
}
liq_v470_preflight <- function(cfg,out=file.path(cfg$out_dir,"preflight")) {
  liq_dir(out);rows<-counts<-list()
  for(sc in cfg$simulation_scenarios) {
    liq_log("Long-calendar preflight",sc)
    d<-liq_simulated_events(cfg,sc,1L);b<-liq_v470_blocks(d)
    support<-tryCatch({liq_require_simulation_support(d$events,b,cfg);"supported"},error=function(e)conditionMessage(e))
    x<-liq_v470_opportunity(d,cfg);x[,`:=`(scenario=sc,class_support=support)]
    rows[[sc]]<-x;cc<-liq_class_support(d$events,cfg);cc[,scenario:=sc];counts[[sc]]<-cc
  }
  z<-liq_bind(rows);liq_write_csv(z,file.path(out,"P470_calendar_and_fold_opportunities.csv"))
  liq_write_csv(liq_bind(counts),file.path(out,"P470_role_class_counts.csv"))
  liq_assert(all(z$calendar_opportunity&z$multiple_forward_periods),
    "Calendar is too short for the declared experiment; inspect preflight. No thresholds were relaxed.")
  # This checks opportunities, not positive gamma, nominal coverage, or superiority.
  z
}
liq_v470_correction_status <- function(cand,cfg) {
  f<-cand$fits$Correction
  if(is.null(f))return(data.table(fit_type="unavailable",gamma=NA_real_,lambda=NA_real_,n_oof=0L,
    valid_forward_periods=0L,valid_meta_periods=0L,finite_validation_losses=0L,
    active=FALSE,selection_reason="Cox unavailable; correction not attempted"))
  nf<-if(is.null(f$audit))0L else nrow(f$audit)
  nm<-if(is.null(f$validation)||!nrow(f$validation))0L else uniqueN(f$validation$inner_fold)
  nv<-if(is.null(f$validation))0L else sum(is.finite(f$validation$mean_Brier))
  reason<-if(f$type!="ridge")"identity: insufficient residual-training support"else
    if(nm==0L)"zero fallback: no valid meta-validation periods"else
      if(f$gamma==0)"zero chosen by valid TRAIN paired one-SE rule"else"nonzero chosen by valid TRAIN paired one-SE rule"
  data.table(fit_type=f$type,gamma=f$gamma,lambda=f$lambda,n_oof=f$n_oof,
    valid_forward_periods=nf,valid_meta_periods=nm,finite_validation_losses=nv,
    active=f$type=="ridge"&&f$gamma>0,selection_reason=reason)
}
liq_v470_frozen_predictions <- function(cand,train,new,choices,cfg) {
  p<-liq_fitted_candidate_predictions(cand,train,new,cfg);H<-cfg$horizons
  for(nm in c("Single_Brier_Guard","Single_Rank_Guard","LIQ_Brier","LIQ_Rank_Guard")) {
    ans<-matrix(NA_real_,nrow(new),length(H),dimnames=list(NULL,H))
    for(j in seq_along(H)) {
      local_head<-nm;local_h<-H[j];ch<-choices[head==local_head&horizon==local_h]
      liq_assert(nrow(ch)==1L,paste("Frozen head needs one choice:",nm,H[j]))
      src<-if(nm=="LIQ_Brier"&&!is.na(ch$selected_source))ch$selected_source else ch$component1
      liq_assert(src%in%names(p),paste("Unknown frozen component:",src));ans[,j]<-p[[src]][,j]
    }
    p[[nm]]<-ans
  };p
}
liq_v470_oracle_origins <- function(context,cfg,n,seed) {
  # IID stationary origin clusters. Within each cluster all fixed assets share
  # the same market tuple. No observed TEST path, label, or new fitting is used.
  set.seed(seed);A<-cfg$simulation_assets;N<-n*A
  lag<-c(0,1,5);S<-.9^abs(outer(lag,lag,"-"))
  m<-matrix(rnorm(n*3L),nrow=n)%*%chol(S)
  aa<-rep(seq_len(A),times=n);ii<-rep(seq_len(n),each=A)
  market<-m[ii,1];lag1<-m[ii,2];lag5<-m[ii,3];x<-rnorm(N)
  e<-as.data.table(setNames(lapply(liq_feature_names(),function(z)rep(0,N)),liq_feature_names()))
  e[,`:=`(lsi=2+abs(x),lsi_lag1=1+abs(x),lsi_mom5=x,shock_severity_pct=pnorm(x),
    abs_ret=abs(rnorm(N,.01,.005)),absret5=.01,rv5=.0001,range_pct=.02+abs(x)*.005,
    volume_shock=-x,pressure=pmax(x,0)*.02,log_dvol=16+x*.2,market_loo=market,
    market_loo_lag1=lag1,market_full=market,market_trend5=market-lag5,market_percentile=pnorm(market),
    shock_cluster_share=plogis(market),shock_cluster_share_lag1=plogis(lag1),
    volume_breadth_lag1=plogis(lag1),avg_corr_lag1=.3,vix_lag1=20+3*market,
    vix_change5=3*(market-lag5),is_stock=as.numeric(aa>A/2),is_sector=as.numeric(aa<=A/2),
    asset=paste0("A",aa),oracle_origin=ii)]
  cuts<-context$regime_cuts;e[,regime:=ifelse(market_loo<=cuts[1],"Low",ifelse(market_loo<=cuts[2],"Normal","High"))]
  beta<-if(context$scenario=="no_regime")0 else if(context$scenario=="regime_reversal")-.75 else .75
  offset<-if(context$scenario=="prevalence_shift")1.1 else 0
  survival<-rep(1,N);q<-matrix(NA_real_,N,length(cfg$horizons),dimnames=list(NULL,cfg$horizons))
  for(day in seq_len(cfg$max_h)) {
    effect<-if(context$scenario=="non_PH")if(day<=10).9 else -.9 else .65
    hz<-plogis(qlogis(.045)+effect*x+beta*market+context$asset_effect[aa]+offset)
    if(day>=cfg$k)survival<-survival*(1-hz)
    if(day%in%cfg$horizons)q[,match(day,cfg$horizons)]<-1-survival
  }
  list(events=e,q=q)
}
liq_v470_soft_auc <- function(q,score) {
  d<-data.table(q=q,s=score)[,.(positive=sum(q),negative=sum(1-q)),by=s][order(s)]
  den<-sum(d$positive)*sum(d$negative)
  if(!is.finite(den)||den<=0)return(NA_real_)
  sum(d$positive*(cumsum(d$negative)-d$negative+.5*d$negative))/den
}
liq_v470_oracle_metrics <- function(q,pred,pairs,cfg) {
  vapply(seq_len(nrow(pairs)),function(i) {
    r<-pairs[i];j<-match(r$horizon,cfg$horizons);p<-pred[[r$model]][,j];b<-pred[[r$reference]][,j]
    if(r$metric=="Brier")mean((p-q[,j])^2-(b-q[,j])^2)else
      liq_v470_soft_auc(q[,j],p)-liq_v470_soft_auc(q[,j],b)
  },numeric(1))
}
liq_v470_marginal_oracle <- function(cand,train,choices,context,intervals,cfg,replication) {
  draws<-vector("list",cfg$oracle_batches);qs<-pp<-vector("list",cfg$oracle_batches)
  needed<-unique(c(intervals$model,intervals$reference))
  for(b in seq_len(cfg$oracle_batches)) {
    z<-liq_v470_oracle_origins(context,cfg,cfg$oracle_origins,
      cfg$oracle_seed+100L*replication+b)
    p<-liq_v470_frozen_predictions(cand,train,z$events,choices,cfg)[needed]
    qs[[b]]<-z$q;pp[[b]]<-p
    draws[[b]]<-liq_v470_oracle_metrics(z$q,p,intervals,cfg)
  }
  mm<-do.call(rbind,draws)
  pooled<-setNames(lapply(needed,function(nm)do.call(rbind,lapply(pp,`[[`,nm))),needed)
  oracle_values<-liq_v470_oracle_metrics(do.call(rbind,qs),pooled,intervals,cfg)
  se<-apply(mm,2,sd)/sqrt(nrow(mm));half<-qt(.995,df=nrow(mm)-1L)*se
  z<-copy(intervals);z[,`:=`(oracle_estimate=oracle_values,oracle_MC_SE=se,
    oracle_lower_99=pmax(-1,oracle_values-half),oracle_upper_99=pmin(1,oracle_values+half),
    oracle_batches=cfg$oracle_batches,oracle_origins_per_batch=cfg$oracle_origins,
    oracle_target="stationary marginal future-origin risk; learned frozen rules and fixed simulated asset effects; independent Monte Carlo proxy")]
  z[,eligible_for_coverage:=supported&!algebraic_identity&is.finite(lower)&is.finite(upper)&is.finite(oracle_estimate)]
  z[,oracle_point_covered:=fifelse(eligible_for_coverage,lower<=oracle_estimate&upper>=oracle_estimate,NA)]
  z[,covered_for_entire_oracle_band:=fifelse(eligible_for_coverage,lower<=oracle_lower_99&upper>=oracle_upper_99,NA)]
  z[,miss_for_entire_oracle_band:=fifelse(eligible_for_coverage,upper<oracle_lower_99|lower>oracle_upper_99,NA)]
  z[,oracle_ambiguous:=fifelse(eligible_for_coverage,!covered_for_entire_oracle_band&!miss_for_entire_oracle_band,NA)]
  z[,oracle_halfwidth_over_interval_width:=fifelse(eligible_for_coverage&upper>lower,half/(upper-lower),NA_real_)]
  batches<-as.data.table(mm);setnames(batches,paste0("row_",seq_len(ncol(mm))))
  batches[,oracle_batch:=.I]
  batches<-melt(batches,id.vars="oracle_batch",variable.name="row",value.name="oracle_batch_delta")
  batches[,pair_row:=as.integer(sub("row_","",row,fixed=TRUE))]
  data.table::setattr(z,"oracle_batch_deltas",batches)
  z
}
liq_v470_conditional_bootstrap <- function(d,b,hd,cfg,replication) {
  ans<-list();tests<-intersect(c("LIQ_Brier","Logit_cal","Regime_cal"),names(hd$test))
  for(crossed in c(FALSE,TRUE)) {
    method<-if(crossed)"crossed_asset_date"else"date_block"
    w<-liq_boot_weights(b$TEST,d$calendar,cfg$conditional_boot_reps,cfg$block_length,
      cfg$seed+replication+if(crossed)10000L else 0L,crossed=crossed)
    for(j in seq_along(cfg$horizons)) {
      h<-cfg$horizons[j];oo<-d$oracle[horizon==h]
      q<-oo$true_probability[match(b$TEST$event_id,oo$event_id)]
      y<-liq_truth(b$TEST,h)$y;reference<-hd$test$Regime_cal[,j]
      for(nm in tests) {
        p<-hd$test[[nm]][,j];loss<-(p-y)^2-(reference-y)^2
        exact<-mean((p-q)^2-(reference-q)^2);iv<-liq_interval(colSums(w*loss)/colSums(w))
        same<-identical(as.numeric(p),as.numeric(reference))
        ans[[length(ans)+1L]]<-data.table(model=nm,horizon=h,method=method,
          true_conditional_delta_Brier=exact,estimate=mean(loss),lower=iv[1],upper=iv[2],
          identical_output=same,eligible_for_coverage=!same,covered=if(!same&&all(is.finite(iv[1:2])))iv[1]<=exact&&iv[2]>=exact else NA,
          interpretation="conditional realized-feature-path Brier target; separate from the marginal oracle")
      }
    }
  };liq_bind(ans)
}
liq_run_simulation_v460 <- liq_run_simulation
liq_run_simulation <- function(cfg,run) {
  values<-list()
  for(sc in cfg$simulation_scenarios)for(replication in seq_len(cfg$simulation_reps)) {
    id<-sprintf("simulation_%s_%03d",sc,replication)
    value<-run(id,"simulation",function(path) {
      d<-liq_simulated_events(cfg,sc,replication);b<-liq_v470_blocks(d)
      liq_save(liq_class_support(d$events,cfg),"role_class_support",path)
      opportunity<-liq_v470_opportunity(d,cfg);liq_save(opportunity,"calendar_and_fold_opportunities",path)
      liq_require_simulation_support(d$events,b,cfg)
      cand<-liq_candidates(b$TRAIN,b$CAL_FIT,b$GUARD,b$TEST,cfg);hd<-liq_heads(cand,b$GUARD,cfg)
      cs<-liq_v470_correction_status(cand,cfg);liq_save(cs,"correction_status",path)
      liq_save(cand$fits$Correction$tuning,"correction_TRAIN_tuning",path)
      liq_save(cand$fits$Correction$validation,"correction_meta_validation",path)
      liq_save(cand$fits$Correction$audit,"correction_forward_audit",path)
      liq_save(hd$choices,"selected_components",path);liq_save(hd$gate,"GUARD_gate",path)
      check<-liq_v470_frozen_predictions(cand,b$TRAIN,b$TEST,hd$choices,cfg)
      check_names<-intersect(names(check),names(hd$test))
      err<-max(vapply(check_names,function(nm)max(abs(check[[nm]]-hd$test[[nm]])),numeric(1)))
      liq_assert(err<1e-12,"Frozen oracle predictor does not reproduce TEST forecasts.")
      liq_save(data.table(check="Frozen predictor reproduces observed TEST",pass=err<1e-12,max_abs_difference=err),"frozen_prediction_check",path)
      pt<-liq_evaluate(b$TEST,hd$test,cfg,hd$rank_names)
      bi<-liq_batch_pairs(b$TEST,hd$test,cfg,d$calendar,hd$choices,cand$fits$Correction)
      oracle<-liq_v470_marginal_oracle(cand,b$TRAIN,hd$choices,d$dgp_context,bi,cfg,replication)
      conditional<-liq_v470_conditional_bootstrap(d,b,hd,cfg,replication)
      for(nm in c("pt","bi","oracle","conditional","cs","opportunity")) {
        z<-get(nm);z[,`:=`(scenario=sc,replication=replication)];assign(nm,z)
      }
      liq_save(pt,"performance",path);liq_save(bi,"calendar_batch_paired_intervals",path)
      liq_save(oracle,"marginal_oracle_coverage",path);liq_save(conditional,"conditional_interval_coverage",path)
      liq_save(attr(oracle,"oracle_batch_deltas"),"oracle_MC_batch_deltas",path)
      liq_save(liq_long_predictions(b$TEST,hd$test,cfg,hd$rank_names),"frozen_test_predictions",path)
      liq_save(d$events,"events",path);liq_save(d$oracle,"oracle_probabilities",path)
      saveRDS(list(candidates=cand,choices=hd$choices,context=d$dgp_context),file.path(path,"fitted_rules.rds"))
      list(point=pt,batch=bi,oracle=oracle,conditional=conditional,correction=cs,opportunity=opportunity)
    },signature=list(cfg=cfg,scenario=sc,replication=replication,oracle_design="independent-origin-MC-v470"))
    if(!is.null(value))values[[id]]<-value
  }
  liq_v470_simulation_summary(values,cfg)
  invisible(values)
}
liq_v470_simulation_summary <- function(values,cfg) {
  if(!length(values))return(invisible(NULL))
  d<-lapply(c("point","batch","oracle","conditional","correction","opportunity"),function(nm)liq_bind(lapply(values,`[[`,nm)))
  names(d)<-c("point","batch","oracle","conditional","correction","opportunity")
  files<-c(point="S01_all_simulation_replications",batch="S05_calendar_batch_paired_intervals",
    oracle="S47001_marginal_oracle_replications",conditional="S03_interval_coverage_replications",
    correction="S47002_correction_status",opportunity="S47003_calendar_opportunities")
  for(nm in names(d))liq_save(d[[nm]],files[nm],cfg$out_dir)
  ll<-melt(d$point,id.vars=c("scenario","replication","model","horizon"),measure.vars=c("Brier","AUC"),variable.name="metric",value.name="value")
  liq_save(ll[,.(n_completed=sum(is.finite(value)),mean=liq_mean(value),mc_se=if(sum(is.finite(value))>1)sd(value[is.finite(value)])/sqrt(sum(is.finite(value)))else NA_real_),by=.(scenario,model,horizon,metric)],"S02_simulation_summary",cfg$out_dir)
  liq_save(d$batch[,.(n_total=.N,n_algebraic=sum(algebraic_identity),n_stochastic_supported=sum(supported&!algebraic_identity),n_abstained=sum(!supported)),by=.(scenario,model,reference,metric,horizon)],"S06_calendar_batch_support_summary",cfg$out_dir)
  z<-d$oracle[,{
    ok<-eligible_for_coverage;n<-sum(ok);p<-if(n)mean(oracle_point_covered[ok])else NA_real_
    den<-1+1.96^2/max(n,1);centre<-(p+1.96^2/(2*max(n,1)))/den
    half<-1.96*sqrt(p*(1-p)/max(n,1)+1.96^2/(4*max(n,1)^2))/den
    .(attempted_supported_fits=.N,n_algebraic=sum(algebraic_identity),n_stochastic=n,
      n_abstained=sum(!supported),oracle_point_coverage=p,replication_Wilson_lower=if(n)max(0,centre-half)else NA_real_,
      replication_Wilson_upper=if(n)min(1,centre+half)else NA_real_,
      entire_oracle_band_covered=if(n)mean(covered_for_entire_oracle_band[ok])else NA_real_,
      entire_oracle_band_missed=if(n)mean(miss_for_entire_oracle_band[ok])else NA_real_,
      n_oracle_ambiguous=sum(oracle_ambiguous[ok]),mean_oracle_MC_SE=liq_mean(oracle_MC_SE[ok]),
      mean_interval_width=liq_mean((upper-lower)[ok]))
  },by=.(scenario,model,reference,metric,horizon)]
  liq_save(z,"S47004_marginal_oracle_summary",cfg$out_dir)
  liq_save(d$conditional[,.(n_total=.N,n_identity=sum(identical_output),n_evaluable=sum(!is.na(covered)),
    coverage=if(any(!is.na(covered)))mean(covered,na.rm=TRUE)else NA_real_),by=.(scenario,model,horizon,method)],"S04_interval_coverage_summary",cfg$out_dir)
  liq_save(d$correction[,.(completed=.N,active=sum(active),valid_zero=sum(gamma==0&valid_meta_periods>0,na.rm=TRUE),
    no_meta_fallback=sum(valid_meta_periods==0),min_forward=min(valid_forward_periods),min_meta=min(valid_meta_periods)),by=scenario],"S47005_correction_scope_summary",cfg$out_dir)
}
liq_v470_reference_read <- function(directory,name,compact) {
  a<-file.path(directory,"tables",paste0(name,".csv"));b<-file.path(directory,compact)
  p<-if(file.exists(a))a else b
  liq_assert(file.exists(p),paste("Reference result missing:",p));fread(p)
}
liq_v470_rolling_diagnostics <- function(cfg) {
  ref<-cfg$reference_dir;out<-file.path(cfg$out_dir,"rolling_diagnostics");liq_dir(out)
  manifest<-file.path(ref,"REFERENCE_MD5.csv")
  if(file.exists(manifest)) {
    m<-fread(manifest);actual<-unname(tools::md5sum(file.path(ref,m$file)))
    liq_assert(all(actual==m$md5),"Bundled v4.6.0 reference integrity failed.")
  }
  g<-liq_v470_reference_read(ref,"G02_all_completed_extended_results","rolling_performance.csv")
  schedule<-liq_v470_reference_read(ref,"R01_rolling_schedule","rolling_schedule.csv")
  g<-g[design%in%schedule$design];g<-merge(g,schedule[,.(design,window_role=rolling_role)],by="design",all.x=TRUE)
  models<-c("Cox_raw","CoxResidual_raw","Single_Brier_Guard","LIQ_Brier","Single_Rank_Guard","LIQ_Rank_Guard")
  per<-g[model%in%models,.(Brier=liq_mean(Brier),AUC=liq_mean(AUC)),by=.(design,window_role,model)]
  regular<-per[window_role=="regular",.(Brier=liq_mean(Brier),AUC=liq_mean(AUC),n_windows=uniqueN(design)),by=model]
  anchor<-per[model=="Cox_raw",.(design,Cox_Brier=Brier,Cox_AUC=AUC)]
  delta<-merge(per,anchor,by="design");delta[,`:=`(delta_Brier=Brier-Cox_Brier,delta_AUC=AUC-Cox_AUC,
    interpretation="read-only v4.6.0 retrospective attribution; overlapping windows are not independent")]
  gatefile<-file.path(ref,"rolling_gate.csv")
  if(file.exists(gatefile))gate<-fread(gatefile)else gate<-liq_bind(lapply(schedule$design,function(id) {
    p<-file.path(ref,"tasks",id,"tables","A30_GUARD_probability_gate.csv")
    if(!file.exists(p))return(NULL);z<-fread(p);z[,design:=id];z
  }))
  if(nrow(gate))delta<-merge(delta,gate,by="design",all.x=TRUE)
  liq_write_csv(per,file.path(out,"R47001_per_window.csv"))
  liq_write_csv(regular,file.path(out,"R47002_regular_summary.csv"))
  liq_write_csv(delta,file.path(out,"R47003_Cox_differences_and_GUARD_choices.csv"))
  writeLines(c("These are the supplied v4.6.0 rolling results, not new v4.7.0 market-data refits.",
    "Regular-window and appended-tail summaries remain separate. No TEST outcomes tune a model or gate.",
    "The raw correction and final heads are shown separately; no pooled standard errors across overlapping windows."),file.path(out,"SCOPE.txt"))
  invisible(regular)
}
liq_v470_tex_table <- function(d,path,caption,label) {
  escape<-function(x)gsub("_","\\_",as.character(x),fixed=TRUE)
  cells<-lapply(d,function(x)if(is.numeric(x))ifelse(is.finite(x),formatC(x,digits=6,format="f"),"--")else escape(x))
  body<-vapply(seq_len(nrow(d)),function(i)paste0(paste(vapply(cells,`[`,character(1),i),collapse=" & ")," \\\\"),character(1))
  writeLines(c("\\begin{table}[p]","\\centering\\small",paste0("\\caption{",caption,"}"),paste0("\\label{",label,"}"),
    paste0("\\begin{tabular}{",paste0(c("l",rep("r",ncol(d)-1L)),collapse=""),"}"),"\\toprule",
    paste0(paste(escape(names(d)),collapse=" & ")," \\\\") ,"\\midrule",body,"\\bottomrule","\\end{tabular}","\\end{table}"),path)
}
liq_v470_export <- function(cfg) {
  pub<-liq_dir(file.path(cfg$out_dir,"publication"))
  rp<-file.path(cfg$out_dir,"rolling_diagnostics","R47002_regular_summary.csv")
  roll<-if(file.exists(rp))fread(rp)else NULL
  scope<-fread(file.path(cfg$out_dir,"tables","S47005_correction_scope_summary.csv"))
  if(!is.null(roll))liq_v470_tex_table(roll,file.path(pub,"T47001_rolling_attribution.tex"),"Supplied v4.6.0 regular rolling results: correction and final selection.","tab:v470_rolling")
  liq_v470_tex_table(scope,file.path(pub,"T47002_learning_opportunities.tex"),paste0("v4.7.0 ",cfg$stage," learning opportunities; positive gamma is not required."),"tab:v470_learning")
  writeLines(c("% Results must be interpreted using completed/abstained denominators and oracle MC error.",
    paste0("The v4.7.0 ",cfg$stage," uses ",cfg$simulation_days," reference sessions and six fixed simulated assets. Forecast rules, TRAIN selection, calibration and GUARD thresholds remain unchanged."),
    "An independent stationary-origin Monte Carlo reference integrates true recovery probabilities under each replication's frozen fitted rules and asset effects. This differs from the realized-feature-path conditional bootstrap target.",
    "Oracle values are Monte Carlo approximations. Their standard errors and 99 percent Monte Carlo bands are reported; these are not exact population truths. Algebraic identities and unsupported intervals are excluded from stochastic coverage denominators.",
    "The experiment is an event-level DGP. It does not simulate or validate the entire OHLCV-to-liquidity-index construction, point-in-time universe membership, or order-book trading costs.",
    "Pilot results check execution and opportunity. Small pilot replication counts do not establish nominal coverage or forecasting superiority."),file.path(pub,"RESULTS_SCOPE_INSERT.tex"))
  meta<-data.table(item=c("version","stage","simulation_sessions","attempts","source_hash","protocol_key","oracle_scope"),
    value=c(cfg$version,cfg$stage,cfg$simulation_days,length(cfg$simulation_scenarios)*cfg$simulation_reps,liq_source_identity(cfg)$hash,liq_v470_protocol_key(cfg),
      "independent-origin MC; eight or configured batches; finite-MC error retained"))
  liq_write_csv(meta,file.path(pub,"PROVENANCE.csv"))
  writeLines(c(if(isTRUE(cfg$export_large))"Full CSV audit export."else"Compact numerical/diagnostic export.",
    "Model checkpoints and fitted-rule RDS files are retained locally and excluded from both exports.",
    if(!isTRUE(cfg$export_large))"Per-task events, oracle probabilities and frozen TEST prediction CSVs remain local; use 07_EXPORT_FULL_AUDIT_V470.R to include them."else"Per-task event, oracle-probability and frozen prediction CSVs included.",
    "Superseded task attempts are retained locally and excluded from exports."),file.path(cfg$out_dir,"EXPORT_SCOPE.txt"))
  files<-list.files(cfg$out_dir,recursive=TRUE,full.names=TRUE)
  files<-files[!dir.exists(files)&!grepl("checkpoint[.]rds|fitted_rules[.]rds|EXPORT_MANIFEST[.]csv",files)&!grepl("/superseded/",files,fixed=TRUE)]
  if(!isTRUE(cfg$export_large))files<-files[!basename(files)%in%c("events.csv","oracle_probabilities.csv","frozen_test_predictions.csv")]
  rel<-substring(normalizePath(files,winslash="/"),nchar(normalizePath(cfg$out_dir,winslash="/"))+2L)
  liq_write_csv(data.table(file=rel,bytes=file.info(files)$size,md5=unname(tools::md5sum(files))),file.path(cfg$out_dir,"EXPORT_MANIFEST.csv"))
  zipfile<-file.path(dirname(cfg$out_dir),paste0("LIQ_REC_v470_",cfg$stage,if(isTRUE(cfg$export_large))"_AUDIT_RESULTS.zip"else"_RESULTS.zip"))
  if(requireNamespace("zip",quietly=TRUE))zip::zip(zipfile,files=c(rel,"EXPORT_MANIFEST.csv"),root=cfg$out_dir,mode="mirror",include_directories=FALSE)
  else message("Results are complete in ",cfg$out_dir,". For automatic ZIP export install.packages('zip') and rerun 04_EXPORT_V470.R.")
  invisible(pub)
}
liq_v470_run <- function(stage=c("pilot","full")) {
  stage<-match.arg(stage);cfg<-liq_v470_config(stage);liq_packages(cfg)
  oldcfg<-file.path(cfg$out_dir,"configuration.rds")
  if(file.exists(oldcfg)) {
    previous<-readRDS(oldcfg)
    liq_assert(identical(previous$version,"4.7.0")&&identical(previous$stage,stage),"Refusing to mix another version or stage into this output directory.")
  }
  liq_dir(cfg$out_dir)
  oldlog<-getOption("liq.log.file");options(liq.log.file=file.path(cfg$out_dir,"run.log"));on.exit(options(liq.log.file=oldlog),add=TRUE)
  if(stage=="full") {
    p<-file.path(Sys.getenv("LIQ_V470_PILOT_DIR",file.path(dirname(cfg$source_path),"out_liq_rec_v4_7_0_pilot")),"V470_PILOT_GATE.rds")
    liq_assert(file.exists(p),"Complete the declared pilot before the 600-attempt full study.")
    gate<-readRDS(p);liq_assert(isTRUE(gate$pass)&&identical(gate$key,liq_v470_protocol_key(cfg)),
      "Pilot protocol/source differs or structural checks failed. No superiority criterion is used.")
  }
  liq_v470_preflight(cfg);saveRDS(cfg,file.path(cfg$out_dir,"configuration.rds"))
  capture.output(sessionInfo(),file=file.path(cfg$out_dir,"sessionInfo.txt"))
  liq_dir(file.path(cfg$out_dir,"source"));file.copy(cfg$source_path,file.path(cfg$out_dir,"source",basename(cfg$source_path)),overwrite=TRUE)
  tm<-liq_task_manager(cfg,paste0("v470-event-DGP-",cfg$simulation_days,"-",cfg$seed))
  values<-liq_run_simulation(cfg,tm$run);st<-tm$status();liq_save(st,"RUN_STATUS",cfg$out_dir)
  cs<-if(length(values))liq_bind(lapply(values,`[[`,"correction"))else data.table()
  noerrors<-!any(st$status=="failed")
  opportunities<-nrow(cs)>0&&all(cs$valid_meta_periods>=2L&cs$finite_validation_losses>0L)
  allscenarios<-nrow(cs)>0&&all(cfg$simulation_scenarios%in%cs$scenario)
  gate<-list(pass=noerrors&&opportunities&&allscenarios,key=liq_v470_protocol_key(cfg),
    checks=list(no_software_failures=noerrors,valid_meta_periods=opportunities,at_least_one_supported_fit_per_scenario=allscenarios),
    positive_gamma_required=FALSE,coverage_or_superiority_required=FALSE,created=Sys.time())
  if(stage=="pilot")saveRDS(gate,file.path(cfg$out_dir,"V470_PILOT_GATE.rds"))
  have_reference<-file.exists(file.path(cfg$reference_dir,"rolling_performance.csv"))||file.exists(file.path(cfg$reference_dir,"tables","G02_all_completed_extended_results.csv"))
  if(have_reference)liq_v470_rolling_diagnostics(cfg)else {
    liq_dir(file.path(cfg$out_dir,"rolling_diagnostics"))
    writeLines("Rolling reference not supplied; no rolling results evaluated.",file.path(cfg$out_dir,"rolling_diagnostics","SCOPE.txt"))
    message("Rolling reference not supplied. Simulation results remain available; see LIQ_V460_RESULTS_DIR.")
  }
  writeLines(c(paste("LIQ-REC",cfg$version,stage),paste("Completed",sum(st$status=="completed"),"Insufficient",sum(st$status=="insufficient_sample"),"Failed",sum(st$status=="failed")),
    paste("Structural pilot checks",gate$pass),"Gamma zero after valid TRAIN selection is allowed. Forecasting superiority is not a run criterion.",
    "Inspect S47002/S47005 for actual correction activation, S06 for support and S47004 for approximate marginal coverage with oracle MC error.",
    if(have_reference)"Rolling diagnostics reuse supplied v4.6.0 results; no new real-data rolling models were fitted."else"Rolling reference not supplied; not evaluated."),file.path(cfg$out_dir,"RUN_SCOPE.txt"))
  if(length(values))liq_v470_export(cfg)
  liq_assert(noerrors,"Software failures occurred: inspect RUN_STATUS.csv; completed checkpoints are retained.")
  invisible(list(cfg=cfg,status=st,gate=gate))
}


# ======================= v4.7.0 audited implementation =======================
# Development changes are explicit: Cox fallback, calendar-only batch choice,
# independently checked oracle targets. No TEST outcome tunes these policies.
liq_config_pre470 <- liq_config
liq_config <- function() {
  cfg<-liq_config_pre470()
  cfg$batch_groups<-4L
  cfg$batch_group_policy<-"largest of 2..4 allowed by calendar span and unchanged 3-Hmax minimum"
  cfg$probability_policy<-"Cox raw fallback; raw/calibrated Cox residual proposals; unchanged GUARD paired one-SE heuristic"
  cfg$protocol_status<-"v4.7 retrospective development after inspecting v4.6 TEST; new simulation seeds; no preregistration claim"
  cfg
}

liq_heads <- function(candidates,guard,cfg) {
  liq_need("Cox_raw"%in%names(candidates$pred$guard)&&"Cox_raw"%in%names(candidates$pred$test),
    "v4.7 Cox anchor unavailable; probability head abstains instead of using another model family.")
  ans<-liq_heads_v460(candidates,guard,cfg)
  legacy_single<-ans$choices[head=="Single_Brier_Guard",component1][1]
  for(ds in c("guard","test"))ans[[ds]]$LIQ_Brier_v460<-ans[[ds]]$LIQ_Brier
  previous_choices<-copy(ans$choices[head=="LIQ_Brier"])
  previous_choices[,head:="LIQ_Brier_v460"]
  ans$legacy_gate<-copy(ans$gate)
  proposed<-intersect(c("CoxResidual_raw","CoxResidual_cal"),names(ans$guard))
  if(!length(proposed))proposed<-"Cox_raw"
  losses<-vapply(proposed,function(nm)mean(liq_loss_vector(guard,ans$guard[[nm]],cfg$horizons)),numeric(1))
  proposal<-proposed[which.min(losses)]
  eligible<-nrow(guard)>=cfg$min_guard&&all(vapply(cfg$horizons,function(h) {
    y<-liq_truth(guard,h)$y;pos<-is.finite(y)&y==1;neg<-is.finite(y)&y==0
    min(sum(pos),sum(neg))>=cfg$min_class&&
      min(uniqueN(guard$shock_date[pos]),uniqueN(guard$shock_date[neg]))>=cfg$selection_min_dates&&
      min(uniqueN(guard$asset[pos]),uniqueN(guard$asset[neg]))>=cfg$selection_min_assets
  },logical(1)))
  gate<-liq_guard_delta(guard,ans$guard[[proposal]],ans$guard$Cox_raw,cfg)
  gate$accepted<-isTRUE(gate$accepted)&&eligible
  selected<-if(gate$accepted)proposal else "Cox_raw"
  for(ds in c("guard","test"))ans[[ds]]$LIQ_Brier<-ans[[ds]][[selected]]
  ans$choices<-rbind(ans$choices[head!="LIQ_Brier"],previous_choices,fill=TRUE)
  for(h in cfg$horizons)ans$choices<-rbind(ans$choices,data.table(head="LIQ_Brier",horizon=h,
    component1="Cox_raw",component2=proposal,weight1=as.numeric(selected=="Cox_raw"),
    selected_source=selected,note="v4.7 Cox fallback; proposal and acceptance use GUARD only"),fill=TRUE)
  pool<-unique(c("Cox_raw",proposed))
  ans$weights<-liq_bind(lapply(cfg$horizons,function(h)data.table(horizon=h,component=pool,
    weight=as.numeric(pool==selected),retained_ensemble=gate$accepted,guard_baseline="Cox_raw",
    selected_source=selected,guard_rule="paired one-SE development heuristic; not a probability of safety or a TEST guarantee")))
  ans$gate<-data.table(proposal=proposal,single="Cox_raw",legacy_single=legacy_single,selected=selected,
    delta_Brier=gate$estimate,block_SE=gate$se,n_blocks=gate$blocks,margin_z=cfg$guard_margin_z,
    min_gain=cfg$guard_min_gain,selection_allowed=eligible,accepted=gate$accepted,
    interpretation="v4.7 Cox anchor; two fixed residual proposals selected on GUARD; heuristic is not a confidence guarantee")
  ans
}

liq_batch_interval <- function(e,calendar,influence,estimate,cfg,K=1L,identity=FALSE,auc=FALSE,y=NULL) {
  idx<-match(e$shock_date,calendar)
  span<-if(length(idx)&&all(is.finite(idx)))max(idx)-min(idx)+1L else 0L
  min_sessions<-cfg$batch_min_H*cfg$max_h
  G<-as.integer(max(2L,min(cfg$batch_groups,floor(span/min_sessions))))
  critical<-qt(1-.05/(2*K),df=G-1L)
  z<-list(estimate=estimate,lower=NA_real_,upper=NA_real_,supported=FALSE,
    reason="insufficient calendar span, origin dates, or finite influence",
    n_dates=uniqueN(e$shock_date),calendar_span=span,groups=G,
    min_batch_sessions=if(span)floor(span/G)else 0L,standard_error=NA_real_,critical=critical,
    group_policy=paste0("calendar-only maximum ",cfg$batch_groups," groups; unchanged minimum ",min_sessions," sessions per group"))
  if(isTRUE(identity)&&is.finite(estimate)) {
    z$lower<-z$upper<-0;z$supported<-TRUE
    z$reason<-"algebraically identical fitted sources; excluded from stochastic coverage";return(z)
  }
  if(!is.finite(estimate)||length(influence)!=nrow(e)||!length(influence)||any(!is.finite(influence))||
     z$n_dates<cfg$sn_min_dates||span==0L||floor(span/G)<min_sessions)return(z)
  group<-pmin(G-1L,floor((idx-min(idx))*G/span))+1L
  if(min(tabulate(group,nbins=G))<8L) {z$reason<-"fewer than eight event rows in a calendar group";return(z)}
  if(auc&&(is.null(y)||min(sum(y==1),sum(y==0))<10L||
    min(uniqueN(e$shock_date[y==1]),uniqueN(e$shock_date[y==0]))<10L)) {
    z$reason<-"insufficient AUC class or class-date support";return(z)
  }
  totals<-as.numeric(rowsum(influence-mean(influence),group,reorder=TRUE))
  se<-sqrt(G/(G-1L)*sum(totals^2))/length(influence)
  if(!is.finite(se)||se<1e-10) {z$reason<-"degenerate group influence; no stochastic interval";return(z)}
  z$standard_error<-se;bounds<-estimate+c(-1,1)*critical*se
  z$lower<-max(-1,bounds[1]);z$upper<-min(1,bounds[2]);z$supported<-TRUE
  z$reason<-"asymptotic stationary influence FCLT and independent Gaussian calendar-group limits"
  z
}

liq_v470_opportunity <- function(d,cfg) {
  b<-liq_v470_blocks(d);cc<-cfg;cc$inner_fractions<-cfg$correction_inner_fractions
  splits<-liq_inner_splits(b$TRAIN,cc);nd<-uniqueN(b$TEST$shock_date)
  span<-if(nrow(b$TEST))max(b$TEST$sid)-min(b$TEST$sid)+1L else 0L
  G<-as.integer(max(2L,min(cfg$batch_groups,floor(span/(cfg$batch_min_H*cfg$max_h)))))
  data.table(n_TRAIN=nrow(b$TRAIN),n_CAL_FIT=nrow(b$CAL_FIT),n_GUARD=nrow(b$GUARD),n_TEST=nrow(b$TEST),
    forward_period_opportunities=length(splits),meta_period_opportunities=max(0L,length(splits)-1L),
    TEST_origin_dates=nd,TEST_calendar_span=span,groups=G,min_batch_sessions=floor(span/G),
    calendar_opportunity=nd>=cfg$sn_min_dates&&floor(span/G)>=cfg$batch_min_H*cfg$max_h,
    multiple_forward_periods=length(splits)>=3L)
}

liq_v470_soft_auc_reference <- function(q,score) {
  if(length(q)!=length(score)||any(!is.finite(q))||any(!is.finite(score)))return(NA_real_)
  den<-sum(q)*sum(1-q);if(den<=0)return(NA_real_)
  ord<-order(score);qq<-q[ord];ss<-score[ord]
  id<-cumsum(c(TRUE,diff(ss)!=0))
  pos<-as.numeric(rowsum(qq,id,reorder=FALSE));neg<-as.numeric(rowsum(1-qq,id,reorder=FALSE))
  sum(pos*(c(0,head(cumsum(neg),-1L))+.5*neg))/den
}

liq_v470_oracle_reference <- function(q,pred,pairs,cfg) {
  vapply(seq_len(nrow(pairs)),function(i) {
    r<-pairs[i];j<-match(r$horizon,cfg$horizons);p<-pred[[r$model]][,j];b<-pred[[r$reference]][,j];qq<-q[,j]
    if(r$metric=="Brier")mean(qq*((1-p)^2-(1-b)^2)+(1-qq)*(p^2-b^2))else
      liq_v470_soft_auc_reference(qq,p)-liq_v470_soft_auc_reference(qq,b)
  },numeric(1))
}

liq_v470_attach_oracle <- function(intervals,oracle_values,oracle_se,cfg) {
  n<-nrow(intervals)
  liq_assert(length(oracle_values)==n&&length(oracle_se)==n&&all(is.finite(oracle_values))&&
    all(is.finite(oracle_se)&oracle_se>=0),"Independent oracle target/SE is missing or malformed.")
  z<-copy(intervals);half<-qt(.995,df=cfg$oracle_batches-1L)*as.numeric(oracle_se)
  # Set explicit external vectors. Never resolve an oracle vector inside DT's j.
  set(z,j="oracle_estimate",value=as.numeric(oracle_values))
  set(z,j="oracle_MC_SE",value=as.numeric(oracle_se))
  set(z,j="oracle_lower_99",value=pmax(-1,as.numeric(oracle_values)-half))
  set(z,j="oracle_upper_99",value=pmin(1,as.numeric(oracle_values)+half))
  set(z,j="oracle_batches",value=rep(as.integer(cfg$oracle_batches),n))
  set(z,j="oracle_origins_per_batch",value=rep(as.integer(cfg$oracle_origins),n))
  z[,oracle_target:="stationary marginal future-origin risk; fixed learned rules and asset effects; independently audited finite-MC proxy"]
  z[,eligible_for_coverage:=supported&!algebraic_identity&is.finite(lower)&is.finite(upper)&is.finite(oracle_estimate)]
  z[,oracle_point_covered:=fifelse(eligible_for_coverage,lower<=oracle_estimate&upper>=oracle_estimate,NA)]
  z[,covered_for_entire_oracle_band:=fifelse(eligible_for_coverage,lower<=oracle_lower_99&upper>=oracle_upper_99,NA)]
  z[,miss_for_entire_oracle_band:=fifelse(eligible_for_coverage,upper<oracle_lower_99|lower>oracle_upper_99,NA)]
  z[,oracle_ambiguous:=fifelse(eligible_for_coverage,!covered_for_entire_oracle_band&!miss_for_entire_oracle_band,NA)]
  set(z,j="oracle_halfwidth_over_interval_width",value=ifelse(z$eligible_for_coverage&z$upper>z$lower,half/(z$upper-z$lower),NA_real_))
  z
}

liq_v470_marginal_oracle <- function(cand,train,choices,context,intervals,cfg,replication) {
  qs<-pp<-draws<-vector("list",cfg$oracle_batches)
  needed<-unique(c(intervals$model,intervals$reference))
  for(b in seq_len(cfg$oracle_batches)) {
    z<-liq_v470_oracle_origins(context,cfg,cfg$oracle_origins,cfg$oracle_seed+100L*replication+b)
    p<-liq_v470_frozen_predictions(cand,train,z$events,choices,cfg)[needed]
    qs[[b]]<-z$q;pp[[b]]<-p;draws[[b]]<-liq_v470_oracle_metrics(z$q,p,intervals,cfg)
  }
  mm<-do.call(rbind,draws);qq<-do.call(rbind,qs)
  pooled<-setNames(lapply(needed,function(nm)do.call(rbind,lapply(pp,`[[`,nm))),needed)
  oracle_values<-liq_v470_oracle_metrics(qq,pooled,intervals,cfg)
  independent_reference<-liq_v470_oracle_reference(qq,pooled,intervals,cfg)
  oracle_se<-apply(mm,2,sd)/sqrt(nrow(mm))
  z<-liq_v470_attach_oracle(intervals,oracle_values,oracle_se,cfg)
  altered<-copy(intervals);set(altered,j="estimate",value=rep(.3141592653589793,nrow(altered)))
  again<-liq_v470_attach_oracle(altered,oracle_values,oracle_se,cfg)
  cols<-c("oracle_estimate","oracle_MC_SE","oracle_lower_99","oracle_upper_99")
  brier<-intervals$metric=="Brier"
  audit<-data.table(check=c("pooled_target_matches_independent_risk_formula",
    "Brier_target_equals_equal_size_batch_mean","reported_target_matches_pooled_target",
    "oracle_target_and_band_ignore_observed_TEST_estimate","finite_independent_MC_SE"),
    pass=c(max(abs(oracle_values-independent_reference))<1e-11,
      !any(brier)||max(abs(oracle_values[brier]-colMeans(mm)[brier]))<1e-11,
      identical(z$oracle_estimate,as.numeric(oracle_values)),
      isTRUE(all.equal(z[,..cols],again[,..cols],tolerance=0,check.attributes=FALSE)),
      all(is.finite(oracle_se)&oracle_se>=0)),
    detail=c(format(max(abs(oracle_values-independent_reference)),digits=17),
      if(any(brier))format(max(abs(oracle_values[brier]-colMeans(mm)[brier])),digits=17)else"not applicable",
      "explicit vector assignment","metamorphic TEST-estimate mutation","SD of independent batch values / sqrt(batch count)"))
  liq_assert(all(audit$pass),paste("Oracle numerical audit failed:",paste(audit[pass==FALSE,check],collapse=", ")))
  targets<-data.table(pair_row=seq_len(nrow(intervals)),model=intervals$model,reference=intervals$reference,
    metric=intervals$metric,horizon=intervals$horizon,pooled_target=oracle_values,
    independent_reference=independent_reference,batch_mean=colMeans(mm),MC_SE=oracle_se)
  batches<-as.data.table(mm);setnames(batches,paste0("row_",seq_len(ncol(mm))))
  batches[,oracle_batch:=.I];batches<-melt(batches,id.vars="oracle_batch",variable.name="row",value.name="oracle_batch_delta")
  batches[,pair_row:=as.integer(sub("row_","",row,fixed=TRUE))]
  setattr(z,"oracle_batch_deltas",batches);setattr(z,"oracle_target_audit",audit);setattr(z,"oracle_independent_targets",targets)
  z
}

liq_run_simulation <- function(cfg,run) {
  values<-list()
  for(sc in cfg$simulation_scenarios)for(replication in seq_len(cfg$simulation_reps)) {
    id<-sprintf("simulation_%s_%03d",sc,replication)
    value<-run(id,"simulation",function(path) {
      d<-liq_simulated_events(cfg,sc,replication);b<-liq_v470_blocks(d)
      liq_save(liq_class_support(d$events,cfg),"role_class_support",path)
      opportunity<-liq_v470_opportunity(d,cfg);liq_save(opportunity,"calendar_and_fold_opportunities",path)
      liq_require_simulation_support(d$events,b,cfg)
      cand<-liq_candidates(b$TRAIN,b$CAL_FIT,b$GUARD,b$TEST,cfg);hd<-liq_heads(cand,b$GUARD,cfg)
      cs<-liq_v470_correction_status(cand,cfg);liq_save(cs,"correction_status",path)
      liq_save(cand$fits$Correction$tuning,"correction_TRAIN_tuning",path)
      liq_save(cand$fits$Correction$validation,"correction_meta_validation",path)
      liq_save(cand$fits$Correction$audit,"correction_forward_audit",path)
      liq_save(hd$choices,"selected_components",path);liq_save(hd$gate,"GUARD_gate",path)
      if(!is.null(hd$legacy_gate))liq_save(hd$legacy_gate,"GUARD_gate_v460_shadow",path)
      replay<-liq_v470_frozen_predictions(cand,b$TRAIN,b$TEST,hd$choices,cfg)
      nm<-intersect(names(replay),names(hd$test))
      err<-max(vapply(nm,function(z)max(abs(replay[[z]]-hd$test[[z]])),numeric(1)))
      liq_assert(err<1e-12,"Frozen predictor does not reproduce observed TEST.")
      liq_save(data.table(check="Frozen predictor reproduces observed TEST",pass=err<1e-12,max_abs_difference=err),"frozen_prediction_check",path)
      pt<-liq_evaluate(b$TEST,hd$test,cfg,hd$rank_names)
      bi<-liq_batch_pairs(b$TEST,hd$test,cfg,d$calendar,hd$choices,cand$fits$Correction)
      oracle<-liq_v470_marginal_oracle(cand,b$TRAIN,hd$choices,d$dgp_context,bi,cfg,replication)
      audit<-copy(attr(oracle,"oracle_target_audit"));targets<-copy(attr(oracle,"oracle_independent_targets"))
      liq_save(audit,"oracle_target_audit",path);liq_save(targets,"oracle_independent_targets",path)
      liq_save(attr(oracle,"oracle_batch_deltas"),"oracle_MC_batch_deltas",path)
      cc<-cfg;cc$batch_groups<-2L
      two<-liq_batch_pairs(b$TEST,hd$test,cc,d$calendar,hd$choices,cand$fits$Correction)
      liq_assert(identical(two[,.(model,reference,metric,horizon)],bi[,.(model,reference,metric,horizon)]),"Sensitivity pair order differs.")
      two<-liq_v470_attach_oracle(two,oracle$oracle_estimate,oracle$oracle_MC_SE,cfg)
      conditional<-liq_v470_conditional_bootstrap(d,b,hd,cfg,replication)
      selected<-hd$gate$selected[1]
      deployment<-data.table(selected_source=selected,proposal=hd$gate$proposal[1],fallback="Cox_raw",
        residual_gamma=cs$gamma,residual_fitted_active=cs$active,
        residual_deployed=cs$active&&selected%in%c("CoxResidual_raw","CoxResidual_cal"),
        calibration_deployed=grepl("_cal$",selected),Cox_fallback=selected=="Cox_raw",
        legacy_single=hd$gate$legacy_single[1],gate_accepted=hd$gate$accepted[1])
      for(n in c("pt","bi","oracle","conditional","cs","opportunity","audit","deployment","two")) {
        z<-get(n);z[,`:=`(scenario=sc,replication=replication)];assign(n,z)
      }
      liq_save(pt,"performance",path);liq_save(bi,"calendar_batch_paired_intervals",path)
      liq_save(oracle,"marginal_oracle_coverage",path);liq_save(two,"two_group_sensitivity",path)
      liq_save(conditional,"conditional_interval_coverage",path);liq_save(deployment,"head_deployment",path)
      liq_save(liq_long_predictions(b$TEST,hd$test,cfg,hd$rank_names),"frozen_test_predictions",path)
      liq_save(d$events,"events",path);liq_save(d$oracle,"oracle_probabilities",path)
      liq_save_rds_atomic(list(candidates=cand,choices=hd$choices,context=d$dgp_context,cfg=cfg,
        version=cfg$version,training_source=liq_source_identity(cfg)),file.path(path,"fitted_rules.rds"))
      list(point=pt,batch=bi,oracle=oracle,conditional=conditional,correction=cs,opportunity=opportunity,
        oracle_audit=audit,deployment=deployment,two_group=two)
    },signature=list(cfg=cfg,scenario=sc,replication=replication,oracle_design="independent-origin-MC-v470-audited"))
    if(!is.null(value))values[[id]]<-value
  }
  liq_v470_simulation_summary(values,cfg)
  invisible(values)
}

liq_v470_simulation_summary_base <- liq_v470_simulation_summary
liq_v470_simulation_summary <- function(values,cfg) {
  if(!length(values))return(invisible(NULL))
  liq_v470_simulation_summary_base(values,cfg)
  for(pair in list(c("oracle_audit","S47009_oracle_numerical_audit"),c("deployment","S47007_head_deployment"),c("two_group","S47010_two_group_sensitivity")))
    liq_save(liq_bind(lapply(values,`[[`,pair[1])),pair[2],cfg$out_dir)
  all<-liq_bind(lapply(values,`[[`,"oracle"));all[,interval_width:=upper-lower]
  inf<-all[,{
    ok<-eligible_for_coverage
    .(n_total=.N,n_identity=sum(algebraic_identity),n_stochastic=sum(ok),n_abstained=sum(!supported),
      min_groups=min(groups),max_groups=max(groups),
      mean_width=liq_mean(interval_width[ok]),median_width=if(any(ok))median(interval_width[ok])else NA_real_,
      n_full_range=sum(ok&is.finite(interval_width)&interval_width>=2-1e-12),
      n_excluding_zero=sum(ok&(lower>0|upper<0)),
      scope="descriptive informativeness; horizons/heads are not independent replications")
  },by=.(scenario,metric)]
  liq_save(inf,"S47006_interval_informativeness",cfg$out_dir)
  point<-liq_bind(lapply(values,`[[`,"point"))
  ref<-point[model=="Cox_raw",.(scenario,replication,horizon,Cox_Brier=Brier,Cox_AUC=AUC)]
  compare<-merge(point[model%in%c("Cox_raw","CoxResidual_raw","LIQ_Brier","LIQ_Brier_v460","Single_Brier_Guard","LIQ_Rank_Guard")],ref,by=c("scenario","replication","horizon"))
  compare[,`:=`(delta_Brier=Brier-Cox_Brier,delta_AUC=AUC-Cox_AUC)]
  liq_save(compare,"S47008_same_fit_head_comparison",cfg$out_dir)
}

liq_v470_export <- function(cfg) {
  pub<-liq_dir(file.path(cfg$out_dir,"publication"))
  scope<-fread(file.path(cfg$out_dir,"tables","S47005_correction_scope_summary.csv"))
  liq_write_csv(scope,file.path(pub,"T47001_learning_opportunities.csv"))
  liq_pub_table(scope,"v4.7 simulation learning opportunities.",
    "Positive residual gamma is not required. Separate TRAIN selection, calibration deployment and Cox fallback.","T47001_learning_opportunities",pub,digits=0L)
  d<-fread(file.path(cfg$out_dir,"tables","S47008_same_fit_head_comparison.csv"))
  means<-d[,.(Brier=liq_mean(Brier),AUC=liq_mean(AUC)),by=.(scenario,model)]
  liq_write_csv(means,file.path(pub,"T47002_performance_means.csv"))
  cov<-fread(file.path(cfg$out_dir,"tables","S47004_marginal_oracle_summary.csv"))
  liq_write_csv(cov,file.path(pub,"T47003_marginal_coverage.csv"))
  info<-fread(file.path(cfg$out_dir,"tables","S47006_interval_informativeness.csv"))
  liq_write_csv(info,file.path(pub,"T47004_interval_informativeness.csv"))
  writeLines(c("% v4.7 is retrospective method development, not preregistration.",
    paste0("The v4.7 ",cfg$stage," uses ",cfg$simulation_days," calendar sessions, six assets and ",cfg$simulation_reps," replications per scenario."),
    "The probability head falls back to raw Cox. Raw and CAL-FIT-calibrated residual proposals are selected and screened on GUARD using the original paired one-SE heuristic. The original v4.6 head remains a same-fit comparator. This heuristic does not guarantee TEST improvement.",
    "The primary interval uses the largest number of equal-calendar groups from two through four allowed by at least three maximum horizons per group. This choice uses calendar span only. The minimum origin/date/class support rules remain unchanged. Fixed two-group results are retained as sensitivity.",
    "Independent stationary-origin Monte Carlo targets are assigned from explicit external vectors. Brier and weighted AUC targets are checked using separate risk formulas. Changing the observed TEST estimate must not change the oracle target or its Monte Carlo band.",
    "Coverage excludes identities and unsupported intervals. Monte Carlo uncertainty and interval width are reported separately. Pilot counts do not establish nominal coverage or forecasting superiority.",
    "The interval assumptions remain a stationary influence FCLT and independent Gaussian calendar-group limits. Training and universe uncertainty, abrupt within-TEST breaks and order-book execution costs are outside this experiment.",
    "Archived v4.6.0 rolling results are references only. New v4.7 rolling selections require retained fitted objects; no archived TEST performance is used to tune a gate."),file.path(pub,"RESULTS_SCOPE_INSERT.tex"))
  liq_write_csv(data.table(item=c("version","stage","source_hash","protocol_key","probability_policy","batch_group_policy","oracle_audit"),
    value=c(cfg$version,cfg$stage,liq_source_identity(cfg)$hash,liq_v470_protocol_key(cfg),cfg$probability_policy,
      cfg$batch_group_policy,"separate Bernoulli-risk and base-R weighted-AUC reference; TEST-estimate mutation invariant")),file.path(pub,"PROVENANCE.csv"))
  writeLines(c(if(cfg$export_large)"Full CSV audit export."else"Compact audited numerical export.",
    "Checkpoints and fitted model RDS files remain local.",
    if(cfg$export_large)"Events and frozen prediction CSVs are included."else"Events and frozen prediction CSVs remain local; 07_EXPORT_FULL_AUDIT_V470.R includes them.",
    "S47009 contains independently checked oracle-target audits; S47010 retains two-group sensitivity.",
    "Archived rolling references are not new v4.7 real-data fits."),file.path(cfg$out_dir,"EXPORT_SCOPE.txt"))
  files<-list.files(cfg$out_dir,recursive=TRUE,full.names=TRUE)
  files<-files[!dir.exists(files)&!grepl("[.]rds$|EXPORT_MANIFEST[.]csv$",files)&!grepl("/superseded/",files,fixed=TRUE)]
  # Configuration is included, model objects are not.
  files<-unique(c(files,file.path(cfg$out_dir,"configuration.rds"),if(file.exists(file.path(cfg$out_dir,"V470_PILOT_GATE.rds")))file.path(cfg$out_dir,"V470_PILOT_GATE.rds")))
  if(!cfg$export_large)files<-files[!basename(files)%in%c("events.csv","oracle_probabilities.csv","frozen_test_predictions.csv")]
  rel<-substring(normalizePath(files,winslash="/"),nchar(normalizePath(cfg$out_dir,winslash="/"))+2L)
  liq_write_csv(data.table(file=rel,bytes=file.info(files)$size,md5=unname(tools::md5sum(files))),file.path(cfg$out_dir,"EXPORT_MANIFEST.csv"))
  zipfile<-file.path(dirname(cfg$out_dir),paste0("LIQ_REC_v470_",cfg$stage,if(cfg$export_large)"_AUDIT_RESULTS.zip"else"_RESULTS.zip"))
  tmpzip<-tempfile("v470_export_",tmpdir=dirname(zipfile),fileext=".zip")
  if(requireNamespace("zip",quietly=TRUE))zip::zip(tmpzip,files=c(rel,"EXPORT_MANIFEST.csv"),root=cfg$out_dir,mode="mirror",include_directories=FALSE)
  else if(nzchar(Sys.which("zip")))local({old<-getwd();on.exit(setwd(old));setwd(cfg$out_dir);utils::zip(tmpzip,files=c(rel,"EXPORT_MANIFEST.csv"),flags="-q")})
  else message("Numerical results saved. Install package zip, then source 04_EXPORT_V470.R to export their ZIP.")
  if(file.exists(tmpzip)) {
    if(file.exists(zipfile))liq_assert(unlink(zipfile)==0L,"Cannot replace previous result ZIP.")
    liq_assert(file.rename(tmpzip,zipfile),"Cannot commit result ZIP.")
  }
  invisible(pub)
}

liq_v470_run <- function(stage=c("pilot","full")) {
  stage<-match.arg(stage);cfg<-liq_v470_config(stage);liq_packages(cfg)
  previous<-file.path(cfg$out_dir,"configuration.rds")
  if(file.exists(previous)) {
    old<-readRDS(previous)
    liq_assert(identical(old$version,cfg$version)&&identical(old$stage,stage),"Use a separate v4.7 output directory.")
  }
  liq_dir(cfg$out_dir);oldlog<-getOption("liq.log.file")
  options(liq.log.file=file.path(cfg$out_dir,"run.log"));on.exit(options(liq.log.file=oldlog),add=TRUE)
  if(stage=="full") {
    path<-file.path(Sys.getenv("LIQ_V470_PILOT_DIR",file.path(dirname(cfg$source_path),"out_liq_rec_v4_7_0_pilot")),"V470_PILOT_GATE.rds")
    liq_assert(file.exists(path),"Run the v4.7 pilot before the full study; a v4.6 receipt is not accepted.")
    pilot<-readRDS(path)
    liq_assert(identical(pilot$version,"4.7.0")&&isTRUE(pilot$pass)&&isTRUE(pilot$checks$independent_oracle_numerics)&&
      identical(pilot$key,liq_v470_protocol_key(cfg)),"Pilot source/protocol/numerical audit differs. Rerun the v4.7 pilot.")
  }
  liq_v470_preflight(cfg);saveRDS(cfg,file.path(cfg$out_dir,"configuration.rds"))
  capture.output(sessionInfo(),file=file.path(cfg$out_dir,"sessionInfo.txt"))
  liq_dir(file.path(cfg$out_dir,"source"));file.copy(cfg$source_path,file.path(cfg$out_dir,"source",basename(cfg$source_path)),overwrite=TRUE)
  tm<-liq_task_manager(cfg,paste0("v470-event-DGP-",cfg$simulation_days,"-",cfg$seed))
  values<-liq_run_simulation(cfg,tm$run);st<-tm$status();liq_save(st,"RUN_STATUS",cfg$out_dir)
  cs<-if(length(values))liq_bind(lapply(values,`[[`,"correction"))else data.table()
  audit<-if(length(values))liq_bind(lapply(values,`[[`,"oracle_audit"))else data.table()
  checks<-list(no_software_failures=nrow(st)>0&&!any(st$status=="failed"),
    valid_meta_periods=nrow(cs)>0&&all(cs$valid_meta_periods>=2L&cs$finite_validation_losses>0),
    supported_fit_in_each_scenario=nrow(cs)>0&&all(cfg$simulation_scenarios%in%cs$scenario),
    independent_oracle_numerics=nrow(audit)>0&&all(audit$pass))
  gate<-list(version=cfg$version,pass=all(unlist(checks)),key=liq_v470_protocol_key(cfg),checks=checks,
    positive_gamma_required=FALSE,coverage_or_superiority_required=FALSE,created=Sys.time())
  if(stage=="pilot")liq_save_rds_atomic(gate,file.path(cfg$out_dir,"V470_PILOT_GATE.rds"))
  have_ref<-file.exists(file.path(cfg$reference_dir,"rolling_performance.csv"))||file.exists(file.path(cfg$reference_dir,"tables","G02_all_completed_extended_results.csv"))
  if(have_ref)liq_v470_rolling_diagnostics(cfg)
  writeLines(c(paste("LIQ-REC",cfg$version,stage),paste("Completed",sum(st$status=="completed"),"Insufficient",sum(st$status=="insufficient_sample"),"Failed",sum(st$status=="failed")),
    paste("Structural and independent numerical checks",gate$pass),cfg$probability_policy,cfg$batch_group_policy,
    "Positive gamma, target coverage and TEST improvement are not pilot acceptance criteria.",
    "The previous v4.6 oracle coverage was invalidated by a name collision and is not reused.",
    "Rolling reference tables remain supplied v4.6.0 results; new v4.7 rolling replay is a separate operation."),file.path(cfg$out_dir,"RUN_SCOPE.txt"))
  if(length(values))liq_v470_export(cfg)
  liq_assert(gate$pass,paste("v4.7 structural/numerical gate failed:",paste(names(checks)[!unlist(checks)],collapse=", "),"Inspect RUN_STATUS and S47009."))
  invisible(list(cfg=cfg,status=st,gate=gate))
}

liq_save_rds_atomic <- function(object,path) {
  liq_dir(dirname(path))
  tmp<-tempfile(paste0(basename(path),"_"),tmpdir=dirname(path),fileext=".tmp")
  on.exit(if(file.exists(tmp))unlink(tmp),add=TRUE)
  raw<-serialize(object,NULL,version=3)
  con<-file(tmp,"wb")
  tryCatch({
    for(a in seq.int(1L,length(raw),by=1048576L))writeBin(raw[a:min(length(raw),a+1048575L)],con)
  },finally=close(con))
  liq_assert(file.info(tmp)$size==length(raw),"Incomplete checkpoint byte count.")
  liq_assert(isTRUE(all.equal(readRDS(tmp),object,tolerance=0,check.attributes=FALSE)),"Checkpoint roundtrip differs.")
  # POSIX can replace directly. On Windows retain the original in a rollback
  # file until the verified temporary file has been committed.
  if(suppressWarnings(file.rename(tmp,path)))return(invisible(path))
  liq_assert(file.exists(path),"Cannot commit checkpoint; original target absent.")
  backup<-tempfile(paste0(basename(path),"_rollback_"),tmpdir=dirname(path))
  liq_assert(file.rename(path,backup),"Cannot preserve previous checkpoint for replacement.")
  if(!suppressWarnings(file.rename(tmp,path))) {
    restored<-file.rename(backup,path)
    stop(if(restored)"Checkpoint replacement failed; original restored."else paste("Checkpoint commit failed; recover original from",backup),call.=FALSE)
  }
  unlink(backup);invisible(path)
}

liq_model_spec_pre470 <- liq_model_spec
liq_model_spec <- function(cfg) {
  d<-liq_model_spec_pre470(cfg)
  d[item=="probability_combination",value:="v4.7: TRAIN-selected Cox residual, raw and CAL-FIT-calibrated proposals; GUARD paired one-SE development heuristic against raw Cox; exact Cox fallback; original v4.6 head retained separately"]
  d[item=="SN_scope",value:="Primary calendar-batch t interval: calendar-only largest 2..4 groups with >=3 Hmax sessions per group, >=40 origin dates and original class support; fixed two-group sensitivity; stationary influence-FCLT assumptions and fixed fits/panel; no finite-sample guarantee"]
  rbind(d,data.table(item=c("development_status","oracle_numerical_safety"),value=c(
    cfg$protocol_status,"Independent MC target vectors assigned explicitly; separate risk-formula checks; TEST-estimate mutation regression; identities excluded from stochastic coverage")))
}




# ===== V480 numerics =====
# Validate complete penalized-binomial paths before any predictions.
liq_v480_numerical_log<-new.env(parent=emptyenv());liq_v480_numerical_log$rows<-list()
liq_v480_numerical_reset<-function()liq_v480_numerical_log$rows<-list()
liq_v480_numerical_table<-function()liq_bind(liq_v480_numerical_log$rows)
liq_v480_fit_valid<-function(fit,x,requested) {
 if(inherits(fit,'error')||is.null(fit$beta)||is.null(fit$lambda))return(FALSE)
 d<-dim(fit$beta)
 if(length(d)!=2L||d[1]!=ncol(x)||d[2]!=length(fit$lambda)||length(fit$a0)!=length(fit$lambda)||!length(fit$lambda)||any(!is.finite(fit$a0))||any(!is.finite(as.matrix(fit$beta)))||(!is.null(fit$jerr)&&fit$jerr!=0L))return(FALSE)
 all(vapply(requested,function(l)any(abs(fit$lambda-l)<=1e-12*max(1,abs(l))),logical(1)))
}
liq_v480_ridge<-function(x,y,lambda,offset=NULL,tolerance=1e-9,max_steps=200L) {
 x<-as.matrix(x);y<-as.numeric(y);n<-nrow(x);p<-ncol(x)
 liq_assert(n==length(y)&&n>1L&&p>0L&&all(is.finite(x))&&all(y%in%c(0,1))&&length(unique(y))==2L,'Invalid ridge inputs.')
 if(is.null(offset))offset<-rep(0,n)
 liq_assert(length(offset)==n&&all(is.finite(offset)),'Invalid ridge offset.')
 lambda<-sort(unique(as.numeric(lambda)),decreasing=TRUE)
 liq_assert(length(lambda)>0L&&all(is.finite(lambda)&lambda>0),'Positive ridge penalties required.')
 xx<-cbind(`(Intercept)`=1,x);penalty<-c(0,rep(1,p))
 objective<-function(b,l){eta<-as.numeric(xx%*%b)+offset;mean(pmax(eta,0)+log1p(exp(-abs(eta)))-y*eta)+l*sum(b[-1]^2)/2}
 b<-c(uniroot(function(a)mean(plogis(offset+a))-mean(y),c(-100,100),tol=1e-12)$root,rep(0,p))
 coefficients<-matrix(NA_real_,p+1L,length(lambda),dimnames=list(colnames(xx),NULL));audit<-list()
 for(k in seq_along(lambda)) {
  l<-lambda[k];converged<-FALSE
  for(iter in seq_len(max_steps)) {
   eta<-as.numeric(xx%*%b)+offset;pr<-plogis(eta)
   gradient<-as.numeric(crossprod(xx,pr-y))/n+l*penalty*b
   if(max(abs(gradient))<=tolerance){converged<-TRUE;break}
   hessian<-crossprod(xx,xx*pmax(pr*(1-pr),1e-15))/n+diag(l*penalty,p+1L)
   step<-tryCatch(as.numeric(solve(hessian,gradient)),error=function(e)NULL)
   liq_assert(!is.null(step)&&all(is.finite(step)),'Unsolvable ridge Hessian.')
   old<-objective(b,l);rate<-1;decrease<-sum(gradient*step)
   repeat {
    next_b<-b-rate*step;value<-objective(next_b,l)
    if(is.finite(value)&&value<=old-1e-4*rate*decrease+1e-14)break
    rate<-rate/2;liq_assert(rate>=2^-40,'Ridge line search failed.')
   }
   b<-next_b
  }
  gradient<-as.numeric(crossprod(xx,plogis(as.numeric(xx%*%b)+offset)-y))/n+l*penalty*b
  error<-max(abs(gradient));liq_assert(converged||error<=tolerance,'Ridge score equations did not converge.')
  coefficients[,k]<-b;audit[[k]]<-data.table(lambda=l,iterations=iter,max_abs_gradient=error,objective=objective(b,l))
 }
 fit<-list(a0=as.numeric(coefficients[1,]),beta=coefficients[-1,,drop=FALSE],lambda=lambda,dim=c(p,length(lambda)),nobs=n,jerr=0L,offset=any(offset!=0),numerical_audit=liq_bind(audit))
 class(fit)<-'liq_ridge_path';fit
}
coef.liq_ridge_path<-function(object,s=NULL,...) {
 idx<-if(is.null(s))seq_along(object$lambda)else vapply(as.numeric(s),function(l){j<-which.min(abs(object$lambda-l));liq_assert(abs(object$lambda[j]-l)<=1e-12*max(1,abs(l)),'Unfitted ridge penalty.');j},integer(1))
 z<-rbind(`(Intercept)`=object$a0[idx],object$beta[,idx,drop=FALSE]);colnames(z)<-paste0('s',seq_along(idx));z
}
predict.liq_ridge_path<-function(object,newx,s=NULL,type=c('link','response','coefficients','nonzero'),newoffset=NULL,...) {
 type<-match.arg(type);b<-coef(object,s=s)
 if(type=='coefficients')return(b)
 if(type=='nonzero')return(lapply(seq_len(ncol(b)),function(j)which(b[-1,j]!=0)))
 newx<-as.matrix(newx);liq_assert(ncol(newx)==nrow(b)-1L&&all(is.finite(newx)),'Ridge prediction design mismatch.')
 liq_assert(!isTRUE(object$offset)||!is.null(newoffset),'Frozen Cox offset required.')
 if(is.null(newoffset))newoffset<-rep(0,nrow(newx))
 liq_assert(length(newoffset)==nrow(newx)&&all(is.finite(newoffset)),'Ridge offset mismatch.')
 eta<-sweep(newx%*%b[-1,,drop=FALSE],2,b[1,],'+')+as.numeric(newoffset)
 if(type=='response')plogis(eta)else eta
}
liq_glmnet_v480<-function(x,y,...,lambda,.engine=NULL) {
 requested<-sort(unique(as.numeric(lambda)),decreasing=TRUE)
 args<-c(list(x=x,y=y),list(...),list(lambda=requested));engine<-if(is.null(.engine))glmnet::glmnet else .engine
 attempt<-function(a){warnings<-character();fit<-withCallingHandlers(tryCatch(do.call(engine,a),error=function(e)e),warning=function(w){warnings<<-c(warnings,conditionMessage(w));invokeRestart('muffleWarning')});list(fit=fit,warnings=warnings,valid=liq_v480_fit_valid(fit,x,requested))}
 first<-attempt(args);answer<-first;backend<-'glmnet_original';steps<-1L
 if(!first$valid) {
  retry<-args;retry$lambda<-sort(unique(c(requested,exp(seq(log(max(100,100*max(requested))),log(min(requested)),length.out=80L)))),decreasing=TRUE)
  retry$maxit<-1000000L;retry$thresh<-1e-9
  answer<-attempt(retry);backend<-'glmnet_warm_path';steps<-2L
  if(!answer$valid) {
   supported<-isTRUE(args$alpha==0)&&identical(args$family,'binomial')&&identical(args$standardize,FALSE)&&!identical(args$intercept,FALSE)&&is.null(args$weights)&&is.null(args$penalty.factor)
   liq_assert(supported,'Penalized model still invalid; no silent model-family switch.')
   answer<-list(fit=liq_v480_ridge(x,y,requested,offset=args$offset),warnings=character(),valid=TRUE);backend<-'ridge_Newton_same_objective';steps<-3L
  }
 }
 fit<-answer$fit;fit$call<-match.call()
 for(w in answer$warnings)warning(w,call.=FALSE)
 row<-data.table(n=nrow(x),p=ncol(x),alpha=args$alpha,has_offset=!is.null(args$offset),requested_penalties=length(requested),backend=backend,attempts=steps,valid=liq_v480_fit_valid(fit,x,requested),recovered=steps>1L,initial_diagnostic=paste(unique(c(first$warnings,if(inherits(first$fit,'error'))conditionMessage(first$fit)else character())),collapse=' | '),max_ridge_gradient=if(inherits(fit,'liq_ridge_path'))max(fit$numerical_audit$max_abs_gradient)else NA_real_)
 liq_v480_numerical_log$rows[[length(liq_v480_numerical_log$rows)+1L]]<-row
 attr(fit,'liq_v480_numerics')<-row;fit
}


# ===== V480 policy =====
liq_config_pre480<-liq_config
liq_config<-function() {
 cfg<-liq_config_pre480();cfg$version<-'4.8.0';cfg$frozen_file<-''
 cfg$probability_policy<-'Cox anchor; first chronological GUARD half proposes raw/calibrated residual; purged second half confirms with original paired one-SE margin'
 cfg$rank_policy<-'Cox anchor; first GUARD half selects Cox/residual/logit/hazard raw; second requires AUC gain >0.005 plus one block SE'
 cfg$protocol_status<-'retrospective development; historical TEST already seen; fixed fresh simulation seeds; no finite-sample safety guarantee'
 cfg
}
liq_v480_config<-function(stage=c('pilot','confirmation','full')) {
 stage<-match.arg(stage);cfg<-liq_config();cfg$mode<-'full';cfg$data_mode<-'csv';cfg$stage<-stage
 cfg$seed<-switch(stage,pilot=4800000L,confirmation=6800000L,full=5800000L)
 cfg$oracle_seed<-switch(stage,pilot=14800000L,confirmation=16800000L,full=15800000L)
 cfg$simulation_reps<-as.integer(Sys.getenv(paste0('LIQ_V480_',toupper(stage),'_REPS'),switch(stage,pilot='2',confirmation='20',full='100')))
 cfg$oracle_batches<-as.integer(Sys.getenv('LIQ_V480_ORACLE_BATCHES','8'))
 cfg$oracle_origins<-as.integer(Sys.getenv('LIQ_V480_ORACLE_ORIGINS',if(stage=='pilot')'250'else'2000'))
 cfg$conditional_boot_reps<-39L;cfg$out_dir<-Sys.getenv('LIQ_V480_OUT_DIR',file.path(dirname(cfg$source_path),paste0('out_liq_rec_v4_8_0_',stage)))
 cfg$simulation_scenarios<-c('signal','no_regime','prevalence_shift','regime_reversal','non_PH','strong_dependence')
 cfg$run_sensitivity<-cfg$run_rolling<-cfg$run_ablations<-cfg$run_panel_checks<-FALSE
 liq_assert(cfg$simulation_days>=900L&&cfg$simulation_assets==6L,'Declared calendar/six assets required.')
 liq_assert(cfg$simulation_reps>=1L&&cfg$simulation_reps<=999L&&cfg$oracle_batches>=4L&&cfg$oracle_origins>=50L,'Invalid experiment size.')
 cfg
}
liq_v480_protocol_key<-function(cfg)liq_hash(list(source=unname(tools::md5sum(cfg$source_path)),version=cfg$version,sessions=cfg$simulation_days,assets=cfg$simulation_assets,H=cfg$horizons,grid=list(cfg$correction_lambda_grid,cfg$correction_gamma_grid),fractions=cfg$correction_inner_fractions,groups=cfg$batch_groups,minH=cfg$batch_min_H,minimums=c(cfg$min_train,cfg$min_cal,cfg$min_guard,cfg$min_class,cfg$sn_min_dates),guard=c(cfg$guard_margin_z,cfg$guard_min_gain,cfg$rank_min_gain),policy=c(cfg$probability_policy,cfg$rank_policy)))
liq_v480_guard_split<-function(events,cfg) {
 dates<-sort(unique(events$shock_date));n<-length(dates)
 if(n<2L)return(list(propose=integer(),confirm=integer(),cut=as.Date(NA),first_confirmation=as.Date(NA)))
 cut<-dates[floor(n/2)];late<-which(events$shock_date>cut);first<-min(events$shock_date[late])
 early<-which(events$shock_date<=cut & !is.na(events$planned_end) & events$planned_end<first)
 list(propose=early,confirm=late,cut=cut,first_confirmation=first)
}
liq_v480_selection_support<-function(e,cfg) {
 nrow(e)>=cfg$min_guard&&all(vapply(cfg$horizons,function(h){y<-liq_truth(e,h)$y;pos<-is.finite(y)&y==1;neg<-is.finite(y)&y==0
 min(sum(pos),sum(neg))>=cfg$min_class&&min(uniqueN(e$shock_date[pos]),uniqueN(e$shock_date[neg]))>=cfg$selection_min_dates&&min(uniqueN(e$asset[pos]),uniqueN(e$asset[neg]))>=cfg$selection_min_assets},logical(1)))
}
liq_heads_before480<-liq_heads
liq_heads<-function(candidates,guard,cfg) {
 ans<-liq_heads_before480(candidates,guard,cfg)
 old<-copy(ans$choices[head%in%c('LIQ_Brier','LIQ_Rank_Guard')]);old[head=='LIQ_Brier',head:='LIQ_Brier_v470'];old[head=='LIQ_Rank_Guard',head:='LIQ_Rank_v470']
 for(ds in c('guard','test')){ans[[ds]]$LIQ_Brier_v470<-ans[[ds]]$LIQ_Brier;ans[[ds]]$LIQ_Rank_v470<-ans[[ds]]$LIQ_Rank_Guard}
 ans$gate_v470<-copy(ans$gate);split<-liq_v480_guard_split(guard,cfg);a<-split$propose;b<-split$confirm
 supported<-liq_v480_selection_support(guard[a],cfg)&&liq_v480_selection_support(guard[b],cfg)
 proposed<-intersect(c('CoxResidual_raw','CoxResidual_cal'),names(ans$guard));if(!length(proposed))proposed<-'Cox_raw'
 proposal<-if(length(a))proposed[which.min(vapply(proposed,function(m)mean(liq_loss_vector(guard[a],ans$guard[[m]][a,,drop=FALSE],cfg$horizons)),numeric(1)))]else 'Cox_raw'
 gate<-if(supported)liq_guard_delta(guard[b],ans$guard[[proposal]][b,,drop=FALSE],ans$guard$Cox_raw[b,,drop=FALSE],cfg)else list(estimate=NA_real_,se=NA_real_,blocks=0L,accepted=FALSE)
 selected<-if(isTRUE(gate$accepted)&&supported)proposal else 'Cox_raw'
 for(ds in c('guard','test'))ans[[ds]]$LIQ_Brier<-ans[[ds]][[selected]]
 ans$choices<-rbind(ans$choices[!head%in%c('LIQ_Brier','LIQ_Rank_Guard')],old,fill=TRUE)
 rankgate<-list()
 for(j in seq_along(cfg$horizons)) {
  h<-cfg$horizons[j];pool<-intersect(c('Cox_raw','CoxResidual_raw','Logit_raw','Hazard_raw'),names(ans$guard))
  ya<-liq_truth(guard[a],h)$y
  scores<-if(length(a))vapply(pool,function(m)liq_auc(ya,ans$guard[[m]][a,j]),numeric(1))else rep(NA_real_,length(pool))
  rp<-if(any(is.finite(scores)))pool[which.max(replace(scores,!is.finite(scores),-Inf))]else 'Cox_raw'
  gain<-se<-NA_real_;G<-0L;accepted<-FALSE
  if(supported) {
   y<-liq_truth(guard[b],h)$y;p<-ans$guard[[rp]][b,j];q<-ans$guard$Cox_raw[b,j]
   gain<-liq_auc(y,p)-liq_auc(y,q);inf<-liq_auc_influence(y,p)-liq_auc_influence(y,q)
   block<-floor((guard$sid[b]-min(guard$sid[b]))/cfg$block_length)
   zz<-data.table(block=block,v=inf)[,.(total=sum(v),n=.N),by=block];G<-nrow(zz)
   se<-if(G>1L)sqrt(G/(G-1)*sum((zz$total-zz$n*mean(inf))^2))/length(inf)else Inf
   accepted<-is.finite(gain)&&is.finite(se)&&gain>cfg$rank_min_gain+cfg$guard_margin_z*se
  }
  src<-if(accepted)rp else 'Cox_raw'
  for(ds in c('guard','test'))ans[[ds]]$LIQ_Rank_Guard[,j]<-ans[[ds]][[src]][,j]
  rankgate[[j]]<-data.table(horizon=h,proposal=rp,selected=src,delta_AUC=gain,block_SE=se,n_blocks=G,selection_allowed=supported,accepted=accepted)
  ans$choices<-rbind(ans$choices,data.table(head='LIQ_Rank_Guard',horizon=h,component1=src,component2=src,weight1=1,selected_source=src),data.table(head='LIQ_Brier',horizon=h,component1='Cox_raw',component2=proposal,weight1=as.numeric(selected=='Cox_raw'),selected_source=selected),fill=TRUE)
 }
 ans$gate<-data.table(proposal=proposal,single='Cox_raw',selected=selected,delta_Brier=gate$estimate,block_SE=gate$se,n_blocks=gate$blocks,selection_allowed=supported,accepted=isTRUE(gate$accepted)&&supported)
 ans$rank_gate<-liq_bind(rankgate);ans$rank_names<-unique(c(ans$rank_names,'LIQ_Rank_v470'))
 ans$weights<-liq_bind(lapply(cfg$horizons,function(h)data.table(horizon=h,component=c('Cox_raw',proposed),weight=as.numeric(c('Cox_raw',proposed)==selected),selected_source=selected)))
 ans$guard_split<-liq_bind(lapply(c('proposal','confirmation'),function(stage){idx<-if(stage=='proposal')a else b;data.table(stage=stage,n=length(idx),first_origin=if(length(idx))min(guard$shock_date[idx])else as.Date(NA),last_origin=if(length(idx))max(guard$shock_date[idx])else as.Date(NA),last_planned_label=if(length(idx))max(guard$planned_end[idx])else as.Date(NA))}))
 ans
}
# General frozen head replay includes every retained version, with no TEST labels.
liq_v470_frozen_predictions<-function(cand,train,new,choices,cfg) {
 p<-liq_fitted_candidate_predictions(cand,train,new,cfg);H<-cfg$horizons
 for(nm in unique(choices$head)) {
  ans<-matrix(NA_real_,nrow(new),length(H),dimnames=list(NULL,H))
  for(j in seq_along(H)) {
   local_head<-nm;local_h<-H[j];ch<-choices[head==local_head&horizon==local_h]
   if(nrow(ch)!=1L)next
   src<-if('selected_source'%in%names(ch)&&!is.na(ch$selected_source))ch$selected_source else ch$component1
   if(!src%in%names(p))next
   if(!is.na(ch$component2)&&ch$component2%in%names(p)&&!('selected_source'%in%names(ch)&&!is.na(ch$selected_source)))ans[,j]<-ch$weight1*p[[ch$component1]][,j]+(1-ch$weight1)*p[[ch$component2]][,j]else ans[,j]<-p[[src]][,j]
  }
  if(all(is.finite(ans)))p[[nm]]<-ans
 }
 p
}


# ===== V480 experiment =====
liq_v480_pairs<-function(e,pred,cfg,calendar,choices,correction) {
 ans<-liq_batch_pairs(e,pred,cfg,calendar,choices,correction);rows<-list(ans)
 for(pair in list(c('CoxResidual_cal','Cox_cal','Brier'),c('LIQ_Brier','Cox_cal','Brier'),c('LIQ_Rank_Guard','Logit_raw','AUC')))if(all(pair[1:2]%in%names(pred)))for(j in seq_along(cfg$horizons)) {
  y<-liq_truth(e,cfg$horizons[j])$y;ok<-is.finite(y);p<-pred[[pair[1]]][ok,j];q<-pred[[pair[2]]][ok,j];a<-pair[3]=='AUC'
  same<-identical(as.numeric(p),as.numeric(q));zero<-!is.null(correction)&&(correction$type=='identity'||correction$gamma==0);identity<-FALSE
  if(pair[1]=='CoxResidual_cal')identity<-zero&&same
  if(pair[1]=='LIQ_Brier'){h<-cfg$horizons[j];ch<-choices[head=='LIQ_Brier'&horizon==h];identity<-zero&&nrow(ch)==1L&&ch$selected_source=='CoxResidual_cal'&&same}
  estimate<-if(a)liq_auc(y[ok],p)-liq_auc(y[ok],q)else mean((p-y[ok])^2-(q-y[ok])^2)
  inf<-if(a)liq_auc_influence(y[ok],p)-liq_auc_influence(y[ok],q)else(p-y[ok])^2-(q-y[ok])^2
  iv<-liq_batch_interval(e[ok],calendar,inf,estimate,cfg,K=length(cfg$horizons),identity=identity,auc=a,y=y[ok])
  rows[[length(rows)+1L]]<-cbind(data.table(model=pair[1],reference=pair[2],metric=pair[3],horizon=cfg$horizons[j],family='matched_calibration_or_benchmark_diagnostic',family_size=length(cfg$horizons),identical_output=same,algebraic_identity=identity,target='marginal future-origin risk; frozen fitted rules'),as.data.table(iv))
 }
 liq_bind(rows)
}
liq_v480_one<-function(cfg,scenario,replication,path,policy=c('v480','v470'),oracle=TRUE) {
 policy<-match.arg(policy);liq_v480_numerical_reset();d<-liq_simulated_events(cfg,scenario,replication);b<-liq_v470_blocks(d)
 liq_save(liq_class_support(d$events,cfg),'role_class_support',path);liq_require_simulation_support(d$events,b,cfg)
 cand<-liq_candidates(b$TRAIN,b$CAL_FIT,b$GUARD,b$TEST,cfg)
 hd<-if(policy=='v480')liq_heads(cand,b$GUARD,cfg)else liq_heads_before480(cand,b$GUARD,cfg)
 cs<-liq_v470_correction_status(cand,cfg);num<-liq_v480_numerical_table();liq_assert(nrow(num)>0&&all(num$valid),'Unvalidated penalized fit.')
 for(n in c('tuning','validation','audit'))liq_save(cand$fits$Correction[[n]],paste0('correction_',n),path)
 liq_save(num,'numerical_fit_audit',path);liq_save(cs,'correction_status',path);liq_save(hd$choices,'selected_components',path);liq_save(hd$gate,'GUARD_probability_gate',path)
 for(n in c('rank_gate','guard_split','gate_v470'))if(!is.null(hd[[n]]))liq_save(hd[[n]],paste0('GUARD_',n),path)
 replay<-liq_v470_frozen_predictions(cand,b$TRAIN,b$TEST,hd$choices,cfg);nm<-intersect(names(replay),names(hd$test))
 err<-max(vapply(nm,function(m)max(abs(replay[[m]]-hd$test[[m]])),numeric(1)));liq_assert(err<1e-12,'Frozen replay differs.')
 pt<-liq_evaluate(b$TEST,hd$test,cfg,hd$rank_names);pairs<-liq_v480_pairs(b$TEST,hd$test,cfg,d$calendar,hd$choices,cand$fits$Correction)
 aud<-oo<-data.table()
 if(oracle) {
  oo<-liq_v470_marginal_oracle(cand,b$TRAIN,hd$choices,d$dgp_context,pairs,cfg,replication)
  aud<-copy(attr(oo,'oracle_target_audit'));liq_save(aud,'oracle_target_audit',path)
  liq_save(attr(oo,'oracle_independent_targets'),'oracle_independent_targets',path);liq_save(attr(oo,'oracle_batch_deltas'),'oracle_MC_batch_deltas',path);liq_save(oo,'marginal_oracle_coverage',path)
 }
 selected<-hd$gate$selected[1]
 deployment<-data.table(selected_source=selected,residual_gamma=cs$gamma,residual_fitted_active=cs$active,residual_deployed=cs$active&&selected%in%c('CoxResidual_raw','CoxResidual_cal'),calibration_deployed=grepl('_cal$',selected),Cox_fallback=selected=='Cox_raw',gate_accepted=hd$gate$accepted[1],rank_non_Cox_horizons=if(!is.null(hd$rank_gate))sum(hd$rank_gate$selected!='Cox_raw')else NA_integer_)
 kept<-intersect(c('Cox_raw','Cox_cal','CoxResidual_raw','CoxResidual_cal','Logit_raw','LIQ_Brier','LIQ_Rank_Guard','LIQ_Brier_v470','LIQ_Rank_v470'),names(hd$test))
 liq_save(liq_long_predictions(b$TEST,hd$test[kept],cfg,intersect(hd$rank_names,kept)),'frozen_test_predictions',path)
 liq_save(pt,'performance',path);liq_save(pairs,'calendar_batch_paired_intervals',path);liq_save(deployment,'head_deployment',path)
 liq_save(data.table(check='frozen replay',pass=err<1e-12,max_abs_difference=err),'frozen_prediction_check',path)
 if(!identical(cfg$stage,'confirmation'))liq_save_rds_atomic(list(candidates=cand,train=b$TRAIN,test=b$TEST,guard=b$GUARD,choices=hd$choices,calendar=d$calendar,context=d$dgp_context,cfg=cfg),file.path(path,'fitted_rules.rds'))
 rows<-list(point=pt,interval=pairs,oracle=oo,correction=cs,deployment=deployment,numerical=num,oracle_audit=aud)
 for(n in names(rows))if(nrow(rows[[n]]))rows[[n]][,`:=`(scenario=scenario,replication=replication)]
 rows
}
liq_v480_summary<-function(values,cfg,status) {
 kinds<-c(point='S48001_performance',interval='S48002_paired_intervals',oracle='S48003_oracle_coverage',correction='S48004_correction_status',deployment='S48005_head_deployment',numerical='S48006_numerical_audit',oracle_audit='S48007_oracle_audit')
 z<-lapply(names(kinds),function(n)liq_bind(lapply(values,`[[`,n)));names(z)<-names(kinds)
 for(n in names(z))liq_save(z[[n]],kinds[n],cfg$out_dir)
 liq_save(status,'RUN_STATUS',cfg$out_dir);if(!nrow(z$point))return(invisible(z))
 rep<-z$point[,.(Brier=liq_mean(Brier),AUC=liq_mean(AUC),n_horizons=.N),by=.(scenario,replication,model)]
 liq_save(rep,'T48001_replication_means',cfg$out_dir);liq_save(rep[,.(replications=.N,Brier=liq_mean(Brier),AUC=liq_mean(AUC)),by=.(scenario,model)],'T48002_scenario_means',cfg$out_dir)
 comparisons<-list(c('LIQ_Brier','Cox_raw','Brier'),c('LIQ_Brier','Cox_cal','Brier'),c('LIQ_Brier','Logit_raw','Brier'),c('CoxResidual_raw','Cox_raw','Brier'),c('CoxResidual_cal','Cox_cal','Brier'),c('LIQ_Brier','LIQ_Brier_v470','Brier'),c('LIQ_Rank_Guard','Cox_raw','AUC'),c('LIQ_Rank_Guard','Logit_raw','AUC'),c('LIQ_Rank_Guard','LIQ_Rank_v470','AUC'))
 diffs<-list()
 for(pair in comparisons) {
  m<-pair[1];r<-pair[2];met<-pair[3];a<-rep[model==m,.(scenario,replication,value=get(met))];b<-rep[model==r,.(scenario,replication,baseline=get(met))]
  q<-merge(a,b,by=c('scenario','replication'));q<-q[is.finite(value)&is.finite(baseline)];if(!nrow(q))next
  q[,`:=`(delta=value-baseline,model=m,reference=r,metric=met)];diffs[[length(diffs)+1L]]<-q
 }
 paired<-liq_bind(diffs);liq_save(paired,'T48003_paired_replication_differences',cfg$out_dir)
 ss<-paired[,{
  n<-.N;est<-mean(delta);se<-if(n>1L)sd(delta)/sqrt(n)else NA_real_;k<-if(n>1L)qt(.975,n-1L)else NA_real_;kk<-if(n>1L)qt(1-.05/(2*54),n-1L)else NA_real_
  .(n_replications=n,mean_model=mean(value),mean_reference=mean(baseline),mean_delta=est,MC_SE=se,MC_lower=est-k*se,MC_upper=est+k*se,simultaneous_MC_lower=est-kk*se,simultaneous_MC_upper=est+kk*se,win_rate=mean(if(metric[1]=='Brier')delta< -1e-12 else delta>1e-12),equal_rate=mean(abs(delta)<=1e-12))
 },by=.(scenario,model,reference,metric)]
 liq_save(ss,'T48004_paired_MC_summary',cfg$out_dir)
 liq_save(status[,.(attempted=.N,completed=sum(status=='completed'),unsupported=sum(status=='insufficient_sample'),failed=sum(status=='failed'))],'T48005_attempts',cfg$out_dir)
 invisible(z)
}
liq_v480_gate_ok<-function(gate,cfg) {
 required<-c('no_software_failures','all_scenarios_represented','valid_forward_selection','validated_numerics','independent_oracle_audit')
 is.list(gate)&&identical(gate$version,cfg$version)&&isTRUE(gate$pass)&&identical(gate$key,liq_v480_protocol_key(cfg))&&all(required%in%names(gate$checks))&&all(vapply(required,function(n)isTRUE(gate$checks[[n]]),logical(1)))
}
liq_v480_run<-function(stage=c('pilot','confirmation','full')) {
 stage<-match.arg(stage);cfg<-liq_v480_config(stage);liq_packages(cfg);liq_dir(cfg$out_dir)
 if(stage!='pilot') {
  p<-file.path(Sys.getenv('LIQ_V480_PILOT_DIR',file.path(dirname(cfg$source_path),'out_liq_rec_v4_8_0_pilot')),'V480_PILOT_GATE.rds')
  liq_assert(file.exists(p)&&liq_v480_gate_ok(readRDS(p),cfg),'Run the current-source pilot first; protocol/numerical receipt must match.')
 }
 oldlog<-getOption('liq.log.file');options(liq.log.file=file.path(cfg$out_dir,'run.log'));on.exit(options(liq.log.file=oldlog),add=TRUE)
 liq_save_rds_atomic(cfg,file.path(cfg$out_dir,'configuration.rds'));capture.output(sessionInfo(),file=file.path(cfg$out_dir,'sessionInfo.txt'))
 liq_dir(file.path(cfg$out_dir,'source'));file.copy(cfg$source_path,file.path(cfg$out_dir,'source',basename(cfg$source_path)),overwrite=TRUE)
 tm<-liq_task_manager(cfg,paste('v480',stage,cfg$seed,sep='-'));values<-list()
 subset<-strsplit(Sys.getenv('LIQ_V480_SCENARIOS',paste(cfg$simulation_scenarios,collapse=',')),',',fixed=TRUE)[[1]]
 liq_assert(all(subset%in%cfg$simulation_scenarios),'Unknown scenario partition.')
 for(sc in subset)for(r in seq_len(cfg$simulation_reps)) {
  id<-sprintf('simulation_%s_%03d',sc,r)
  v<-tm$run(id,paste0(stage,'_simulation'),function(path)liq_v480_one(cfg,sc,r,path,oracle=stage!='confirmation'),signature=list(protocol=liq_v480_protocol_key(cfg),oracle=stage!='confirmation',seed=cfg$seed,oracle_seed=cfg$oracle_seed))
  if(!is.null(v))values[[id]]<-v
 }
 st<-tm$status();summary_cfg<-cfg;summary_cfg$out_dir<-Sys.getenv('LIQ_V480_PROGRESS_DIR',cfg$out_dir);z<-liq_v480_summary(values,summary_cfg,st)
 if(length(subset)<length(cfg$simulation_scenarios))return(invisible(list(cfg=cfg,status=st)))
 checks<-c(no_software_failures=nrow(st)==length(cfg$simulation_scenarios)*cfg$simulation_reps&&!any(st$status=='failed'),all_scenarios_represented=nrow(z$point)>0L&&all(cfg$simulation_scenarios%in%z$point$scenario),valid_forward_selection=nrow(z$correction)>0L&&all(z$correction$valid_meta_periods>=2L),validated_numerics=nrow(z$numerical)>0L&&all(z$numerical$valid),independent_oracle_audit=stage=='confirmation'||(nrow(z$oracle_audit)>0L&&all(z$oracle_audit$pass)))
 gate<-list(version=cfg$version,pass=all(checks),key=liq_v480_protocol_key(cfg),checks=checks,superiority_required=FALSE,created=Sys.time())
 if(stage=='pilot')liq_save_rds_atomic(gate,file.path(cfg$out_dir,'V480_PILOT_GATE.rds'))
 liq_save(data.table(check=names(checks),pass=checks),'STRUCTURAL_CHECKS',cfg$out_dir)
 writeLines(c(paste('LIQ-REC',cfg$version,stage),paste('Completed',sum(st$status=='completed'),'Unsupported',sum(st$status=='insufficient_sample'),'Failed',sum(st$status=='failed')),cfg$probability_policy,cfg$rank_policy,cfg$protocol_status,'All declared attempts retained. No performance-based stopping, threshold relaxation or reseeding.',if(stage=='confirmation')'Forecast-only confirmation; oracle not evaluated. Full 600-attempt forecasting/oracle experiment is separate.'else'Independent MC oracle retained; pilot counts do not establish coverage.','MC intervals quantify replication error; not market-generalization intervals.'),file.path(cfg$out_dir,'RUN_SCOPE.txt'))
 liq_assert(all(checks),'Structural checks failed; inspect task status and numerical/oracle audits.')
 invisible(list(cfg=cfg,status=st,gate=gate))
}


# ===== V480 market =====
liq_v480_market<-function() {
 cfg<-liq_config();cfg$mode<-'full';cfg$data_mode<-'csv';cfg$frozen_file<-'';cfg$out_dir<-Sys.getenv('LIQ_V480_MARKET_OUT_DIR',file.path(dirname(cfg$source_path),'out_liq_rec_v4_8_0_market'));cfg$run_simulation<-FALSE
 liq_packages(cfg);liq_validate_config(cfg);liq_dir(cfg$out_dir);oldlog<-getOption('liq.log.file');options(liq.log.file=file.path(cfg$out_dir,'run.log'));on.exit(options(liq.log.file=oldlog),add=TRUE)
 dat<-liq_get_data(cfg);cfg<-dat$cfg;liq_universe_audit(dat,cfg);input_hash<-liq_hash_file(cfg$input_csv)
 ff<-file.path(cfg$out_dir,'daily_features.rds');key<-liq_hash(list(input=input_hash,source=liq_source_identity(cfg)$hash))
 cache<-if(file.exists(ff))tryCatch(readRDS(ff),error=function(e)NULL)else NULL
 features<-if(!is.null(cache)&&identical(cache$key,key))cache$features else {f<-liq_raw_features(dat$panel,cfg);liq_save_rds_atomic(list(key=key,features=f),ff);f}
 rm(cache);gc(FALSE);capture.output(sessionInfo(),file=file.path(cfg$out_dir,'sessionInfo.txt'));liq_save_rds_atomic(cfg,file.path(cfg$out_dir,'configuration.rds'))
 liq_dir(file.path(cfg$out_dir,'source'));file.copy(cfg$source_path,file.path(cfg$out_dir,'source',basename(cfg$source_path)),overwrite=TRUE)
 schedule<-liq_rolling_schedule(dat$calendar,cfg);liq_save(schedule,'R48001_rolling_schedule',cfg$out_dir);regular<-schedule[rolling_role=='regular']
 designs<-c(list(list(id='primary',role='primary',fold=cfg$fold)),lapply(seq_len(nrow(regular)),function(j)list(id=regular$design[j],role='regular',fold=liq_fold_on_calendar(dat$calendar[regular$first_sid[j]:regular$last_sid[j]],cfg$rolling_fractions))))
 tm<-liq_task_manager(cfg,paste('market',input_hash,sep='-'));values<-list()
 for(design in designs) {
  id<-design$id;role<-design$role;fold<-design$fold
  v<-tm$run(id,role,function(path) {
   liq_v480_numerical_reset();cc<-cfg;cc$fold<-fold;fit<-liq_outer(features,dat$calendar,cc,fold=fold,out=path,inference=FALSE)
   liq_save(liq_v480_numerical_table(),'numerical_fit_audit',path)
   liq_save(fit$heads$guard_split,'GUARD_guard_split',path);liq_save(fit$heads$rank_gate,'GUARD_rank_gate',path);liq_save(fit$heads$gate_v470,'GUARD_gate_v470',path)
   replay<-liq_v470_frozen_predictions(fit$candidates,fit$blocks$TRAIN,fit$blocks$TEST,fit$heads$choices,cc)
   nm<-intersect(names(replay),names(fit$heads$test));err<-max(vapply(nm,function(n)max(abs(replay[[n]]-fit$heads$test[[n]])),numeric(1)));liq_assert(err<1e-12,'Market frozen replay differs.')
   liq_save_rds_atomic(list(candidates=fit$candidates,train=fit$blocks$TRAIN,test=fit$blocks$TEST,guard=fit$blocks$GUARD,choices=fit$heads$choices,calendar=dat$calendar,cfg=cc),file.path(path,'fitted_rules.rds'))
   liq_save(liq_long_predictions(fit$blocks$TEST,fit$heads$test,cc,fit$heads$rank_names),'frozen_test_predictions',path)
   point<-copy(fit$point);point[,`:=`(design=id,window_role=role)];gate<-copy(fit$heads$gate);gate[,`:=`(design=id,window_role=role)]
   list(point=point,gate=gate,n_TEST=nrow(fit$blocks$TEST),replay_error=err)
  },signature=list(fold=fold,protocol=liq_v480_protocol_key(cfg),input_hash=input_hash))
  if(!is.null(v))values[[id]]<-v
  if(length(values)){liq_save(liq_bind(lapply(values,`[[`,'point')),'R48002_market_performance',cfg$out_dir);liq_save(liq_bind(lapply(values,`[[`,'gate')),'R48003_market_GUARD_decisions',cfg$out_dir)}
 }
 st<-tm$status();liq_save(st,'RUN_STATUS',cfg$out_dir)
 if(length(values)) {
  point<-liq_bind(lapply(values,`[[`,'point'));per<-point[,.(Brier=liq_mean(Brier),AUC=liq_mean(AUC)),by=.(design,window_role,model)]
  liq_save(per,'R48004_per_window_equal_horizon',cfg$out_dir)
  ss<-per[window_role=='regular',.(n_windows=uniqueN(design),Brier=liq_mean(Brier),AUC=liq_mean(AUC)),by=model];ss[,scope:='equal regular-window/horizon weights; historical retrospective analysis; no iid-window SE'];liq_save(ss,'R48005_regular_window_summary',cfg$out_dir)
 }
 writeLines(c('Locked 100-asset market snapshot. No new download. Primary plus every regular rolling design.','Nested TRAIN preprocessing, CAL-FIT and purged two-stage GUARD. Historical TEST already inspected.','Unsupported windows retained without pooling or lower thresholds; appended tail excluded.','Rolling windows share histories and can overlap; no independent-window uncertainty claim.',paste('Completed',sum(st$status=='completed'),'Unsupported',sum(st$status=='insufficient_sample'),'Failed',sum(st$status=='failed'))),file.path(cfg$out_dir,'RUN_SCOPE.txt'))
 liq_assert(!any(st$status=='failed'),'Market software failure; inspect RUN_STATUS.');invisible(list(cfg=cfg,status=st))
}


# ===== V480 fast =====
# Exact allocation shortcuts; unchanged RNG calls and formulas.
liq_simulated_events_reference<-liq_simulated_events
liq_cdf_reference<-liq_cdf
liq_simulated_events_fast <- function(cfg,scenario,replication) {
  # A declared confirmation-time DGP. Shared calendar shocks induce overlapping
  # outcome dependence. This DGP does not model order-book liquidity.
  set.seed(cfg$seed+replication)
  n<-max(700L,cfg$simulation_days);A<-cfg$simulation_assets
  calendar<-seq(as.Date("2005-01-03"),by="day",length.out=ceiling(n*1.5))
  calendar<-calendar[as.POSIXlt(calendar)$wday%in%1:5][seq_len(n)]
  fold<-liq_fold_on_calendar(calendar);train_end<-fold$to[1]
  common<-as.numeric(stats::arima.sim(list(ar=.90),n=n+cfg$max_h))
  common<-common*sqrt(1-.90^2);time_noise<-rnorm(n+cfg$max_h)
  origin<-seq.int(80L,n-1L,by=5L);asset_effect<-rnorm(A,0,.25)
  cuts<-c(-.5,.5);rows<-list();oracle<-list();z<-0L
  for(t in origin)for(a in seq_len(A)) {
    z<-z+1L;x<-rnorm(1);market<-common[t];shifted<-calendar[t]>train_end
    beta<-if(scenario=="no_regime")0 else .75
    if(scenario=="regime_reversal"&&shifted)beta<- -.75
    offset<-if(scenario=="prevalence_shift"&&shifted)1.1 else 0
    rho<-if(scenario=="strong_dependence").9 else .55
    days<-seq_len(cfg$max_h)
    effect_x<-if(scenario=="non_PH")ifelse(days<=10,.9,-.9)else rep(.65,length(days))
    hazard<-plogis(qlogis(.045)+effect_x*x+beta*market+asset_effect[a]+offset)
    hazard[days<cfg$k]<-0
    uniform<-pnorm(rho*time_noise[t+days]+sqrt(1-rho^2)*rnorm(length(days)))
    hit<-which(uniform<hazard);follow<-min(cfg$max_h,n-t)
    duration<-if(length(hit)&&hit[1]<=follow)hit[1]else follow
    recovered<-as.integer(length(hit)>0&&hit[1]<=follow)
    e<-setNames(rep(list(0),length(liq_feature_names())),liq_feature_names())
    updates<-list(lsi=2+abs(x),lsi_lag1=1+abs(x),lsi_mom5=x,shock_severity_pct=pnorm(x),
      abs_ret=abs(rnorm(1,.01,.005)),absret5=.01,rv5=.0001,
      range_pct=.02+abs(x)*.005,volume_shock=-x,pressure=pmax(x,0)*.02,
      log_dvol=16+x*.2,market_loo=market,market_loo_lag1=common[t-1L],market_full=market,
      market_trend5=market-common[t-5L],market_percentile=pnorm(market),
      shock_cluster_share=plogis(market),shock_cluster_share_lag1=plogis(common[t-1L]),
      volume_breadth_lag1=plogis(common[t-1L]),avg_corr_lag1=.3,vix_lag1=20+3*market,
      vix_change5=3*(market-common[t-5L]),is_stock=as.numeric(a>A/2),is_sector=as.numeric(a<=A/2),
      event_id=paste0("SIM_",replication,"_",t,"_",a),asset=paste0("A",a),
      shock_date=calendar[t],sid=t,duration=as.integer(duration),status=recovered,
      followup=as.integer(follow),planned_end=if(t+cfg$max_h<=n)calendar[t+cfg$max_h]else as.Date(NA),
      observed_end=calendar[t+follow],role="OUTSIDE",analysis_eligible=FALSE,
      confirmation_day=if(recovered)duration else NA_integer_,
      recovery_start_day=if(recovered)duration-cfg$k+1L else NA_integer_,
      censor_reason=if(recovered)"recovered"else if(follow==cfg$max_h)"Hmax"else"data_end")
    e[names(updates)]<-updates
    for(j in seq_len(nrow(fold)))if(calendar[t]>=fold$from[j]&&calendar[t]<=fold$to[j]) {
      e$role<-fold$role[j]
      e$analysis_eligible<-!is.na(e$planned_end)&&e$planned_end<=fold$to[j]&&e$followup>=cfg$max_h
    }
    e$regime<-if(market<=cuts[1])"Low"else if(market<=cuts[2])"Normal"else"High"
    rows[[z]]<-e
    oracle[[z]]<-list(event_id=e$event_id,horizon=cfg$horizons,
      true_probability=(1-cumprod(1-hazard))[cfg$horizons])
  }
  e<-liq_bind(rows)
  # The observed regime boundaries are TRAIN-only, regardless of true DGP effects.
  q<-quantile(e[role=="TRAIN" & analysis_eligible==TRUE,market_loo],cfg$regime_quantiles)
  e[,regime:=ifelse(market_loo<=q[1],"Low",ifelse(market_loo<=q[2],"Normal","High"))]
  list(events=e,oracle=liq_bind(oracle),calendar=calendar,fold=fold,
    scenario=scenario,replication=replication,
    dgp_context=list(asset_effect=asset_effect,regime_cuts=q,scenario=scenario,seed=cfg$seed+replication))
}
liq_cdf_fast<-function(p) {
 p<-as.matrix(p);if(!nrow(p))return(p)
 if(any(!is.finite(p)))return(liq_cdf_reference(p))
 ans<-liq_clip(p)
 if(ncol(p)>1L){bad<-which(rowSums(ans[,-1L,drop=FALSE]<ans[,-ncol(ans),drop=FALSE])>0L);for(i in bad)ans[i,]<-liq_pava(ans[i,])}
 dimnames(ans)<-dimnames(p);ans
}
liq_cdf<-liq_cdf_fast
liq_simulated_events<-liq_simulated_events_fast


# ===== V480 final_io =====
liq_save_rds_atomic<-function(object,path) {
 liq_dir(dirname(path));tmp<-tempfile(paste0(basename(path),'_'),tmpdir=dirname(path),fileext='.tmp');on.exit(if(file.exists(tmp))unlink(tmp),add=TRUE)
 saveRDS(object,tmp,compress='gzip',version=3)
 liq_assert(file.exists(tmp)&&file.info(tmp)$size>0&&isTRUE(all.equal(readRDS(tmp),object,tolerance=0,check.attributes=FALSE)),'Incomplete/differing checkpoint roundtrip.')
 if(suppressWarnings(file.rename(tmp,path)))return(invisible(path))
 liq_assert(file.exists(path),'Checkpoint target absent.');backup<-tempfile(paste0(basename(path),'_rollback_'),tmpdir=dirname(path))
 liq_assert(file.rename(path,backup),'Cannot preserve original checkpoint.')
 if(!suppressWarnings(file.rename(tmp,path))){restored<-file.rename(backup,path);stop(if(restored)'Checkpoint commit failed; original restored.'else paste('Recover original from',backup),call.=FALSE)}
 unlink(backup);invisible(path)
}
liq_model_spec_before480<-liq_model_spec
liq_model_spec<-function(cfg) {
 d<-liq_model_spec_before480(cfg);d[item=='probability_combination',value:=cfg$probability_policy];d[item=='rank_ensemble',value:=cfg$rank_policy]
 rbind(d,data.table(item=c('GUARD_maturity','numerical_recovery','execution','development_status'),value=c('Calendar-median split; proposal labels close strictly before confirmation starts; same support floors in both halves.','Validate jerr, dimensions, all requested penalties and finite coefficients; same-family warm path then score-verified ridge Newton.','Exact DGP list allocation and monotone-row PAVA shortcut; full reference/RNG equivalence tests included.',cfg$protocol_status)))
}

if(!identical(tolower(Sys.getenv("LIQ_AUTORUN","true")),"false"))liq_v480_run("pilot")
