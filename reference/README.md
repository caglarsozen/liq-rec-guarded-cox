# Numerical reference records

These are study-derived outputs from the frozen historical fits and the completed 600-replication experiment described in the manuscript. They are supplied for numerical checks and figure reproduction. The reference records are not new estimation results from the public packaging step.

- `core_forecasts.csv.gz`: 25,680 historical forecast rows for raw Cox, raw residual, LIQ-P, LIQ-R and horizon logit; 1,284 events at each horizon.
- `test_events.csv`: event identifiers, monitoring outcomes and regimes, with no raw price/volume columns.
- `historical_horizons.csv`: evaluated model/horizon scores, including explicitly named raw-reference skill columns from manuscript preparation.
- `market_stress_composite.csv`: daily cross-asset composite on the fixed 2011--2019 scale; `annual_origins.csv` counts eligible event origins.
- `survival_bands.csv` and `reliability.csv`: point estimates and exploratory pointwise intervals from 1,999 crossed 45-session calendar-block/asset resamples, conditional on fixed fits and diagnostic bins.
- `rolling_windows.csv`, `rolling_attempts.csv`, `rolling_summary.csv`: every regular attempt, retaining unsupported 2018. Shared histories prevent interpretation as independent replications.
- `simulation_brier.csv`, `simulation_auc.csv`: equally weighted four-horizon means, first within each replication and then across 100 independent replications per scenario.
- `nonPH_paired_contrasts.csv` and `nonPH_decision_costs.csv`: paired replication-average contrasts with separate 54-comparison Monte Carlo families for scores and decisions.
- `simulation_coverage.csv`: interval support, identity and simultaneous oracle-coverage classifications. Unsupported or entirely identity families are not stochastic successes.

The historical cohort contains 1,189 recoveries and 95 known non-recoveries by 30 sessions. The same complete-window cohort is used at every horizon. Ranking scores receive no Brier or calibration interpretation.

The market composite was independently reconstructed from the authorized private input and archived training parameters. Its event-origin values agreed with 18,904 stored origins to within approximately 1.1e-13. The public file contains the resulting composite rather than provider OHLCV records.

The full simulation's reporting-only CITL correction was previously completed on all 600 local tasks. The public loader uses the same stable score-root definition. Raw oracle score draws and all fitted simulation objects are not part of these reference files; the archived coverage summaries do not allow every oracle AUC target to be independently reconstructed from raw draws.
