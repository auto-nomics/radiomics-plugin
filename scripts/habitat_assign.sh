# Assigns tumor voxels to the frozen habitat centers from habitat-fit.
# Rebuilds the legacy RADIOMICS_HABITAT_ASSIGN_SETTINGS JSON blob from
# typed env vars (see image_ingest.sh) and execs the pinned runner
# command.

set -eu

RADIOMICS_HABITAT_ASSIGN_SETTINGS=$(python -c '
import json
import os

settings = {
    "mask_label": int(os.environ["RADIOMICS_MASK_LABEL"]),
}
print(json.dumps(settings))
')
export RADIOMICS_HABITAT_ASSIGN_SETTINGS

exec python /opt/radiomics/radiomics_runner.py habitat-assign
