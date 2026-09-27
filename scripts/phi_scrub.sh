# Removes PHI from one DICOM File or FileSet. Rebuilds the legacy
# RADIOMICS_PHI_SCRUB_SETTINGS JSON blob from typed env vars (see
# image_ingest.sh). The pseudonym-requires-keep_patient_id gate has no DSL
# equivalent, so the script enforces it with the legacy error message.

set -eu

RADIOMICS_PHI_SCRUB_SETTINGS=$(python -c '
import json
import os

keep_patient_id = os.environ["RADIOMICS_KEEP_PATIENT_ID"].lower() == "true"
pseudonym = os.environ.get("RADIOMICS_PSEUDONYM") or None
if pseudonym is not None and not pseudonym.strip():
    raise SystemExit("pseudonym cannot be empty when provided")
if pseudonym is not None and not keep_patient_id:
    raise SystemExit("pseudonym requires keep_patient_id=true")
settings = {
    "keep_patient_id": keep_patient_id,
    "pseudonym": pseudonym,
}
print(json.dumps(settings))
')
export RADIOMICS_PHI_SCRUB_SETTINGS

exec python /opt/radiomics/radiomics_runner.py phi-scrub
