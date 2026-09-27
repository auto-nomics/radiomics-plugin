# Normalizes one voxel mask or rasterizes one RTSTRUCT against the
# reference image on input port 0. Rebuilds the legacy
# RADIOMICS_MASK_SETTINGS JSON blob from typed env vars (see image_ingest.sh)
# and execs the pinned runner command.

set -eu

RADIOMICS_MASK_SETTINGS=$(python -c '
import json
import os

settings = {
    "z_sort": os.environ["RADIOMICS_Z_SORT"],
    "z_direction": os.environ["RADIOMICS_Z_DIRECTION"],
    "roi_name": os.environ.get("RADIOMICS_ROI_NAME") or None,
}
print(json.dumps(settings))
')
export RADIOMICS_MASK_SETTINGS

exec python /opt/radiomics/radiomics_runner.py ingest-mask
