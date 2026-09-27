# Fits common intratumoral habitat centers. Rebuilds the legacy
# RADIOMICS_HABITAT_FIT_SETTINGS JSON blob from typed env vars (see
# image_ingest.sh) and execs the pinned runner command. Every
# cross-parameter rule of this variant is carried by manifest bounds.

set -eu

RADIOMICS_HABITAT_FIT_SETTINGS=$(python -c '
import json
import os

settings = {
    "mask_label": int(os.environ["RADIOMICS_MASK_LABEL"]),
    "n_habitats": int(os.environ["RADIOMICS_N_HABITATS"]),
    "sample_voxels_per_case": int(os.environ["RADIOMICS_SAMPLE_VOXELS_PER_CASE"]),
    "seed": int(os.environ["RADIOMICS_SEED"]),
    "standardize": os.environ["RADIOMICS_STANDARDIZE"].lower() == "true",
    "n_init": int(os.environ["RADIOMICS_N_INIT"]),
    "max_iter": int(os.environ["RADIOMICS_MAX_ITER"]),
}
print(json.dumps(settings))
')
export RADIOMICS_HABITAT_FIT_SETTINGS

exec python /opt/radiomics/radiomics_runner.py habitat-fit
