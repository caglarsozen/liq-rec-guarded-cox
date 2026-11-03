# Reproduction scope

The public interface packages the frozen model; it does not change its learning, calibration or selection specification. Root entry points configure input/output locations and call archived functions. The loader applies the already established stable CITL reporting definition. File hashes identify the unchanged model source and the expected private input vintage.

## Three levels of use

1. **Reference verification and redrawing:** available from the public repository alone. These operations use archived derived outputs and do not recreate fitted models.
2. **Simulation re-estimation:** available from code and installed R dependencies, without market data. Run the current pilot before the 600-replication full experiment. The example and quick tests are separate exercises.
3. **Historical re-estimation:** additionally requires authorized access to the preserved market snapshot. Installing a matching ZIP is supported; the raw snapshot is not publicly redistributed here. A replacement download constitutes a different data vintage.

The original R environment is recorded, rather than replaced with an invented dependency lockfile. `00_INSTALL.R` installs missing compatible packages; it does not claim to recreate every historical binary or platform. `00_INSTALL_ARCHIVED.R` requests the directly recorded package versions and may require compilation tools. For example, the original run used glmnet 4.1-10; a contemporary compatibility test may install a later release. Record the resulting session information with `06_EXPORT_SPECIFICATION.R`. Numerical comparisons should account for platform/library differences while preserving the frozen scientific design.

## Outputs and resumption

Pilot, full simulation, example and historical runs use separate `results/` subdirectories. The full run requires the current-source pilot receipt. Task identities include protocol information; changed inputs or incompatible receipts must not be combined with existing checkpoints. Unsupported attempts remain in status reports. No script tunes selection thresholds using the archived test scores.

Public profiles pin the universe, session counts, oracle sizes and output routes and clear inherited alternative membership, metadata and context files. Previous environment values are restored even when a run errors. `06_EXPORT_SPECIFICATION.R` exports each effective profile separately as `configuration_<stage>.R` and `model_specification_<stage>.csv`; inspecting these profiles does not fit models. The historical entry point checks the four installed snapshot files against the published size/MD5 manifest before calling the frozen runner, which also verifies its original lock.

Historical source fields named `BSS_historical` and `BSS_regime` use calibrated empirical references. For the paper's raw-training reference convention, run `scripts/summarize_run.py`; it exports separately named additional columns and leaves the archived fields untouched. The two references answer different comparisons.

## Calibration reporting

The finite CITL score root solves the weighted offset-logistic intercept equation. The loader changes this diagnostic only, preserving the original joint intercept/slope calculation. New runs through the public interface therefore report stable CITL immediately. `07_REPAIR_ARCHIVED_CITL.R` is an optional replay utility for older complete 600-task outputs; it requires their retained `fitted_rules.rds` objects and will not infer missing forecasts or refit models.

## Continuous verification

GitHub Actions runs quick mathematical/information-flow regression tests, independent archived-record checks and one illustrative fitting replication with the oracle disabled on Ubuntu and Windows with R 4.5.0. Ubuntu additionally runs the 12-attempt pilot across all six scenarios, including independent-oracle diagnostics and the pilot receipt. Both systems export all four effective public profiles. The workflow does not run the 600-replication experiment or fit the 100-asset historical panel on every commit. The badge reports the actual workflow state; it is not evidence of universal forecasting superiority or new Monte Carlo replication.
