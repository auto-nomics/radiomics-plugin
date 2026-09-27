# Normalizes one NIfTI/MHA file or DICOM-series FileSet to MHA.
#
# The legacy Rust wrapper passed one JSON settings blob per variant in a
# single RADIOMICS_*_SETTINGS environment variable. The v0 env template
# surface cannot build that blob (no JSON arrays, no null for absent
# optionals, no string escaping), so this script rebuilds it from the typed
# RADIOMICS_* variables with json.dumps and execs the pinned runner. The
# runner therefore sees the same document the Rust serde_json macro made.

set -eu

RADIOMICS_IMAGE_SETTINGS=$(python -c '
import json
import os

settings = {
    "z_sort": os.environ["RADIOMICS_Z_SORT"],
    "z_direction": os.environ["RADIOMICS_Z_DIRECTION"],
}
print(json.dumps(settings))
')
export RADIOMICS_IMAGE_SETTINGS

exec python /opt/radiomics/radiomics_runner.py ingest-image
