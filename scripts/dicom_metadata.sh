# Extracts DICOM metadata. Rebuilds the legacy
# RADIOMICS_DICOM_METADATA_SETTINGS JSON blob from typed env vars (see
# image_ingest.sh) and execs the pinned runner command.

set -eu

RADIOMICS_DICOM_METADATA_SETTINGS=$(python -c '
import json
import os

settings = {
    "extra_tags": os.environ["RADIOMICS_EXTRA_TAGS"].split(),
}
print(json.dumps(settings))
')
export RADIOMICS_DICOM_METADATA_SETTINGS

exec python /opt/radiomics/radiomics_runner.py dicom-metadata
