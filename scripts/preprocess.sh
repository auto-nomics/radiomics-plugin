# Applies deterministic radiomics preprocessing. Rebuilds the legacy
# RADIOMICS_PREPROCESS_SETTINGS JSON blob from typed env vars (see
# image_ingest.sh). The optional list-valued params travel as
# space-separated strings; empty means null, exactly like the legacy None.
# The ordering rules the manifest bounds cannot carry are re-checked here
# with the legacy error messages.

set -eu

RADIOMICS_PREPROCESS_SETTINGS=$(python -c '
import json
import os

spacing = os.environ.get("RADIOMICS_RESAMPLED_SPACING") or None
if spacing is not None:
    spacing = [float(part) for part in spacing.split()]
    if len(spacing) != 3 or any(not value > 0.0 for value in spacing):
        raise SystemExit("resampled_spacing must contain three positive numbers")
resegment = os.environ.get("RADIOMICS_RESEGMENT_RANGE") or None
if resegment is not None:
    bounds = [float(part) for part in resegment.split()]
    if len(bounds) != 2 or bounds[0] > bounds[1]:
        raise SystemExit("resegment_range must be finite and ordered")
    resegment = [bounds[0], bounds[1]]
settings = {
    "resampled_spacing": spacing,
    "interpolator": os.environ["RADIOMICS_INTERPOLATOR"],
    "resegment_range": resegment,
    "normalize": os.environ["RADIOMICS_NORMALIZE"].lower() == "true",
}
print(json.dumps(settings))
')
export RADIOMICS_PREPROCESS_SETTINGS

exec python /opt/radiomics/radiomics_runner.py preprocess
