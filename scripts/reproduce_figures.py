"""Redraw study figures from archived numerical records, without model fitting."""
from pathlib import Path
import numpy as np,pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT=Path(__file__).resolve().parents[1];REF=ROOT/'reference';OUT=ROOT/'results/figures';OUT.mkdir(parents=True,exist_ok=True)
H=[5,10,20,30]
SC=['signal','no_regime','prevalence_shift','regime_reversal','non_PH','strong_dependence']
COL={'Cox_raw':'#28556f','LIQ_Brier':'#a3393e','LIQ_Rank_Guard':'#7a588e','Logit_raw':'#54834c','Regime_raw':'#b8873c','CoxResidual_raw':'#777777','Low':'#326e90','Normal':'#b58b30','High':'#a44148'}
NAME={'Cox_raw':'Cox','LIQ_Brier':'LIQ-P','LIQ_Rank_Guard':'LIQ-R','Logit_raw':'Horizon logit','Regime_raw':'Regime empirical','CoxResidual_raw':'Residual, raw'}
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':9,'axes.spines.top':False,'axes.spines.right':False,'axes.labelsize':9,'xtick.labelsize':8,'ytick.labelsize':8,'legend.fontsize':8,'pdf.fonttype':42,'axes.linewidth':.6})

def save(fig,name):
    fig.savefig(OUT/(name+'.pdf'),bbox_inches='tight',pad_inches=.08)
    fig.savefig(OUT/(name+'.png'),bbox_inches='tight',pad_inches=.08,dpi=300)
    plt.close(fig)

market=pd.read_csv(REF/'market_stress_composite.csv',parse_dates=['date'])
annual=pd.read_csv(REF/'annual_origins.csv')
fig,ax=plt.subplots(2,1,figsize=(6.5,4.2),gridspec_kw={'height_ratios':[2,1]})
ax[0].plot(market.date,market.market_stress,lw=.7,color='#31576d');ax[0].axhline(0,color='.6',lw=.5)
for lo,hi,c in [('2020-01-01','2021-12-31','#e3b44d'),('2022-01-01','2023-12-31','#4e9e8a'),('2024-02-02','2025-12-31','#b95660')]:
    ax[0].axvspan(pd.Timestamp(lo),pd.Timestamp(hi),color=c,alpha=.1,zorder=0)
ax[0].set_ylabel('Market stress composite');ax[0].text(.01,.94,'(a)',transform=ax[0].transAxes,va='top')
ax[1].bar(annual.year,annual.eligible_origins,color='#8198a6',width=.7)
ax[1].set(xlabel='Calendar year',ylabel='Eligible origins');ax[1].text(.01,.94,'(b)',transform=ax[1].transAxes,va='top')
fig.tight_layout();save(fig,'Fig1_stress')

bands=pd.read_csv(REF/'survival_bands.csv');events=pd.read_csv(REF/'test_events.csv')
fig,ax=plt.subplots(figsize=(6.5,4.0));risk=[]
for state in ['Low','Normal','High']:
    z=bands[bands.regime==state].sort_values('day');sub=events[events.regime==state]
    ax.step(z.day,z.survival,where='post',lw=1.3,color=COL[state],label=f'{state} (n={len(sub)})')
    ax.fill_between(z.day,z.lower,z.upper,color=COL[state],alpha=.13,step='post',lw=0)
    risk.append([str(sum(sub.duration>=h)) for h in [0,5,10,20,30]])
ax.set(xlim=(0,30),ylim=(0,1.02),xlabel='Sessions after shock',ylabel='Non-recovery probability');ax.legend(frameon=False);ax.grid(axis='y',color='.9',lw=.5)
tab=ax.table(cellText=risk,rowLabels=['Low','Normal','High'],colLabels=['0','5','10','20','30'],cellLoc='center',rowLoc='right',bbox=[.10,-.49,.87,.28]);tab.auto_set_font_size(False);tab.set_fontsize(8)
for cell in tab.get_celld().values():cell.set_linewidth(0)
ax.text(0,-.25,'At risk',transform=ax.transAxes,fontsize=8);fig.subplots_adjust(bottom=.34);save(fig,'Fig2_survival')

perf=pd.read_csv(REF/'historical_horizons.csv')
fig,axs=plt.subplots(1,2,figsize=(6.5,2.85))
for model in ['LIQ_Brier','Cox_raw','Logit_raw','Regime_raw']:
    z=perf[perf.model==model].sort_values('horizon')
    for ax,metric in zip(axs,['Brier','AUC']):ax.plot(z.horizon,z[metric],marker='o',ms=3,color=COL[model],label=NAME[model])
z=perf[perf.model=='LIQ_Rank_Guard'].sort_values('horizon');axs[1].plot(z.horizon,z.AUC,ls='--',marker='s',ms=3,color=COL['LIQ_Rank_Guard'],label='LIQ-R')
for i,ax in enumerate(axs):
    ax.set(xlabel='Horizon (sessions)',xticks=H);ax.grid(axis='y',color='.9',lw=.5);ax.text(.02,.97,'('+chr(97+i)+')',transform=ax.transAxes,va='top')
axs[0].set_ylabel('Brier loss');axs[1].set_ylabel('Recovery AUC');axs[1].axhline(.5,color='.6',ls=':',lw=.7)
handles,labels=axs[1].get_legend_handles_labels();fig.legend(handles,labels,loc='lower center',ncol=3,frameon=False);fig.tight_layout(rect=[0,.18,1,1]);save(fig,'Fig3_horizons')

rel=pd.read_csv(REF/'reliability.csv');fig,axs=plt.subplots(2,2,figsize=(6.5,5.0))
for ax,h,letter in zip(axs.flat,H,'abcd'):
    ax.plot([0,1],[0,1],ls=':',color='.5',lw=.7)
    for model,marker in [('Cox_raw','o'),('LIQ_Brier','s')]:
        z=rel[(rel.model==model)&(rel.horizon==h)]
        ax.errorbar(z.mean_p,z.rate,yerr=[z.rate-z.lower,z.upper-z.rate],color=COL[model],marker=marker,ms=3,lw=.8,capsize=2,label=NAME[model])
    ax.set(xlim=(0,1),ylim=(0,1),xlabel='Mean forecast probability',ylabel='Observed recovery rate');ax.text(.03,.93,f'({letter}) {h} sessions',transform=ax.transAxes)
handles,labels=axs[0,0].get_legend_handles_labels();fig.legend(handles,labels,loc='lower center',ncol=2,frameon=False);fig.tight_layout(rect=[0,.05,1,1]);save(fig,'Fig4_reliability')

roll=pd.read_csv(REF/'rolling_windows.csv');status=pd.read_csv(REF/'rolling_attempts.csv')
ids=status[status.kind=='regular'].task.tolist();years=[int(x[-8:-4]) for x in ids]
fig,axs=plt.subplots(2,1,figsize=(6.5,4.5))
for model,ls,marker in [('Cox_raw','-','o'),('LIQ_Brier','--','s'),('CoxResidual_raw',':','^')]:
    z=roll[roll.model==model].set_index('design').reindex(ids);axs[0].plot(years,z.Brier,color=COL[model],label=NAME[model],ls=ls,marker=marker,ms=3)
for model,ls in [('Cox_raw','-'),('LIQ_Rank_Guard','--')]:
    z=roll[roll.model==model].set_index('design').reindex(ids);axs[1].plot(years,z.AUC,color=COL[model],label=NAME[model],ls=ls,marker='o',ms=3)
for ax in axs:
    ax.axvspan(2017.75,2018.25,color='.9');ax.set_xticks(years);ax.grid(axis='y',color='.9',lw=.5);ax.legend(frameon=False,ncol=3,loc='upper center',bbox_to_anchor=(.5,1.26))
axs[0].set_ylabel('Mean Brier loss');axs[1].set(ylabel='Mean recovery AUC',xlabel='Regular window end year');fig.tight_layout();save(fig,'Fig5_rolling')

sim=pd.read_csv(REF/'simulation_brier.csv').set_index('scenario').reindex(SC)
rank=pd.read_csv(REF/'simulation_auc.csv').set_index('scenario').reindex(SC)
fig,axs=plt.subplots(2,1,figsize=(6.5,4.7));xs=np.arange(6)
labels=['Signal','No regime','Prevalence\nshift','Regime\nreversal','Non-proportional\nhazards','Strong\ndependence']
for model,marker in [('Cox_raw','o'),('LIQ_Brier','s'),('Logit_raw','^')]:axs[0].plot(xs,sim[model],marker=marker,ms=4,color=COL[model],label=NAME[model])
for model,marker in [('Cox_raw','o'),('LIQ_Rank_Guard','s'),('Logit_raw','^')]:axs[1].plot(xs,rank[model],marker=marker,ms=4,color=COL[model],label=NAME[model])
for ax in axs:ax.set_xticks(xs,labels);ax.grid(axis='y',color='.9',lw=.5);ax.legend(frameon=False,ncol=3,loc='upper center',bbox_to_anchor=(.5,1.25))
axs[0].set_ylabel('Mean Brier loss');axs[1].set_ylabel('Mean recovery AUC');axs[1].axhline(.5,color='.6',ls=':',lw=.7);fig.tight_layout();save(fig,'Fig6_simulation')

cov=pd.read_csv(REF/'simulation_coverage.csv');cov=cov[cov.model=='LIQ_Brier'].set_index('scenario').reindex(SC)
fig,axs=plt.subplots(1,2,figsize=(6.5,3.2));yy=np.arange(6)
axs[0].barh(yy,cov.all_supported,color='#c4cfd6',height=.65,label='All supported')
axs[0].barh(yy,cov.evaluable_families,color='#356b82',height=.40,label='Nonidentity and supported')
axs[0].set_yticks(yy,['Signal','No regime','Prevalence shift','Regime reversal','Non-proportional hazards','Strong dependence']);axs[0].invert_yaxis();axs[0].set(xlim=(0,105),xlabel='Families out of 100');axs[0].legend(frameon=False,fontsize=6,loc='lower right')
rate=cov.family_point_coverage.to_numpy();lo=cov.MC_Wilson_lower.to_numpy();hi=cov.MC_Wilson_upper.to_numpy()
axs[1].errorbar(rate,yy,xerr=[rate-lo,hi-rate],fmt='o',color='#a3393e',ms=3,capsize=2,lw=.8)
axs[1].set_yticks(yy,[]);axs[1].invert_yaxis();axs[1].set(xlim=(.5,1.02),xlabel='Conditional point coverage');axs[1].axvline(.95,ls=':',color='.6',lw=.7)
fig.tight_layout();save(fig,'FigS1_coverage')
print('Seven figures redrawn from archived records:',OUT)
