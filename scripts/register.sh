# Registers a moving image to a fixed image with SimpleITK. Rebuilds the
# legacy RADIOMICS_REGISTER_SETTINGS JSON blob from typed env vars (see
# image_ingest.sh). The transform_type membership rule has no DSL
# equivalent (and the runner would silently treat an unknown value as
# rigid), so the script enforces it with the legacy error message.

set -eu

RADIOMICS_REGISTER_SETTINGS=$(python -c '
import json
import os

transform_type = os.environ["RADIOMICS_TRANSFORM_TYPE"]
if transform_type not in ("rigid", "affine"):
    raise SystemExit("transform_type must be rigid or affine")
settings = {
    "transform_type": transform_type,
    "iterations": int(os.environ["RADIOMICS_ITERATIONS"]),
    "learning_rate": float(os.environ["RADIOMICS_LEARNING_RATE"]),
    "sampling_percent": float(os.environ["RADIOMICS_SAMPLING_PERCENT"]),
}
print(json.dumps(settings))
')
export RADIOMICS_REGISTER_SETTINGS

exec python /opt/radiomics/radiomics_runner.py register
