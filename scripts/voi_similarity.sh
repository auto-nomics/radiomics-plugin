# Computes Dice/Jaccard/Hausdorff/surface-Dice for two masks. Rebuilds the
# legacy RADIOMICS_VOI_SETTINGS JSON blob from typed env vars (see
# image_ingest.sh) and execs the pinned runner command.

set -eu

RADIOMICS_VOI_SETTINGS=$(python -c '
import json
import os

settings = {
    "comparison_id": os.environ["RADIOMICS_COMPARISON_ID"],
    "mask_label": int(os.environ["RADIOMICS_MASK_LABEL"]),
    "surface_tolerance_mm": float(os.environ["RADIOMICS_SURFACE_TOLERANCE_MM"]),
}
print(json.dumps(settings))
')
export RADIOMICS_VOI_SETTINGS

exec python /opt/radiomics/radiomics_runner.py voi-similarity
