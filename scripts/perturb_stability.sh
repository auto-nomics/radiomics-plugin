# Re-extracts features under controlled perturbations. Rebuilds the three
# legacy JSON blobs from typed env vars (see extract.sh):
# RADIOMICS_EXTRACT_SETTINGS, RADIOMICS_PERTURB_SETTINGS, and
# RADIOMICS_EXTRACTION. The perturbation membership and uniqueness rules
# have no DSL equivalent, so the script enforces them with the legacy
# error messages.

set -eu

RADIOMICS_EXTRACT_SETTINGS=$(python -c '
import json
import os

IMAGE_TYPES = [
    "Original", "LoG", "Wavelet", "Square", "SquareRoot", "Logarithm",
    "Exponential", "Gradient", "LBP2D", "LBP3D",
]
FEATURE_CLASSES = [
    "shape", "shape2D", "firstorder", "glcm", "glrlm", "glszm", "gldm",
    "ngtdm",
]

image_types = os.environ["RADIOMICS_IMAGE_TYPES"].split()
feature_classes = os.environ["RADIOMICS_FEATURE_CLASSES"].split()
if not image_types or not feature_classes:
    raise SystemExit("image_types and feature_classes cannot be empty")
unknown_types = [name for name in image_types if name not in IMAGE_TYPES]
if unknown_types:
    raise SystemExit(
        "unsupported PyRadiomics image type(s): "
        + ", ".join(unknown_types)
        + ". Supported types: "
        + ", ".join(IMAGE_TYPES)
    )
unknown_classes = [name for name in feature_classes if name not in FEATURE_CLASSES]
if unknown_classes:
    raise SystemExit(
        "unsupported PyRadiomics feature class(es): "
        + ", ".join(unknown_classes)
        + ". PyRadiomics 3.1 supports: "
        + ", ".join(FEATURE_CLASSES)
        + " (NGLDM is not available)"
    )
force2d = os.environ["RADIOMICS_FORCE2D"].lower() == "true"
if "shape2D" in feature_classes and not force2d:
    raise SystemExit("shape2D requires force2d=true")
spacing = os.environ.get("RADIOMICS_RESAMPLED_SPACING") or None
if spacing is not None:
    spacing = [float(part) for part in spacing.split()]
    if len(spacing) != 3 or any(not value > 0.0 for value in spacing):
        raise SystemExit("resampled_spacing must contain three positive numbers")
log_sigmas = [float(part) for part in os.environ["RADIOMICS_LOG_SIGMAS"].split()]
if not 1 <= len(log_sigmas) <= 10 or any(value <= 0.0 for value in log_sigmas):
    raise SystemExit("log_sigmas must contain 1-10 positive finite values")
settings = {
    "mask_label": int(os.environ["RADIOMICS_MASK_LABEL"]),
    "bin_width": float(os.environ["RADIOMICS_BIN_WIDTH"]),
    "resampled_spacing": spacing,
    "force2d": force2d,
    "force2d_dimension": int(os.environ["RADIOMICS_FORCE2D_DIMENSION"]),
    "image_types": image_types,
    "feature_classes": feature_classes,
    "log_sigmas": log_sigmas,
}
print(json.dumps(settings))
')
export RADIOMICS_EXTRACT_SETTINGS

RADIOMICS_PERTURB_SETTINGS=$(python -c '
import json
import os

ALLOWED = ["dilate1", "erode1", "translate_x", "translate_y", "translate_z", "noise"]
perturbations = os.environ["RADIOMICS_PERTURBATIONS"].split()
unknown = [name for name in perturbations if name not in ALLOWED]
if unknown:
    raise SystemExit(
        "unsupported perturbation(s): "
        + ", ".join(unknown)
        + ". Allowed: "
        + ", ".join(ALLOWED)
    )
if len(set(perturbations)) != len(perturbations):
    raise SystemExit("perturbations must be unique")
settings = {
    "perturbations": perturbations,
    "noise_sigma_pct": float(os.environ["RADIOMICS_NOISE_SIGMA_PCT"]),
    "seed": int(os.environ["RADIOMICS_SEED"]),
}
print(json.dumps(settings))
')
export RADIOMICS_PERTURB_SETTINGS

RADIOMICS_EXTRACTION=$(python -c '
import json
import os

extraction = {
    "extraction_id": os.environ["RADIOMICS_EXTRACTION_ID"],
    "patient_id": os.environ["RADIOMICS_PATIENT_ID"],
    "image_id": os.environ["RADIOMICS_IMAGE_ID"],
    "roi_id": os.environ["RADIOMICS_ROI_ID"],
    "modality": os.environ["RADIOMICS_MODALITY"],
    "preset_id": os.environ["RADIOMICS_PRESET_ID"],
}
print(json.dumps(extraction))
')
export RADIOMICS_EXTRACTION

exec python /opt/radiomics/radiomics_runner.py perturb-stability
