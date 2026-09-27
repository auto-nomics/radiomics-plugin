# Computes ROI/background SNR, CNR, uniformity, and slice completeness.
# Rebuilds the legacy RADIOMICS_IMAGE_QC_SETTINGS JSON blob from typed env
# vars (see image_ingest.sh) and execs the pinned runner command.

set -eu

RADIOMICS_IMAGE_QC_SETTINGS=$(python -c '
import json
import os

settings = {
    "extraction_id": os.environ["RADIOMICS_EXTRACTION_ID"],
    "mask_label": int(os.environ["RADIOMICS_MASK_LABEL"]),
}
print(json.dumps(settings))
')
export RADIOMICS_IMAGE_QC_SETTINGS

exec python /opt/radiomics/radiomics_runner.py image-qc
