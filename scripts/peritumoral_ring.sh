# Builds an anatomically constrained peritumoral ring mask. Rebuilds the
# legacy RADIOMICS_RING_SETTINGS JSON blob from typed env vars (see
# image_ingest.sh). The radius ordering rule has no DSL equivalent, so the
# script enforces it with the legacy error message.

set -eu

RADIOMICS_RING_SETTINGS=$(python -c '
import json
import os

inner = float(os.environ["RADIOMICS_INNER_MM"])
outer = float(os.environ["RADIOMICS_OUTER_MM"])
if not inner < outer:
    raise SystemExit("radii must be finite, in [0, 50] millimeters, and ordered")
settings = {
    "mask_label": int(os.environ["RADIOMICS_MASK_LABEL"]),
    "inner_mm": inner,
    "outer_mm": outer,
}
print(json.dumps(settings))
')
export RADIOMICS_RING_SETTINGS

exec python /opt/radiomics/radiomics_runner.py peritumoral-ring
