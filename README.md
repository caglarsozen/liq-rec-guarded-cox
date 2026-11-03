# LIQ-REC: guarded Cox recovery forecasts

[![Verification](https://github.com/caglarsozen/liq-rec-guarded-cox/actions/workflows/verify.yml/badge.svg)](https://github.com/caglarsozen/liq-rec-guarded-cox/actions/workflows/verify.yml)

Replication software for **Forecasting Liquidity-Stress Recovery with a Guarded Cox Correction** by **Çağlar Sözen and Mervenur Sözen**.

The model estimates recovery of a daily liquidity-stress proxy at 5, 10, 20 and 30 trading sessions. A ridge-regularized offset logistic correction learns from forward Cox predictions. Separate chronological samples calibrate, propose and confirm deployment. The probability rule (LIQ-P) retains Cox when confirmation is insufficient. The ranking rule (LIQ-R) selects scores separately and has no probability-calibration interpretation.

## Quick start

Download this repository or clone it, then work from its root directory. The original experiments used R 4.5.0; their recorded environment is in `metadata/original_R_sessionInfo.txt`.

```r
source("00_INSTALL.R", encoding = "UTF-8")  # install missing dependencies once
source("00_START.R", encoding = "UTF-8")    # load functions without starting estimation
source("01_QUICK_CHECK.R", encoding = "UTF-8")
```

The same commands work with `Rscript` in a terminal. Quick checks cover endpoint coding, confirmation-day dating, horizon projection, AUC ties, validation-label maturation, the ridge fallback and calibration-in-the-large (CITL). They do not run the historical experiment or the 600-replication simulation.

Independent verification of the supplied numerical records requires only the Python standard library:

```sh
python3 scripts/verify_reference.py
```

## Choose an experiment

| Entry point | Work performed | Inputs |
|---|---|---|
| `02_RUN_EXAMPLE.R` | One non-proportional-hazards replication; oracle disabled | No market data |
| `03_RUN_PILOT.R` | Two replications in each of six scenarios; structural/numerical checks | No market data |
| `04_RUN_SIMULATION.R` | 100 replications per scenario, 600 total; independent-oracle diagnostics | Successful current-source pilot |
| `05_RUN_MARKET.R` | Primary historical fit and all nine regular rolling attempts | Authorized frozen market snapshot |
| `06_EXPORT_SPECIFICATION.R` | Effective configuration and current runtime | Installed R dependencies |
| `07_REPAIR_ARCHIVED_CITL.R` | Reporting-only repair of older full-run outputs | All 600 original fitted-rule files |
| `08_INSTALL_SNAPSHOT.R` | Verify and install an authorized local snapshot archive | Online Resource 2 or the complete manuscript package |

Each experiment is explicitly started by its own entry point. Full studies are computationally intensive. Results and resumable task records are written under `results/`, which is excluded from version control. Unsupported attempts remain recorded; support rules are not relaxed and failed seeds are not replaced by favourable ones.

For the full simulation:

```r
source("03_RUN_PILOT.R", encoding = "UTF-8")
source("04_RUN_SIMULATION.R", encoding = "UTF-8")
```

The pilot and full cohorts have different seeds. The full cohort uses 3,600 sessions, six assets, base seed 5,800,000, eight oracle batches and 2,000 oracle origins per batch. The six scenarios and all fixed settings are recorded in `metadata/frozen_specification.json` and the frozen R source. A single example or successful quick check is not a substitute for this experiment.

## Historical data

Raw Yahoo Finance observations and provider response payloads are not distributed in this code repository. `data/README.md` explains how an authorized holder of the preserved snapshot can install it and verify its exact identity. The universe and expected file hashes are supplied. Historical estimation does not download or refresh provider data, does not substitute synthetic observations and does not accept a changed snapshot silently.

```r
Sys.setenv(LIQ_SNAPSHOT_ARCHIVE = "C:/path/to/Online_Resource_2_Replication.zip")
source("08_INSTALL_SNAPSHOT.R", encoding = "UTF-8")
source("05_RUN_MARKET.R", encoding = "UTF-8")
```

The selected historical panel contains 40 exchange-traded funds and 60 equities; VIX is external context. Its selection is retrospective. The historical test period had been inspected during development, so chronological fitting is not presented as prospective validation. A new provider download may contain different data and cannot establish bitwise reproduction of the preserved vintage.

## Archived evidence and figures

`reference/` contains study-derived forecasts, outcomes, aggregate indices and summary tables. It does not contain provider OHLCV records. The supplied core forecasts allow independent recalculation of the historical Brier scores and AUCs for Cox, the residual, LIQ-P, LIQ-R and horizon logit. The files retain every known 30-session negative.

To redraw the six main figures and coverage figure from their archived numerical records:

```sh
python3 -m pip install -r requirements-figures.txt
python3 scripts/reproduce_figures.py
```

Figures are written to `results/figures/`. Redrawing them does not refit models, select a forecasting rule or create new Monte Carlo evidence. `reference/README.md` identifies their provenance and uncertainty interpretation.

After an authorized historical re-estimation, the added fixed-fit diagnostic calculations can also be repeated:

```sh
python3 -m pip install -r requirements-diagnostics.txt
python3 scripts/recompute_diagnostics.py
```

This separately reconstructs the index, proxy comparisons, cohort restrictions and 1,999-resample diagnostics from the installed snapshot and newly generated historical outputs. It binds caches to input/output identities. It does not retrain models or count the diagnostic resamples as independent market observations.

To add the paper's explicitly identified raw-training-reference skill scores to a newly generated model/horizon table:

```sh
python3 scripts/summarize_run.py results/market/tasks/primary/tables/T03_horizon_performance.csv
```

The original R columns `BSS_historical` and `BSS_regime` use the calibrated reference forecasts. The extra Python columns `BSS_historical_raw_training` and `BSS_regime_raw_training` use raw training references, as identified in the paper. Their denominators must not be interchanged.

## Frozen model and reporting correction

The standalone scientific source `LIQ_REC_Fin_Major_Revision_v4_8_0.R` is preserved byte for byte:

```text
SHA256 9f0d78386a675b9349c3d63d38eddf86d7f855c751e43db9e20756ff2b4d86b3
MD5    ed19ad4035b799915163897644a8515c
```

Use the numbered entry points. They source the model with automatic execution disabled, set explicit output profiles, and register the archived ridge-prediction methods for use in an isolated environment. The public loader applies the previously verified bracketed-score CITL correction. It changes the reported intercept only: forecasting fits, calibration maps, probability outputs and deployment decisions are unaffected. Joint calibration intercept/slope diagnostics remain separate.

Interface version **1.0.0** packages the frozen scientific model **4.8.0**; the interface version is not a new forecasting method. See `documentation/METHOD.md` for information flow and `documentation/REPRODUCTION.md` for the complete reproduction scope.

## Interpretation

- The primary historical Brier reduction is approximately **1.13%**; simultaneous paired intervals include zero at every horizon.
- In all **eight supported rolling windows**, LIQ-P equals Cox exactly. The ninth regular attempt is retained as unsupported.
- Under simulated non-proportional hazards, LIQ-P reduces Cox Brier loss by approximately **5.88%**. Multiplicity-adjusted Brier superiority over horizon logit is not established.
- Probability and ranking objectives can disagree. Ranking deteriorates under regime reversal, and daily proxy recovery does not establish recovery of executable liquidity.

The full 81-design event-definition grid, a point-in-time/delisted universe and independent execution-cost validation are outside the available evidence. Archived numerical consistency checks do not close those empirical questions.

## Citation and license

Authors: Çağlar Sözen, Giresun University; Mervenur Sözen, Ondokuz Mayıs University. Correspondence: caglar.sozen@giresun.edu.tr.

Use `CITATION.cff` and identify the exact Git commit used for an analysis. The manuscript title is supplied as context; no journal acceptance, publication DOI or registered software DOI is asserted.

The repository's MIT license applies to the authors' software and documentation. Third-party software and financial observations retain their own terms. See `THIRD_PARTY_NOTICES.md`.
