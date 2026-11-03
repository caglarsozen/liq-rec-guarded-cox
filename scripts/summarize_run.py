"""Add explicitly named raw-training-reference Brier skills to an R score CSV."""
from pathlib import Path
import argparse,csv,math

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('table',type=Path)
    parser.add_argument('--output',type=Path,default=Path('results/reports/horizon_scores_raw_reference_skill.csv'))
    args=parser.parse_args()
    with args.table.open(newline='',encoding='utf-8-sig') as f:
        reader=csv.DictReader(f);fields=reader.fieldnames;data=list(reader)
    keys=[k for k in ['scenario','replication','design','horizon'] if k in fields]
    if 'horizon' not in keys:raise ValueError('A model/horizon score table is required.')
    def key(row):return tuple(row[k] for k in keys)
    def number(value):
        try:return float(value)
        except (ValueError,TypeError):return math.nan
    historical={key(r):number(r['Brier']) for r in data if r['model']=='Historical_raw'}
    regime={key(r):number(r['Brier']) for r in data if r['model']=='Regime_raw'}
    extra=['BSS_historical_raw_training','BSS_regime_raw_training']
    for row in data:
        loss=number(row['Brier'])
        for name,reference in zip(extra,[historical,regime]):
            denominator=reference.get(key(row),math.nan)
            row[name]=1-loss/denominator if math.isfinite(loss) and math.isfinite(denominator) and denominator>0 else ''
    args.output.parent.mkdir(parents=True,exist_ok=True)
    with args.output.open('w',newline='',encoding='utf-8') as f:
        writer=csv.DictWriter(f,fieldnames=[x for x in fields if x not in extra]+extra)
        writer.writeheader();writer.writerows(data)
    print(args.output)

if __name__=='__main__':main()
