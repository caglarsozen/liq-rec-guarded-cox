# Code inspection: 4 November 2026

Baseline inspected: commit `75134d92c5d204a4f734e9a29c916b8ba7559456`. All 66 baseline files were retrieved through GitHub and checked against their Git blob identities. The scientific source remains byte-for-byte model 4.8.0, SHA256 `9f0d78386a675b9349c3d63d38eddf86d7f855c751e43db9e20756ff2b4d86b3`.

## Findings and corrections

| Finding | Consequence | Correction |
|---|---|---|
| Alternative membership, asset-metadata or context environment variables could be inherited by public entry points; the progress output directory could also be redirected. | A nominally fixed public profile could use another session's inputs or summary destination. | A shared explicit profile now pins input/output settings and clears alternative inputs temporarily. Environment restoration is tested. |
| The historical entry point checked the local snapshot lock, while the published size/MD5 identities were enforced only by the installer. | Manually installing a different dataset and its matching replacement lock could pass the internal lock check. | The historical entry point now verifies all four installed files against the published manifest before invoking the original runner. Exact files, changed observations plus lock, and missing provenance are tested. |
| The configuration exporter used the generic configuration rather than the effective public experiment profiles. | Its default simulation seed and output configuration did not describe the numbered full-simulation entry point. | The exporter now writes separate pilot/full/market/example configurations and model specifications. |

These are public-interface reproducibility corrections. They do not change the original learning objectives, features, event definitions, fitting algorithms, calibration maps, deployment guards, random seeds or stored study forecasts.

## Verification scope

- The independent Python check recalculates historical Brier loss and tie-adjusted AUC from 25,680 archived forecast rows. Its 75 checks retain 1,284 events and all 95 known 30-session negatives. Mean Brier scores remain 0.16672858953636924 for Cox and 0.1648407969768294 for LIQ-P.
- All seven figure scripts were executed from archived numerical records. The separately named raw-training-reference skill columns agree with the reported historical values. These operations do not fit models.
- The R quick suite contains 32 checks, including endpoint coding, horizon projection, stable calibration intercepts, ridge fallback score equations, purged selection, low-support Cox fallback, profile isolation and snapshot identities.
- Continuous verification exercises R 4.5.0 on Ubuntu and Windows, a complete illustrative non-proportional-hazards fit on each, all 12 pilot attempts with independent-oracle diagnostics on Ubuntu, and effective-profile export. Workflow results, rather than this list of checks alone, determine whether a commit passes.

The inspection also traced training-prefix reconstruction, complete-window eligibility, proposal-label maturation, offset correction, candidate replay, tied AUC influence values, and the separation of ranking from probability evaluation. No additional change to the frozen scientific model was made from that inspection.

## Limits

The full 600-replication experiment and the 100-asset historical fitting pipeline were not rerun for this code inspection. The newly executable pilot is a separate diagnostic cohort. The source's 600-replication summaries and the archived historical records remain evidence from the original fits. Exact market re-estimation requires the authorized private snapshot and compatible recorded dependencies. The adapted Python fixed-fit diagnostic script was syntax-checked; this inspection did not repeat its entire private-data workflow.

Historical test reuse, retrospective universe selection, the uncompleted 81-design grid and the lack of independent execution-cost validation remain scientific limitations. Passing software checks does not establish prospective superiority, calibration after regime change, or finite-sample coverage guarantees.
