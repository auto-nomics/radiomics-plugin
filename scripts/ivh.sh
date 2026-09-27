# Extracts intensity-volume histogram values for one image/mask pair.
# Rebuilds the legacy RADIOMICS_IVH_SETTINGS JSON blob from typed env vars
# (see image_ingest.sh). The volume fractions travel as a space-separated
# string (no array-of-numbers param type), so the (0, 1] range rule is
# re-checked here with the legacy error message.

set -eu

RADIOMICS_IVH_SETTINGS=$(python -c '
import json
import os

fractions = [float(part) for part in os.environ["RADIOMICS_VOLUME_FRACTIONS"].split()]
if not fractions or any(not 0.0 < value <= 1.0 for value in fractions):
    raise SystemExit("volume_fractions must contain values in (0, 1]")
settings = {
    "extraction_id": os.environ["RADIOMICS_EXTRACTION_ID"],
    "mask_label": int(os.environ["RADIOMICS_MASK_LABEL"]),
    "volume_fractions": fractions,
}
print(json.dumps(settings))
')
export RADIOMICS_IVH_SETTINGS

exec python /opt/radiomics/radiomics_runner.py ivh-extract
