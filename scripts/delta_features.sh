# Computes baseline-to-followup feature changes from a wide feature table.
# Rebuilds the legacy RADIOMICS_DELTA_SETTINGS JSON blob from typed env
# vars (see image_ingest.sh). The baseline/followup distinctness rule has
# no DSL equivalent, so the script enforces it with the legacy message.

set -eu

RADIOMICS_DELTA_SETTINGS=$(python -c '
import json
import os

baseline = os.environ["RADIOMICS_BASELINE"]
followup = os.environ["RADIOMICS_FOLLOWUP"]
if baseline == followup:
    raise SystemExit("baseline and followup must differ")
settings = {
    "id_column": os.environ["RADIOMICS_ID_COLUMN"],
    "timepoint_column": os.environ["RADIOMICS_TIMEPOINT_COLUMN"],
    "baseline": baseline,
    "followup": followup,
}
print(json.dumps(settings))
')
export RADIOMICS_DELTA_SETTINGS

exec python /opt/radiomics/radiomics_runner.py delta-features
