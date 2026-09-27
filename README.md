# radiomics plugin

Manifest plugin for the pinned PyRadiomics Stage-A image: 21 container node
kinds covering DICOM/NIfTI ingestion, geometry validation, deterministic
preprocessing, official PyRadiomics 3.1.0 extraction (single and batch),
DICOM metadata/PHI scrubbing, mask analysis, registration, and the
longitudinal-stability family (delta features, habitats, perturbations).
Migrated from the Rust wrapper `crates/node-bundles/nodes-io/src/radiomics_container.rs`
per `docs/plugin-node-migration.md`.

## Layout

```text
radiomics/
├── manifest.toml            # one [[nodes]] entry per container kind
├── scripts/*.sh             # per-variant launcher scripts (21)
├── Dockerfile               # image provenance (build + push via GHCR)
├── radiomics_runner.py      # Stage-A runner baked into the image
├── test_radiomics_*.sh      # image baselines (moved from containers/pyradiomics)
└── README.md
```

## Image

- Reference (digest-pinned, from `containers/image-inventory.tsv`):
  `ghcr.io/auto-nomics/autonomics/pyradiomics@sha256:bccbe15b2ec8d079e1bf869c4f06bfe4143642015394453c584dc981e5403fbe`
  (tag `3.1.0-r2`).
- Base `python:3.11.11-slim@sha256:a8e0a309…`; PyRadiomics 3.1.0, NumPy
  1.26.4, SimpleITK 2.3.1, PyWavelets 1.5.0, PyArrow 15.0.2, pandas 2.2.3,
  pydicom 2.4.4, scikit-image 0.22.0, trimesh 4.6.13. Family license
  SPDX: BSD-3-Clause (PyRadiomics).
- Rebuild from the plugin root:

```bash
podman build -f radiomics/Dockerfile -t localhost/atc/pyradiomics:3.1.0-r2 radiomics
```

Rebuild, retag, republish, and update `manifest.toml` `image.reference`
whenever any dependency changes. The local Podman build and the published
GHCR manifest can have different digests after registry normalization;
always pin the digest returned by the published GHCR tag.

## Variant map

| Kind | Runner command | Inputs | Outputs |
|---|---|---|---|
| `radiomics_image_ingest` | `ingest-image` | image/series | `image.mha`, `image_meta.json` |
| `radiomics_mask_ingest` | `ingest-mask` | reference + mask/RTSTRUCT | `mask.mha`, `roi_meta.json` |
| `radiomics_pair_validate` | `validate-pair` | image + mask | `pair_validation.parquet`, `geometry.json` |
| `radiomics_preprocess` | `preprocess` | image + mask | `image.mha`, `mask.mha`, `preprocess_meta.json` |
| `pyradiomics_extract` | `extract-single` | image + mask | 5 extraction artifacts |
| `pyradiomics_batch_extract` | `extract-batch` | 2 FileSets + manifest | 5 extraction artifacts |
| `radiomics_dicom_metadata` | `dicom-metadata` | DICOM file/FileSet | `dicom_metadata.parquet`, `dicom_metadata_report.json` |
| `radiomics_phi_scrub` | `phi-scrub` | DICOM file/FileSet | `scrubbed_dicom.zip`, 2 reports |
| `radiomics_voi_dice_hausdorff` | `voi-similarity` | 2 masks | `voi_similarity.parquet`, `.json` |
| `radiomics_image_qc` | `image-qc` | image + ROI + background | `image_qc.parquet`, `.json` |
| `radiomics_rtstruct_geometry` | `rtstruct-geometry` | RTSTRUCT + reference | `rtstruct_geometry.parquet`, `.json` |
| `radiomics_ivh_extract` | `ivh-extract` | image + mask | `ivh.parquet`, `ivh.json` |
| `radiomics_shape_topology` | `shape-topology` | mask | 3 artifacts |
| `radiomics_register` | `register` | fixed + moving | `registered.mha`, `transform.tfm`, `registration.json` |
| `radiomics_delta_features` | `delta-features` | wide feature table | `delta_features.parquet`, report |
| `radiomics_bias_correct` | `bias-correct` | image + mask | `corrected.mha`, `bias_field.mha`, `bias_meta.json` |
| `radiomics_robust_normalize` | `normalize` | image + mask | `normalized.mha`, `normalize_meta.json` |
| `radiomics_peritumoral_ring` | `peritumoral-ring` | tumor + exclusion + reference | 3 masks + `ring_meta.json` |
| `radiomics_habitat_fit` | `habitat-fit` | 2 FileSets + manifest | `habitats.json`, `habitat_fit_samples.parquet` |
| `radiomics_habitat_assign` | `habitat-assign` | mask + channels + habitats | `habitat_mask.mha`, features, meta |
| `radiomics_perturb_stability` | `perturb-stability` | image + mask | 3 replicate artifacts |

The non-container radiomics helpers (manifest build, stage file set, DCM
glob, QC, feature-set assembly) stay in the Rust registry
(`nodes-io/src/radiomics.rs`); they have no image and were not migrated.
The legacy kind names carried no `_container` suffix, so all 21 kinds are
unchanged from `radiomics_container.rs`.

## Design: env vars in, JSON blob out

The legacy wrapper passed one JSON settings blob per variant (for example
`RADIOMICS_IVH_SETTINGS = {"extraction_id":"…","mask_label":1,
"volume_fractions":[0.05,…]}`) built with `serde_json::json!` and read by
the runner with `json.loads`. The v0 manifest env surface cannot build
that blob directly: it has no JSON array rendering (arrays space-join),
optional params render as empty strings rather than null, and template
substitution does not escape strings.

Every script therefore receives its params as individual typed
`RADIOMICS_*` env variables (declared in `[nodes.command.env]`) and
rebuilds the blob with `json.dumps` before `exec`-ing the pinned runner
command. `json.dumps` restores the three properties the env templates
lack: string escaping, empty-optional → `null`, and space-separated →
array. The runner parses the same document the Rust macro produced. The
one spelling delta: `json.dumps(1e-6)` emits `1e-06` where serde_json
emits `1e-6`; `json.loads` treats them identically (the documented f64
rendering nuance).

`RADIOMICS_VALID_ONLY` is the exception that proves the rule: the runner
parses that variable itself as a `"true"/"false"` string, so batch
extract passes `{{ valid_only }}` straight through.

## Parity notes

Byte-exact against the legacy `container_spec` (asserted by
`crates/container-plugin/tests/radiomics_migration.rs`): image reference,
outputs (paths + formats), `network = isolated`, `read_only_rootfs`,
`pull_policy = missing`, `timeout_secs = 3600` (the wrapper's single
`DEFAULT_TIMEOUT_SECS`), `artifact_prefix = /artifacts/{kind}` (every
legacy default fn), empty `panels`/`panel_bundles`, and `gpus = None`
(the wrapper's `base_spec` never requested GPUs, so no
`[nodes.resources]` table exists anywhere in the manifest).

Semantic (script markers, not bytes), per the migration doc's
script-is-not-byte-exact rule:

- Settings blobs are rebuilt by the scripts instead of the Rust
  `serde_json::json!` macros; the JSON documents match key-for-key.
- Cross-field rules the manifest bounds cannot carry are enforced in the
  scripts with the legacy error messages: `shape2D requires force2d=true`,
  image-type/feature-class/perturbation membership, `log_sigmas` 1-10
  positive, `volume_fractions` in (0, 1], `max_iterations` 1-8 positive
  levels, `pseudonym requires keep_patient_id=true`, `baseline != followup`,
  percentile and ring-radius ordering, `resampled_spacing`/`resegment_range`
  shapes, and `transform_type` membership (the runner would silently treat
  an unknown value as rigid). `z_sort`/`z_direction` membership stays in
  the runner, which already raised the legacy error.

Deliberate deltas:

- **`radiomics_perturb_stability` now works.** The legacy wrapper
  collected and validated the six identity fields
  (`extraction_id`, `patient_id`, `image_id`, `roi_id`, `modality`,
  `preset_id`) but never put them into an env var, while the runner's
  `perturb_stability` requires `RADIOMICS_EXTRACTION` and fails with
  `missing extraction metadata` without it — the legacy node could never
  run. The script builds `RADIOMICS_EXTRACTION` from those same params.
- `timeout_secs` and `artifact_prefix` were per-DAG-spec overrides in the
  wrapper and are fixed family contracts in the manifest (same narrowing
  as every prior plugin migration).
- An empty optional string (`roi_name`, `pseudonym`) means omitted; the
  legacy wrapper rejected `Some("")` for `rtstruct_geometry.roi_name` and
  `phi_scrub.pseudonym`. `pseudonym=""` still fails (script guard);
  `roi_name=""` now selects the default behavior instead of erroring.
- `extra_tags` entries that are empty strings vanish in the
  space-join/split round-trip instead of being rejected.

DSL gaps (accepted, following the deseq2 precedent):

- No array-of-numbers param type: `log_sigmas`, `volume_fractions`,
  `max_iterations`, `resampled_spacing`, and `resegment_range` travel as
  space-separated strings and are split/type-checked in the scripts.
- Input port types are `file`-only in v0; the wrapper's `Any` and
  `FileSet` input ports (mask ingest, batch extract, DICOM metadata,
  PHI scrub, RTSTRUCT geometry, habitat fit/assign) are declared `file`.
  The runner already accepts comma-joined `AUTONOMICS_INPUT*` values, so
  FileSet payloads still flow; only the DAG-side type contract narrows.
- Scalar bounds cover the wrapper's numeric checks; trim-empty checks on
  required identity strings are covered by schema `required` (non-null)
  but not by a blank-string rejection.

## Image baselines

The `test_radiomics_*.sh` scripts run the image directly (entrypoint +
runner command) against the local IBSI checkout; they are unchanged apart
from their location:

```bash
AUTONOMICS_IBSI_DIR=/mnt/data/ibsi_dataset \
  radiomics/test_radiomics_nifti.sh
AUTONOMICS_IBSI_DIR=/mnt/data/ibsi_dataset \
  radiomics/test_radiomics_dicom.sh
AUTONOMICS_IBSI1_CT_DIR=/mnt/data/ibsi_dataset/ibsi_1_ct_radiomics_phantom \
  radiomics/test_radiomics_rtstruct_series.sh
AUTONOMICS_IBSI_DIR=/mnt/data/ibsi_dataset \
  radiomics/test_radiomics_phasea.sh
```

Publish:

```bash
GHCR_IMAGE="$AUTONOMICS_IMAGE_PREFIX/pyradiomics:3.1.0-r2"
podman tag localhost/atc/pyradiomics:3.1.0-r2 "$GHCR_IMAGE"
podman push "$GHCR_IMAGE"
```
