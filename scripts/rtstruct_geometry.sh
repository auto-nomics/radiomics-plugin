# Profiles RTSTRUCT contour geometry against a reference image. Rebuilds
# the legacy RADIOMICS_RTSTRUCT_GEOMETRY_SETTINGS JSON blob from typed env
# vars (see image_ingest.sh) and execs the pinned runner command. An empty
# roi_name means omitted, so every ROI is profiled.

set -eu

RADIOMICS_RTSTRUCT_GEOMETRY_SETTINGS=$(python -c '
import json
import os

settings = {
    "roi_name": os.environ.get("RADIOMICS_ROI_NAME") or None,
}
print(json.dumps(settings))
')
export RADIOMICS_RTSTRUCT_GEOMETRY_SETTINGS

exec python /opt/radiomics/radiomics_runner.py rtstruct-geometry
