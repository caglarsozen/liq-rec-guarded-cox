# Mathematical and information-flow regression tests; no historical model fitting.
m <- liq_load_model();cfg <- m$liq_config();cfg$install <- FALSE;m$liq_packages(cfg)
checks <- character()
check <- function(name,ok) {
  if(!isTRUE(ok))stop("FAILED: ",name)
  checks <<- c(checks,name);cat("PASS:",name,"\n")
}
check("frozen scientific source",unname(tools::md5sum(m$LIQ_SOURCE_PATH))=="ed19ad4035b799915163897644a8515c")
check("horizons and endpoint",identical(cfg$horizons,c(5L,10L,20L,30L)) && cfg$k==3L && cfg$max_h==30L)
e <- data.frame(status=c(0L,1L,0L,1L),duration=c(30L,30L,8L,5L),followup=c(30L,30L,8L,30L))
check("known endpoint negative is retained",identical(m$liq_truth(e,30L)$y,c(0L,1L,NA_integer_,1L)))
check("incomplete follow-up remains unknown",is.na(m$liq_truth(e,10L)$y[3L]))
check("tied AUC receives half credit",abs(m$liq_auc(c(0,1,0,1),rep(.5,4))-.5)<1e-14)
check("perfect AUC orientation",m$liq_auc(c(0,0,1,1),c(.1,.2,.8,.9))==1)
set.seed(20261103)
p <- matrix(runif(80),20,4);q <- m$liq_cdf(p)
check("horizon probabilities are coherent",all(q>=0 & q<=1) && all(q[,-1,drop=FALSE]>=q[,-4,drop=FALSE]))
targets <- t(vapply(sample(0:4,20,replace=TRUE),function(k)as.numeric(seq_len(4)>k),numeric(4)))
check("projection squared-loss inequality",all(rowSums((q-targets)^2)<=rowSums((p-targets)^2)-rowSums((q-p)^2)+1e-12))
y <- c(rep(1,37),rep(0,63))
for(prob in c(1e-6,.05,.5,.95,1-1e-6)) {
  got <- m$liq_calibration(y,rep(prob,100))["CITL"]
  expected <- qlogis(.37)-qlogis(prob)
  check(paste("CITL analytic constant",prob),abs(got-expected)<1e-10)
}
w <- seq_along(y)
check("CITL weighted analytic solution",abs(m$liq_citl_stable_v480(y,rep(.8,100),w)-
  (qlogis(sum(w*y)/sum(w))-qlogis(.8)))<1e-10)
check("CITL insufficient support",is.na(m$liq_calibration(c(1,rep(0,99)),rep(.5,100))["CITL"]))
dates <- as.Date("2020-01-01")+0:119
guard <- data.table::data.table(shock_date=dates,planned_end=dates+30)
split <- m$liq_v480_guard_split(guard,cfg)
check("proposal labels mature before confirmation",max(guard$planned_end[split$propose])<min(guard$shock_date[split$confirm]))

# Hand-designed paths test confirmation-day dating, overlap and complete-window eligibility.
calendar <- as.Date("2011-01-01")+0:349
panel <- data.table::CJ(asset=c("A","B","C"),sid=seq_along(calendar))
panel[,date:=calendar[sid]];panel[,member:=TRUE]
for(n in setdiff(m$liq_feature_names(),c("shock_cluster_share","shock_cluster_share_lag1")))panel[,(n):=0]
panel[sid%in%seq(10L,280L,10L),lsi:=5]
panel[sid==301L,lsi:=10]
panel[asset=="A" & sid==304L,lsi:=2]
panel[asset=="B" & sid%in%302:331,lsi:=1]
fold <- data.frame(role=c("TRAIN","TEST"),from=calendar[c(1,301)],to=calendar[c(300,350)])
fixture <- m$liq_events(panel,calendar,cfg,fold)$events
a <- fixture[asset=="A" & sid==301L];b <- fixture[asset=="B" & sid==301L]
check("recovery is dated at confirmation end",nrow(a)==1L && a$duration==6L && a$recovery_start_day==4L)
check("complete 30-session non-recovery is negative",nrow(b)==1L && b$followup==30L && b$status==0L && b$y30==0L && b$analysis_eligible)
starts <- fixture[asset=="B" & role=="TEST",sid]
check("accepted origins are at least six sessions apart",length(starts)>1L && all(diff(starts)>=6L) && any(diff(starts)<30L))

# Force a failed solver to test the same-objective ridge recovery and S3 dispatch.
x <- matrix(rnorm(800),200,4);off <- seq(-1,1,length.out=200)
yy <- as.integer(seq_len(200)%%3==0);lambda <- c(.3,.1)
fit <- m$liq_glmnet_v480(x,yy,family="binomial",alpha=0,standardize=FALSE,
  offset=off,lambda=lambda,.engine=function(...)stop("injected solver failure"))
eta <- predict(fit,newx=x,s=lambda,type="link",newoffset=off)
bb <- coef(fit,s=lambda);manual <- sweep(x%*%bb[-1,,drop=FALSE],2,bb[1,],"+")+off
check("validated ridge fallback preserves offset",inherits(fit,"liq_ridge_path") && max(abs(eta-manual))<1e-10)
check("ridge score equations converge",max(fit$numerical_audit$max_abs_gradient)<1e-7)

# Too little guard support must preserve Cox even for an apparently perfect residual.
small <- data.table::data.table(asset=rep(c("A","B","C"),4),sid=1:12,
  shock_date=as.Date("2022-01-01")+0:11,planned_end=as.Date("2022-01-01")+30:41,
  status=rep(0:1,6),duration=rep(c(30L,3L),6),followup=30L)
base <- matrix(rep(c(.2,.4,.6,.8),each=12),12,4)
pr <- setNames(rep(list(base),14),c("Historical_raw","Regime_raw","Logit_raw","Hazard_raw","Cox_raw",
  "Historical_cal","Regime_cal","Logit_cal","Hazard_cal","Cox_cal",
  "TRAIN_Mixture_raw","TRAIN_Mixture_cal","CoxResidual_raw","CoxResidual_cal"))
pr$CoxResidual_raw <- matrix(rep(small$status,4),12,4)*.98+.01
pr$CoxResidual_cal <- pr$CoxResidual_raw
candidates <- list(pred=list(guard=pr,test=lapply(pr,function(z)z[1:5,,drop=FALSE])))
heads <- m$liq_heads(candidates,small,cfg)
check("insufficient guard support returns Cox probabilities",identical(heads$test$LIQ_Brier,candidates$pred$test$Cox_raw))
check("insufficient guard support returns Cox rankings",isTRUE(all.equal(heads$test$LIQ_Rank_Guard,candidates$pred$test$Cox_raw,check.attributes=FALSE)))
dir.create("results",showWarnings=FALSE)
write.csv(data.frame(check=checks,pass=TRUE),"results/quick_checks.csv",row.names=FALSE)
cat("\nQuick checks passed:",length(checks),"\nNo historical fits or full simulation experiment were rerun.\n")
