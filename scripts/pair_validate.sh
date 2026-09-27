# Validates image/mask geometry and ROI voxel count. Rebuilds the legacy
# RADIOMICS_VALIDATE_SETTINGS JSON blob from typed env vars (see
# image_ingest.sh) and execs the pinned runner command.

set -eu

RADIOMICS_VALIDATE_SETTINGS=$(python -c '
import json
import os

settings = {
    "extraction_id": os.environ["RADIOMICS_EXTRACTION_ID"],
    "mask_label": int(os.environ["RADIOMICS_MASK_LABEL"]),
    "minimum_mask_voxels": int(os.environ["RADIOMICS_MINIMUM_MASK_VOXELS"]),
    "geometry_tolerance_mm": float(os.environ["RADIOMICS_GEOMETRY_TOLERANCE_MM"]),
}
print(json.dumps(settings))
')
export RADIOMICS_VALIDATE_SETTINGS

exec python /opt/radiomics/radiomics_runner.py validate-pair
