"""Recompute fixed-fit diagnostics after an authorized historical run; no refitting."""
from pathlib import Path
import numpy as np, pandas as pd, json, os, hashlib
from scipy.special import expit,logit
from scipy.optimize import brentq
from scipy.stats import rankdata
R=Path(__file__).resolve().parents[1]
O=Path(os.environ.get('LIQ_DIAGNOSTICS_DIR',str(R/'results/diagnostics')));O.mkdir(parents=True,exist_ok=True)
T=O
C=O/'cache';C.mkdir(exist_ok=True)
M=R
P=R/'results/market/tasks/primary/tables'
# Verify private inputs and bind disposable caches to the exact run outputs.
expected=json.loads((R/'metadata/expected_snapshot.json').read_text())
for item in expected:
 path=R/item['path']
 if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest()!=item['sha256']:
  raise RuntimeError('Install the exact authorized snapshot before diagnostics: '+item['path'])
required=['A04_LSI_training_parameters.csv','T01_event_dictionary.csv','frozen_test_predictions.csv','T03_horizon_performance.csv']
fingerprint={n:hashlib.sha256((P/n).read_bytes()).hexdigest() for n in required}
fingerprint['source']=hashlib.sha256((R/'LIQ_REC_Fin_Major_Revision_v4_8_0.R').read_bytes()).hexdigest()
cache_meta=C/'run_identity.json'
if cache_meta.exists() and json.loads(cache_meta.read_text())!=fingerprint:
 raise RuntimeError('Cached diagnostics refer to another run. Set LIQ_DIAGNOSTICS_DIR to a fresh directory.')
cache_meta.write_text(json.dumps(fingerprint,indent=2))

H=[5,10,20,30]
def save(x,n):x.to_csv(T/(n+'.csv'),index=False,float_format='%.17g')
if (C/'daily.pkl').exists(): d=pd.read_pickle(C/'daily.pkl')
else:
 raw=pd.read_csv(M/'data/frozen_ohlcv.csv',parse_dates=['date'])
 for c in ['open','high','low','close','adjusted','volume']:raw[c]=pd.to_numeric(raw[c],errors='coerce')
 assets=sorted(pd.read_csv(M/'universe/universe_100.csv').asset)
 cal=pd.DatetimeIndex(sorted(raw.loc[raw.asset=='SPY','date'].unique()))
 d=raw.set_index(['asset','date']).reindex(pd.MultiIndex.from_product([assets,cal],names=['asset','date'])).reset_index()
 d['observed']=np.isfinite(d.close)&(d.close>0)
 d['valid_price']=d.observed&(d.adjusted>0)&np.isfinite(d.adjusted)&(d.low>0)&(d.high>=d.low)&(d.high>=d.close)&(d.low<=d.close)
 d['valid_volume']=(d.volume>0)&np.isfinite(d.volume)
 with np.errstate(divide='ignore',invalid='ignore'):
  prev=d.groupby('asset').adjusted.shift()
  d['ret']=np.where(d.valid_price&(prev>0),np.log(d.adjusted)-np.log(prev),np.nan)
  d['abs_ret']=abs(d.ret);d['range_pct']=np.where(d.valid_price,(d.high-d.low)/d.close,np.nan)
  d['log_volume']=np.where(d.valid_volume,np.log(d.volume),np.nan)
  d['log_dvol']=np.where(d.valid_volume&d.observed,np.log(d.close)+np.log(d.volume),np.nan)
  d['volume_shock']=d.log_volume-d.groupby('asset').log_volume.transform(lambda x:x.rolling(60).median().shift())
  d['pressure']=d.range_pct*np.maximum(-d.volume_shock,0)
  d['amihud']=d.abs_ret/(d.close*d.volume)*1e6;d.loc[~(d.valid_volume&d.observed),'amihud']=np.nan
  ah=d.high*d.adjusted/d.close;al=d.low*d.adjusted/d.close
  pa=ah.groupby(d.asset).shift();pl=al.groupby(d.asset).shift()
  be=np.log(ah/al)**2+np.log(pa/pl)**2;ga=np.log(np.maximum(ah,pa)/np.minimum(al,pl))**2
  alpha=(np.sqrt(2*be)-np.sqrt(be))/(3-2*np.sqrt(2))-np.sqrt(ga/(3-2*np.sqrt(2)))
  d['cs_spread']=np.maximum(0,2*np.tanh(alpha/2))
  d.loc[~(d.valid_price&d.groupby('asset').valid_price.shift(fill_value=False)),'cs_spread']=np.nan
 params=pd.read_csv(P/'A04_LSI_training_parameters.csv')
 comps=['abs_ret','range_pct','log_dvol','volume_shock','pressure']
 for j,c in enumerate(comps,1):
  p=params[params.component==c].set_index('asset')
  d['z'+str(j)]=d.asset.map(p.sign)*(d[c].clip(lower=d.asset.map(p.lower),upper=d.asset.map(p.upper))-d.asset.map(p['mean']))/d.asset.map(p.sd)
 d['lsi']=d[['z1','z2','z3','z4','z5']].mean(axis=1,skipna=False)
 d['role']='OUTSIDE'
 for role,lo,hi in [('TRAIN','2011-01-01','2019-12-31'),('CAL_FIT','2020-01-01','2021-12-31'),('GUARD','2022-01-01','2023-12-31'),('TEST','2024-02-02','2025-12-31')]:d.loc[d.date.between(lo,hi),'role']=role
 d.to_pickle(C/'daily.pkl')
ev=pd.read_csv(P/'T01_event_dictionary.csv',parse_dates=['shock_date'])
chk=ev[['asset','shock_date','lsi']].merge(d[['asset','date','lsi']],left_on=['asset','shock_date'],right_on=['asset','date'])
err=float(np.max(abs(chk.lsi_x-chk.lsi_y)));assert err<1e-11
eligible=ev[ev.analysis_eligible];test=eligible[eligible.role=='TEST'].sort_values(['shock_date','asset']).copy();test.to_pickle(C/'test.pkl')
assert len(test)==1284 and sum(test.y30==0)==95
inv=[]
for a,g in d.groupby('asset'):
 z=eligible[eligible.asset==a]
 inv.append(dict(asset=a,first_observed=g.loc[g.observed,'date'].min().strftime('%Y-%m-%d'),last_observed=g.loc[g.observed,'date'].max().strftime('%Y-%m-%d'),first_LSI=g.loc[np.isfinite(g.lsi),'date'].min().strftime('%Y-%m-%d'),observed=int(g.observed.sum()),missing=int((~g.observed).sum()),invalid_price=int((g.observed&~g.valid_price).sum()),invalid_volume=int((g.observed&~g.valid_volume).sum()),TRAIN=sum(z.role=='TRAIN'),CAL_FIT=sum(z.role=='CAL_FIT'),GUARD=sum(z.role=='GUARD'),TEST=sum(z.role=='TEST')))
save(pd.DataFrame(inv),'asset_inventory')
des=[]
for role,g in d.groupby('role'):
 for c in ['ret','abs_ret','range_pct','log_dvol','volume_shock','pressure','lsi']:
  x=g[c].dropna();des.append(dict(role=role,variable=c,n=len(x),mean=x.mean(),sd=x.std(),p01=x.quantile(.01),p25=x.quantile(.25),median=x.median(),p75=x.quantile(.75),p99=x.quantile(.99)))
save(pd.DataFrame(des),'daily_statistics')
if not (T/'proxy_correlations.csv').exists():
 rows=[]
 for (a,role),g in d[d.role.isin(['TRAIN','TEST'])].groupby(['asset','role']):
  zz=g[['z1','z2','z3','z4','z5']].to_numpy()
  for k in range(7):
   xx=g.lsi.to_numpy() if k==0 else np.mean(np.delete(zz,k-1,axis=1),axis=1) if k<6 else np.mean(zz[:,[2,3]],axis=1)
   for c in ['amihud','cs_spread']:
    yy=g[c].to_numpy();good=np.isfinite(xx)&np.isfinite(yy)
    v=np.corrcoef(rankdata(xx[good]),rankdata(yy[good]))[0,1] if good.sum()>20 else np.nan
    rows.append(dict(asset=a,role=role,index='main' if k==0 else 'omit_'+str(k) if k<6 else 'volume_only',proxy=c,n=int(good.sum()),spearman=v))
 save(pd.DataFrame(rows),'proxy_correlations')
pc=pd.read_csv(T/'proxy_correlations.csv')
ps=pc.groupby(['role','index','proxy']).spearman.agg(median='median',q25=lambda x:x.quantile(.25),q75=lambda x:x.quantile(.75)).reset_index();save(ps,'proxy_summary')
pred=pd.read_csv(P/'frozen_test_predictions.csv')
mods=['Cox_raw','LIQ_Brier','Logit_raw','LIQ_Rank_Guard']
wide={m:pred[pred.model==m].pivot(index='event_id',columns='horizon',values='output').reindex(test.event_id)[H].to_numpy() for m in mods}
y=test[['y'+str(h) for h in H]].to_numpy()
def auc(y,p,w):
 ix=np.argsort(p,kind='stable');yy=y[ix];pp=p[ix];ww=w[ix];_,ix=np.unique(pp,return_index=True)
 aa=np.add.reduceat(ww*yy,ix);bb=np.add.reduceat(ww*(1-yy),ix)
 return np.sum(aa*(np.cumsum(bb)-bb+.5*bb))/(aa.sum()*bb.sum()) if aa.sum()>0 and bb.sum()>0 else np.nan
common=[a for a,g in d[d.role=='TRAIN'].groupby('asset') if (g.valid_price&g.valid_volume&np.isfinite(g.lsi)).all()]
non=[]
for a,g in test.sort_values(['asset','sid']).groupby('asset'):
 last=-np.inf
 for _,z in g.iterrows():
  if z.sid>last+30:non.append(z.event_id);last=z.sid
subsets={'Full':np.ones(len(test),bool),'Non-overlap origins':test.event_id.isin(non).to_numpy(),'Complete TRAIN history':test.asset.isin(common).to_numpy()}
rows=[]
for name,mask in subsets.items():
 for m in mods:
  for j,h in enumerate(H):
   yy=y[mask,j];pp=wide[m][mask,j];rows.append(dict(subset=name,model=m,horizon=h,n=int(mask.sum()),assets=test.loc[mask,'asset'].nunique(),Brier=np.mean((yy-pp)**2) if m!='LIQ_Rank_Guard' else np.nan,AUC=auc(yy,pp,np.ones(len(yy)))))
save(pd.DataFrame(rows),'fixed_rule_subsets')
save(eligible.groupby(['role','regime']).agg(n=('event_id','size'),rate5=('y5','mean'),rate10=('y10','mean'),rate20=('y20','mean'),rate30=('y30','mean')).reset_index(),'regime_summary')
perf=pd.read_csv(P/'T03_horizon_performance.csv')
bh=perf[perf.model=='Historical_raw'].set_index('horizon').Brier;br=perf[perf.model=='Regime_raw'].set_index('horizon').Brier
perf['skill_hist_train']=1-perf.Brier/perf.horizon.map(bh);perf['skill_reg_train']=1-perf.Brier/perf.horizon.map(br);save(perf,'primary_performance')
if (C/'weights.npy').exists():W=np.load(C/'weights.npy')
else:
 cal=pd.DatetimeIndex(sorted(d.date.unique()));cal=cal[(cal>=test.shock_date.min())&(cal<=test.shock_date.max())];di=cal.get_indexer(test.shock_date)
 aa,ai=np.unique(test.asset,return_inverse=True);rng=np.random.default_rng(20261102);W=np.empty((1999,len(test)))
 for b in range(1999):
  starts=rng.integers(0,len(cal),int(np.ceil(len(cal)/45)));idx=((starts[:,None]+np.arange(45))%len(cal)).ravel()[:len(cal)]
  W[b]=np.bincount(idx,minlength=len(cal))[di]*np.bincount(rng.integers(0,len(aa),len(aa)),minlength=len(aa))[ai]
 np.save(C/'weights.npy',W)
def calfit(y,p,w):
 use=w>0;y=y[use];z=logit(np.clip(p[use],1e-6,1-1e-6));w=w[use]
 if sum(w*y)<5 or sum(w*(1-y))<5:return [np.nan]*3
 c=brentq(lambda a:np.dot(w,expit(z+a)-y),-45,45,xtol=1e-12)
 X=np.column_stack([np.ones(len(z)),z]);b=np.array([0.,1.])
 for _ in range(40):
  mu=expit(X@b);score=X.T@(w*(y-mu));hes=X.T@((w*mu*(1-mu))[:,None]*X)
  try:step=np.linalg.solve(hes,score)
  except np.linalg.LinAlgError:return [c,np.nan,np.nan]
  if not np.isfinite(step).all() or max(abs(step))>50:return [c,np.nan,np.nan]
  b+=step
  if max(abs(step))<1e-9:break
 return [c,*b] if max(abs(b))<100 and max(abs(score))<1e-5 else [c,np.nan,np.nan]
if not (T/'uncertainty.csv').exists():
 rel=[];unc=[]
 for m in mods:
  for j,h in enumerate(H):
   yy=y[:,j];pp=wide[m][:,j];bt={'AUC':np.array([auc(yy,pp,w) for w in W])}
   if m!='LIQ_Rank_Guard':
    q=np.array([calfit(yy,pp,w) for w in W]);bt.update(Brier=(W@((pp-yy)**2))/W.sum(axis=1),CITL=q[:,0],cal_intercept=q[:,1],cal_slope=q[:,2])
   point=perf[(perf.model==m)&(perf.horizon==h)].iloc[0]
   for metric,x in bt.items():
    fin=x[np.isfinite(x)];lo,hi=np.quantile(fin,[.025,.975]);unc.append(dict(model=m,horizon=h,metric=metric,estimate=point[metric],lower=lo,upper=hi,valid=len(fin),draws=len(W)))
   if m in ['Cox_raw','LIQ_Brier']:
    bins=np.unique(np.quantile(pp,np.linspace(0,1,7)));bi=np.clip(np.searchsorted(bins,pp,side='right')-1,0,len(bins)-2)
    for k in np.unique(bi):
     mask=bi==k;sw=W[:,mask].sum(axis=1);good=sw>0;r=(W[:,mask]@yy[mask])[good]/sw[good];lo,hi=np.quantile(r,[.025,.975]);rel.append(dict(model=m,horizon=h,bin=k+1,n=int(mask.sum()),mean_p=pp[mask].mean(),rate=yy[mask].mean(),lower=lo,upper=hi))
   print('diagnostic',m,h,flush=True)
 save(pd.DataFrame(unc),'uncertainty');save(pd.DataFrame(rel),'reliability')
checks=[dict(check='daily_LSI_reconstruction',n=len(chk),max_error=err,passed=err<1e-11),dict(check='h30_negatives_retained',n=int(sum(test.y30==0)),max_error=0,passed=True)]
for m in ['Cox_raw','LIQ_Brier','Logit_raw']:
 for j,h in enumerate(H):
  q=np.array(calfit(y[:,j],wide[m][:,j],np.ones(len(y))));p=perf[(perf.model==m)&(perf.horizon==h)].iloc[0];er=max(abs(q-p[['CITL','cal_intercept','cal_slope']].to_numpy(float)));checks.append(dict(check=m+' calibration '+str(h),n=len(y),max_error=er,passed=er<1e-6))
save(pd.DataFrame(checks),'new_calculation_checks')
assert pd.DataFrame(checks).passed.all()
print('LSI',err,'complete_history',len(common),'nonoverlap',len(non),flush=True)
print(ps[ps['index']=='main'].to_string(index=False),flush=True)
