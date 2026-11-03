# Reporting-only repair. Original forecasts, fits, rules, point losses and
# source/checkpoint files are never overwritten. No forecasting model or
# CAL-FIT map is trained. Run from the original V480 package directory:
# source('19_REPAIR_CITL_REPORTING_V480.R')
liq_citl_stable_v480 <- function(y,p,w=rep(1,length(y)),details=FALSE) {
 stopifnot(length(y)==length(p),length(y)==length(w))
 ok<-is.finite(y)&is.finite(p)&is.finite(w)&w>0
 y<-as.numeric(y[ok]);p<-as.numeric(p[ok]);w<-as.numeric(w[ok])
 empty<-list(estimate=NA_real_,score_error=NA_real_,lower=NA_real_,upper=NA_real_)
 if(length(y)<20L||sum(w*y)<5||sum(w*(1-y))<5)return(if(details)empty else NA_real_)
 stopifnot(all(y%in%c(0,1)))
 z<-qlogis(pmin(pmax(p,1e-6),1-1e-6));rate<-sum(w*y)/sum(w)
 lower<-qlogis(rate)-max(z);upper<-qlogis(rate)-min(z)
 score<-function(a)sum(w*(plogis(z+a)-y))/sum(w)
 fit<-stats::uniroot(score,c(lower-1,upper+1),tol=1e-12,maxiter=1000L)
 error<-abs(score(fit$root));stopifnot(is.finite(fit$root),error<1e-10)
 ans<-list(estimate=fit$root,score_error=error,lower=lower,upper=upper)
 if(details)ans else ans$estimate
}

liq_repair_citl_reports_v480 <- function(
 full_dir=Sys.getenv('LIQ_V480_FULL_DIR','out_liq_rec_v4_8_0_full'),
 output_dir=Sys.getenv('LIQ_V480_CITL_OUT',paste0(full_dir,'_CITL_DIAGNOSTIC_FIX'))) {
 for(pp in c(1e-6,.05,.5,.95,1-1e-6)) {
  yy<-c(rep(1,37),rep(0,63));aa<-liq_citl_stable_v480(yy,rep(pp,100));stopifnot(abs(aa-(qlogis(.37)-qlogis(pp)))<1e-10)
 }
 stopifnot(dir.exists(full_dir));full_dir<-normalizePath(full_dir,winslash='/',mustWork=TRUE)
 if(normalizePath(output_dir,winslash='/',mustWork=FALSE)==full_dir)stop('Use a separate output directory.')
 source_file<-file.path(full_dir,'source','LIQ_REC_Fin_Major_Revision_v4_8_0.R')
 if(!file.exists(source_file)||unname(tools::md5sum(source_file))!='ed19ad4035b799915163897644a8515c')stop('The original frozen V480 source is required.')
 before_auto<-Sys.getenv('LIQ_AUTORUN',unset=NA_character_)
 on.exit(if(is.na(before_auto))Sys.unsetenv('LIQ_AUTORUN')else Sys.setenv(LIQ_AUTORUN=before_auto),add=TRUE)
 Sys.setenv(LIQ_AUTORUN='false')
 e<-new.env(parent=globalenv());sys.source(source_file,envir=e,keep.source=FALSE);e$LIQ_SOURCE_PATH<-normalizePath(source_file,winslash='/')
 package_cfg<-e$liq_config();package_cfg$install<-FALSE;e$liq_packages(package_cfg)
 for(nm in c('liq_fit_logit','liq_fit_hazard','liq_fit_cox','liq_cal_fit','liq_correction_path'))assign(nm,function(...)stop('Refitting is disabled during diagnostic repair.'),envir=e)
 status<-data.table::fread(file.path(full_dir,'tables','RUN_STATUS.csv'))
 stopifnot(nrow(status)==600L,all(status$status=='completed'))
 fit_files<-file.path(full_dir,'tasks',status$task,'fitted_rules.rds')
 if(!all(file.exists(fit_files)))stop('Local fitted_rules.rds files are required. They are in the original full-run output, not the exported results ZIP. Set LIQ_V480_FULL_DIR to the original output directory.')
 dir.create(output_dir,recursive=TRUE,showWarnings=FALSE);checks<-rows<-list();flags<-list()
 for(k in seq_len(nrow(status))) {
  id<-status$task[k];path<-file.path(full_dir,'tasks',id);z<-readRDS(fit_files[k]);cfg<-z$cfg
  point<-data.table::fread(file.path(path,'tables','performance.csv'))
  # Reapply only the already-frozen deterministic GUARD selection to stored
  # candidate predictions; never fit a base model or a calibration map.
  heads<-e$liq_heads(z$candidates,z$guard,cfg)
  if(!isTRUE(all.equal(as.data.frame(heads$choices),as.data.frame(z$choices),tolerance=0,check.attributes=FALSE)))stop('Frozen head choices changed: ',id)
  point$CITL_original<-point$CITL
  point$CITL_score_error<-point$CITL_old_score_error<-NA_real_
  point$CITL_reporting_method<-'original_not_probability'
  max_metric_error<-max_score_error<-0;fixed_extreme<-0L
  for(i in seq_len(nrow(point))) {
   model<-point$model[i];j<-match(point$horizon[i],cfg$horizons)
   if(!model%in%names(heads$test)||is.na(j))stop('Missing frozen model/horizon: ',id,' ',model)
   yy<-e$liq_truth(z$test,point$horizon[i])$y;p<-heads$test[[model]][,j]
   ok<-is.finite(yy)&is.finite(p);y<-yy[ok];p<-p[ok]
   err<-c(abs(length(y)-point$n[i]),abs(mean(p)-point$mean_output[i]),abs(mean(y)-point$observed_rate[i]),abs(e$liq_auc(y,p)-point$AUC[i]))
   if(is.finite(point$Brier[i])) {
    pp<-pmin(pmax(p,1e-6),1-1e-6)
    bs<-mean((pp-y)^2)
    rh<-pmin(pmax(heads$test$Historical_cal[ok,j],1e-6),1-1e-6)
    rr<-pmin(pmax(heads$test$Regime_cal[ok,j],1e-6),1-1e-6)
    bh<-mean((rh-y)^2);br<-mean((rr-y)^2)
    replay<-c(weight_n=length(y),Brier=bs,
     BSS_historical=if(bh>1e-12)1-bs/bh else NA_real_,
     BSS_regime=if(br>1e-12)1-bs/br else NA_real_,
     log_loss=mean(-y*log(pp)-(1-y)*log(1-pp)),cal_error=mean(pp-y))
    for(ratio in cfg$cost_ratios) {
     action<-pp>=ratio/(ratio+1)
     replay[paste0('decision_cost_r',ratio)]<-mean(ratio*action*(1-y)+(1-action)*y)
    }
    for(field in names(replay)) {
     original<-point[[field]][i];value<-replay[[field]]
     if(is.finite(original)!=is.finite(value))stop('Point metric support changed: ',id,' ',model,' ',field)
     if(is.finite(value))err<-c(err,abs(value-original))
    }
   }
   max_metric_error<-max(max_metric_error,err[is.finite(err)])
   if(!is.finite(point$Brier[i]))next
   ans<-liq_citl_stable_v480(y,p,details=TRUE);old<-point$CITL_original[i]
   zz<-qlogis(pmin(pmax(p,1e-6),1-1e-6))
   point$CITL[i]<-ans$estimate;point$CITL_score_error[i]<-ans$score_error
   if(is.finite(old))point$CITL_old_score_error[i]<-abs(mean(plogis(zz+old)-y))
   point$CITL_reporting_method[i]<-'unique offset-logistic intercept; bracketed score root; reporting only'
   if(is.finite(ans$score_error))max_score_error<-max(max_score_error,ans$score_error)
   if(is.finite(old)&&is.finite(ans$lower)&&(old<ans$lower-1e-6||old>ans$upper+1e-6))fixed_extreme<-fixed_extreme+1L
   if(is.finite(point$cal_intercept[i])&&is.finite(point$cal_slope[i])) {
    residual<-y-plogis(point$cal_intercept[i]+point$cal_slope[i]*zz)
    gradient<-max(abs(mean(residual)),abs(mean(residual*zz)))
    if(gradient>1e-6)flags[[length(flags)+1L]]<-data.table::data.table(task=id,model=model,horizon=point$horizon[i],max_abs_score=gradient)
   }
  }
  if(max_metric_error>1e-12||max_score_error>1e-10)stop('Frozen-metric or root-score mismatch: ',id)
  point$scenario<-sub('_[0-9]+$','',sub('^simulation_','',id));point$replication<-as.integer(sub('^.*_','',id))
  rows[[k]]<-point;checks[[k]]<-data.table::data.table(task=id,pass=TRUE,max_metric_error=max_metric_error,max_CITL_score_error=max_score_error,invalid_original_intercepts_repaired=fixed_extreme)
  if(k%%50L==0L)cat('CITL reporting repair:',k,'/ 600 frozen tasks replayed\n')
  rm(z,heads);gc(FALSE)
 }
 corrected<-data.table::rbindlist(rows,fill=TRUE);checked<-data.table::rbindlist(checks)
 e$liq_write_csv(corrected,file.path(output_dir,'S48001_performance_CITL_corrected.csv'))
 e$liq_write_csv(checked,file.path(output_dir,'CITL_REPAIR_CHECKS.csv'))
 flag_table<-if(length(flags))data.table::rbindlist(flags)else data.table::data.table(task=character(),model=character(),horizon=integer(),max_abs_score=numeric())
 e$liq_write_csv(flag_table,file.path(output_dir,'JOINT_CALIBRATION_SCORE_FLAGS.csv'))
 mean_table<-corrected[,list(CITL=mean(CITL,na.rm=TRUE),cal_error=mean(cal_error,na.rm=TRUE),cal_intercept=mean(cal_intercept,na.rm=TRUE),cal_slope=mean(cal_slope,na.rm=TRUE)),by=c('scenario','model','horizon')]
 e$liq_write_csv(mean_table,file.path(output_dir,'CITL_corrected_horizon_means.csv'))
 writeLines(c('Reporting-only CITL repair: fixed forecasts, fitted objects, GUARD choices, source and original result files unchanged.',
  'The 600 forecasting models and CAL-FIT maps were not retrained; TEST predictions were not recalibrated.',
  paste('All frozen point metrics reproduced; max error',format(max(checked$max_metric_error),digits=17)),
  paste('Invalid original CITL intercepts repaired',sum(checked$invalid_original_intercepts_repaired)),
  paste('Joint slope/intercept score flags',length(flags)),
  'Joint intercept/slope values are preserved, not retuned. Any score flags are reported separately.'),file.path(output_dir,'REPAIR_SCOPE.txt'))
 capture.output(sessionInfo(),file=file.path(output_dir,'sessionInfo.txt'))
 files<-list.files(output_dir,full.names=TRUE);files<-files[basename(files)!='EXPORT_MANIFEST.csv'];e$liq_write_csv(data.table::data.table(file=basename(files),bytes=file.info(files)$size,md5=unname(tools::md5sum(files))),file.path(output_dir,'EXPORT_MANIFEST.csv'))
 target<-file.path(dirname(normalizePath(output_dir,winslash='/')), 'LIQ_REC_v480_CITL_FIX_RESULTS.zip')
 if(requireNamespace('zip',quietly=TRUE))zip::zip(target,files=list.files(output_dir),root=output_dir,mode='mirror',include_directories=FALSE)
 cat('CITL reporting repair completed. Models were not retrained.\nOutput:',normalizePath(output_dir,winslash='/'),'\n')
 if(file.exists(target))cat('ZIP:',target,'\n')
 invisible(list(corrected=corrected,checks=checked,output=output_dir))
}
if(tolower(Sys.getenv('LIQ_CITL_REPAIR_AUTORUN','true'))=='true')liq_repair_citl_reports_v480()
