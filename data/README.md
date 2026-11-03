# Authorized local market snapshot

Historical reproduction uses the preserved 100-asset Yahoo Finance OHLCV snapshot, including VIX as context. Raw provider observations and response payloads are not distributed here. The code is usable for simulations without them.

An authorized holder can install the snapshot from `Online_Resource_2_Replication.zip` or the containing manuscript-package ZIP using `08_INSTALL_SNAPSHOT.R`. This installer accepts local files only, selects four expected members, verifies file sizes and MD5 identities, and preserves any different existing input by stopping before installation. SHA256 identifiers are also provided in `metadata/expected_snapshot.json`.

Expected local files are:

- `data/frozen_ohlcv.csv`
- `data/frozen_ohlcv.csv.lock.csv`
- `data/data_provenance.csv`
- `universe/universe_100.csv`

The lock binds the observations, provenance and universe. It remains enabled in the public historical entry point. Access to the preserved vintage is necessary for exact historical reproduction; the repository alone does not supply that vintage.

The CSV schema includes `asset`, `date`, `open`, `high`, `low`, `close`, `adjusted` and `volume`. Dates refer to observed sessions. Nonpositive volume and invalid price records are excluded according to the scientific source. Missing observations are not forward-filled. Volume is read explicitly to avoid integer conversion errors.

The 29-asset baseline was preserved; its original retrieval date is unknown. The 71 additions were obtained on 23 October 2026. The panel is a retrospective convenience sample, not a point-in-time membership panel. Original provider corporate-action conventions were not independently reconstructed. Fresh provider downloads may differ and must be documented as a separate vintage rather than used to claim exact replication.

Provider data remain subject to the provider's terms. The repository's software license does not grant rights to third-party financial observations.
