# Extracts mask topology, principal axes, and per-slice geometry. Rebuilds
# the legacy RADIOMICS_SHAPE_TOPOLOGY_SETTINGS JSON blob from typed env
# vars (see image_ingest.sh) and execs the pinned runner command.

set -eu

RADIOMICS_SHAPE_TOPOLOGY_SETTINGS=$(python -c '
import json
import os

settings = {
    "extraction_id": os.environ["RADIOMICS_EXTRACTION_ID"],
    "mask_label": int(os.environ["RADIOMICS_MASK_LABEL"]),
}
print(json.dumps(settings))
')
export RADIOMICS_SHAPE_TOPOLOGY_SETTINGS

exec python /opt/radiomics/radiomics_runner.py shape-topology
