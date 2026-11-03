# Scientific specification and information flow

## Observation and endpoint

Forecasts are issued after finalized shock-session OHLCV and adjusted close are available, for actions beginning next session. The asset stress index averages five signed training-standardized terms: absolute adjusted log return, high--low range divided by close, negative log dollar volume, negative volume shock relative to its preceding 60-session median, and range times the positive volume dry-up. Training winsorization uses quantiles 0.0025 and 0.9975. All five terms must be present.

Training asset-index quantiles 0.90 and 0.60 define shock and recovery thresholds. Accepted origins are at least six sessions apart. Recovery is dated at the end of the first completed three-session run below the recovery threshold, starting after the origin. Full 30-session follow-up and a planned endpoint inside the chronological role are required independently of recovery status. A known non-recovery at 30 sessions remains a negative binary target.

## Chronological roles

| Role | Designated period | Eligible historical events |
|---|---|---:|
| Estimation | 2011--2019 | 10,236 |
| Calibration | 2020--2021 | 2,683 |
| Guard validation | 2022--2023 | 2,608 |
| Test | 2 February 2024--2025 | 1,284 |

2010 supplies initial history. The first eligible test origin is 6 February 2024. Event monitoring is purged at role boundaries. Every historical inner fold reconstructs preprocessing, event thresholds and regime cutoffs from its own daily training prefix. Later labels do not replace unsupported training folds.

## Correction and selection

The five baseline families are historical and regime empirical probabilities, Cox proportional hazards, elastic-net horizon logistic regression and ridge discrete hazards. The 25 predictor timestamps are listed in `metadata/feature_specification.csv`. The regime variable leaves out the shocked asset; the full market average remains another disclosed predictor.

Six forward training fractions (0.35, 0.45, 0.55, 0.65, 0.75, 0.85) produce mature Cox predictions for offset residual learning. The residual basis has ten standardized coordinates plus three squares and two market interactions. Its shared penalty grid is {0.3, 0.1, 0.03, 0.01, 0.003}; shrinkage is selected from {0, 0.25, 0.5, 0.75, 1}. Paired one-standard-error admissibility prefers smaller shrinkage and then stronger regularization. Equal-weight isotonic horizon projection enforces coherent cumulative probabilities.

An independent calibration block estimates score-bin isotonic maps. The guard block is split at its median distinct origin date. Proposal monitoring must close before the first confirmation origin. Both halves require 40 events and the fixed class/date/asset floors. LIQ-P confirms a raw or calibrated correction only when its mean four-horizon Brier difference against raw Cox plus one 45-session block standard error is negative. LIQ-R confirms a raw score only when its AUC gain exceeds 0.005 plus one block standard error. Otherwise each output retains Cox. These are empirical selection heuristics, not finite-sample safety guarantees.

## Simulation

Each of six scenarios uses 100 independently seeded replications, 3,600 sessions and six assets. Market stress is a unit-variance Gaussian autoregression with coefficient 0.90. The confirmation hazard is logistic with baseline 0.045, event and market effects, and a fixed-within-replication asset effect with standard deviation 0.25. Hazards are zero before session three. Shared calendar-normal innovations induce dependence across assets and overlapping origins. Scenario changes cover absent regime signal, prevalence shift, regime reversal, non-proportional event effects and stronger shared dependence.

The simulation assigns origin covariates directly rather than reconstructing historical daily variables. Full fitting, tuning, calibration and two-stage selection repeat within each replication. Eight independent batches of 2,000 future-origin clusters evaluate fixed-fit oracle targets. Identical and unsupported interval families remain separately classified. Exact formulas, random-number ordering and seed offsets are preserved in the frozen R source.

## Limits

The daily index is a proxy, not a direct spread/depth or execution-cost observation. Historical test inspection, mixed vintages and retrospective membership limit prospective interpretation. Calendar-group intervals condition on fitted rules and the selected panel and assume sufficiently stable influence behaviour. The current evidence does not include full re-estimation across all 81 event designs, a delisted-stock universe or externally estimated trading costs.
