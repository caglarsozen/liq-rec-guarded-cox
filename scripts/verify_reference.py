"""Check archived numerical evidence without retraining or third-party packages."""
from pathlib import Path
from collections import defaultdict
import csv,gzip,hashlib,json,math,statistics

ROOT=Path(__file__).resolve().parents[1]

def rows(name):
    path=ROOT/'reference'/name
    opener=gzip.open if path.suffix=='.gz' else open
    with opener(path,'rt',encoding='utf-8',newline='') as f:return list(csv.DictReader(f))

def auc(items):
    counts=defaultdict(lambda:[0,0])
    for r in items:counts[float(r['output'])][int(float(r['y']))]+=1
    below=score=positive=negative=0.0
    for key in sorted(counts):
        n0,n1=counts[key];score+=n1*(below+.5*n0);below+=n0;positive+=n1;negative+=n0
    return score/(positive*negative)

def main():
    checks=[]
    def check(name,condition):
        if not condition:raise AssertionError(name)
        checks.append(name)
    spec=json.loads((ROOT/'metadata/frozen_specification.json').read_text())
    check('frozen source SHA256',hashlib.sha256((ROOT/spec['source_file']).read_bytes()).hexdigest()==spec['source_sha256'])
    forecasts=rows('core_forecasts.csv.gz');table={(r['model'],int(r['horizon'])):r for r in rows('historical_horizons.csv')}
    groups=defaultdict(list)
    for r in forecasts:groups[(r['model'],int(r['horizon']))].append(r)
    check('twenty model/horizon groups',len(groups)==20)
    loss={};probabilities={}
    for key,g in groups.items():
        check(str(key)+' complete cohort',len(g)==1284 and len({r['event_id'] for r in g})==1284 and all(r['known'].lower()=='true' for r in g))
        check(str(key)+' AUC',abs(auc(g)-float(table[key]['AUC']))<1e-12)
        if key[1]==30:check(str(key)+' endpoint negatives',sum(float(r['y'])==0 for r in g)==95)
        if key[0]!='LIQ_Rank_Guard':
            bs=statistics.fmean((float(r['output'])-float(r['y']))**2 for r in g)
            check(str(key)+' Brier',abs(bs-float(table[key]['Brier']))<1e-12);loss[key]=bs
            for r in g:probabilities[(key[0],r['event_id'],key[1])]=float(r['output'])
    check('primary LIQ-P equals raw residual',all(probabilities[('LIQ_Brier',r['event_id'],int(r['horizon']))]==float(r['output']) for r in forecasts if r['model']=='CoxResidual_raw'))
    for model in ['Cox_raw','CoxResidual_raw','LIQ_Brier','Logit_raw']:
        ids={r['event_id'] for r in forecasts if r['model']==model}
        check(model+' horizon coherence',all(all(probabilities[(model,i,h)]<=probabilities[(model,i,k)]+1e-14 for h,k in [(5,10),(10,20),(20,30)]) for i in ids))
    b0=statistics.fmean(loss[('Cox_raw',h)] for h in [5,10,20,30]);b1=statistics.fmean(loss[('LIQ_Brier',h)] for h in [5,10,20,30])
    check('historical descriptive Brier improvement',abs(b0-.166729)<1e-6 and abs(b1-.164841)<1e-6 and 1.12<100*(1-b1/b0)<1.14)
    rolling=rows('rolling_summary.csv');rby={r['model']:r for r in rolling}
    check('rolling probability equals Cox mean',float(rby['LIQ_Brier']['Brier'])==float(rby['Cox_raw']['Brier']))
    attempts=rows('rolling_attempts.csv');regular=[r for r in attempts if r['kind']=='regular']
    check('eight supported of nine regular attempts',len(regular)==9 and sum(r['status']=='completed' for r in regular)==8)
    sim={r['scenario']:r for r in rows('simulation_brier.csv')};check('six simulation scenarios',len(sim)==6)
    a=float(sim['non_PH']['Cox_raw']);b=float(sim['non_PH']['LIQ_Brier'])
    check('non-PH Brier reduction',5.87<100*(1-b/a)<5.89)
    coverage=rows('simulation_coverage.csv');check('100 independent replications per scenario',all(int(r['replications'])==100 for r in coverage))
    check('nonidentity non-PH probability coverage count',any(r['scenario']=='non_PH' and r['model']=='LIQ_Brier' and int(r['covered_families'])==96 for r in coverage))
    result={'checks_passed':len(checks),'historical_events':1284,'known_30_session_negatives':95,'core_forecast_rows':len(forecasts),'historical_Brier_Cox':b0,'historical_Brier_LIQ_P':b1,'scope':'Archived numerical consistency; no model fitting or new Monte Carlo experiment.'}
    print(json.dumps(result,indent=2))
    return result

if __name__=='__main__':main()
