# Applies percentile-truncated robust z-score normalization. Rebuilds the
# legacy RADIOMICS_NORMALIZE_SETTINGS JSON blob from typed env vars (see
# image_ingest.sh). The percentile ordering rule has no DSL equivalent, so
# the script enforces it with the legacy error message.

set -eu

RADIOMICS_NORMALIZE_SETTINGS=$(python -c '
import json
import os

lower = float(os.environ["RADIOMICS_LOWER_PERCENTILE"])
upper = float(os.environ["RADIOMICS_UPPER_PERCENTILE"])
if not lower < upper:
    raise SystemExit("percentiles must be finite, in [0, 100], and ordered")
settings = {
    "mask_label": int(os.environ["RADIOMICS_MASK_LABEL"]),
    "lower_percentile": lower,
    "upper_percentile": upper,
}
print(json.dumps(settings))
')
export RADIOMICS_NORMALIZE_SETTINGS

exec python /opt/radiomics/radiomics_runner.py normalize
