# Applies mask-guided N4 bias-field correction. Rebuilds the legacy
# RADIOMICS_BIAS_SETTINGS JSON blob from typed env vars (see
# image_ingest.sh). The per-level iteration list travels as a
# space-separated string (no array-of-numbers param type), so the level
# count and positivity rules are re-checked here with the legacy message.

set -eu

RADIOMICS_BIAS_SETTINGS=$(python -c '
import json
import os

iterations = [int(part) for part in os.environ["RADIOMICS_MAX_ITERATIONS"].split()]
if not iterations or len(iterations) > 8 or 0 in iterations:
    raise SystemExit("max_iterations must contain 1-8 positive levels")
settings = {
    "mask_label": int(os.environ["RADIOMICS_MASK_LABEL"]),
    "shrink_factor": int(os.environ["RADIOMICS_SHRINK_FACTOR"]),
    "max_iterations": iterations,
    "convergence_threshold": float(os.environ["RADIOMICS_CONVERGENCE_THRESHOLD"]),
}
print(json.dumps(settings))
')
export RADIOMICS_BIAS_SETTINGS

exec python /opt/radiomics/radiomics_runner.py bias-correct
