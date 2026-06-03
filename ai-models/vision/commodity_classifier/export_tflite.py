"""
Export pipeline: PyTorch checkpoint → ONNX → TFLite INT8

Uses onnx2tf (already in requirements.txt) which converts ONNX directly to
TFLite without the brittle onnx-tf → SavedModel intermediate step.

INT8 calibration uses real validation images for accurate quantization.

Usage:
  python export_tflite.py

Output:
  exports/commodity_classifier_int8.tflite   (deploy this to Flutter)
  exports/labels.txt
  ../../mobile-app/assets/models/commodity_classifier_int8.tflite  (auto-copied)
"""

import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn
import torchvision.models as models
import torchvision.transforms as transforms
from PIL import Image
from tqdm import tqdm

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
CHECKPOINT   = Path("checkpoints/commodity_classifier.pt")
ONNX_OUT     = Path("exports/commodity_classifier.onnx")
TFLITE_OUT   = Path("exports/commodity_classifier_int8.tflite")
LABELS_OUT   = Path("exports/labels.txt")
VAL_DIR      = Path("datasets/commodity_images/val")
ASSETS_DEST  = Path("../../../mobile-app/assets/models/commodity_classifier_int8.tflite")

NUM_CLASSES = 10
IMG_SIZE    = 224

COMMODITY_CLASSES = [
    "maize", "cassava", "sorghum", "rice", "soy",
    "groundnuts", "yam", "millet", "cocoa", "palm_oil",
]

# ---------------------------------------------------------------------------
# Step 1 — Load trained PyTorch model
# ---------------------------------------------------------------------------

def load_model() -> torch.nn.Module:
    model = models.mobilenet_v3_small(weights=None)
    model.classifier[-1] = nn.Linear(model.classifier[-1].in_features, NUM_CLASSES)
    model.load_state_dict(torch.load(CHECKPOINT, map_location="cpu", weights_only=True))
    model.eval()
    return model


# ---------------------------------------------------------------------------
# Step 2 — Export to ONNX
# ---------------------------------------------------------------------------

def export_onnx(model: torch.nn.Module) -> None:
    ONNX_OUT.parent.mkdir(parents=True, exist_ok=True)
    dummy = torch.randn(1, 3, IMG_SIZE, IMG_SIZE)
    torch.onnx.export(
        model, dummy, str(ONNX_OUT),
        input_names=["input"],
        output_names=["output"],
        dynamic_axes={"input": {0: "batch"}, "output": {0: "batch"}},
        opset_version=17,
    )
    print(f"  ONNX saved: {ONNX_OUT} ({ONNX_OUT.stat().st_size / 1024:.0f} KB)")


# ---------------------------------------------------------------------------
# Step 3 — Build representative dataset for INT8 calibration
# ---------------------------------------------------------------------------

def build_calib_dataset(n_images: int = 200) -> list[np.ndarray]:
    """
    Load real validation images for INT8 calibration.
    Falls back to random noise if val set not available yet.
    """
    preprocess = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(IMG_SIZE),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
    ])

    images: list[np.ndarray] = []

    if VAL_DIR.exists():
        print(f"  Loading calibration images from {VAL_DIR}...")
        paths = []
        for class_dir in sorted(VAL_DIR.iterdir()):
            paths.extend(sorted(class_dir.glob("*.jpg"))[:n_images // NUM_CLASSES + 1])

        for p in tqdm(paths[:n_images], desc="  calibration", unit="img", leave=False):
            try:
                img = preprocess(Image.open(p).convert("RGB"))
                # TFLite expects NHWC layout
                arr = img.permute(1, 2, 0).numpy()[np.newaxis]  # (1, H, W, C)
                images.append(arr.astype(np.float32))
            except Exception:
                continue
        print(f"  {len(images)} calibration images loaded from validation set")
    else:
        print("  Val set not found — using random noise for calibration (accuracy may suffer)")
        print("  Run download_dataset.py + train.py first for best results")

    if not images:
        images = [np.random.rand(1, IMG_SIZE, IMG_SIZE, 3).astype(np.float32) for _ in range(100)]

    return images


# ---------------------------------------------------------------------------
# Step 4 — Convert ONNX → TFLite INT8 via onnx2tf
# ---------------------------------------------------------------------------

def export_tflite_int8(calib_images: list[np.ndarray]) -> None:
    """
    Uses onnx2tf CLI (more reliable than Python API for complex graphs).
    Writes calibration data to a .npy file that onnx2tf reads for INT8 PTQ.
    """
    import tempfile
    import os

    exports_dir = ONNX_OUT.parent
    exports_dir.mkdir(parents=True, exist_ok=True)

    # Save calibration data as npy for onnx2tf
    calib_path = exports_dir / "calib_data.npy"
    calib_arr = np.concatenate(calib_images, axis=0)  # (N, H, W, C)
    np.save(str(calib_path), calib_arr)
    print(f"  Calibration data: {calib_arr.shape} saved to {calib_path}")

    # Run onnx2tf to convert ONNX → TFLite INT8
    cmd = [
        sys.executable, "-m", "onnx2tf",
        "-i", str(ONNX_OUT),
        "-o", str(exports_dir / "saved_model"),
        "-oiqt",                    # output INT8 quantized TFLite
        "-cind", "input",           # calibration input node name
        str(calib_path),            # calibration data file
        "[[[[0.485,0.456,0.406]]]]",  # mean (NHWC)
        "[[[[0.229,0.224,0.225]]]]",  # std  (NHWC)
        "--non_verbose",
    ]

    print(f"  Running onnx2tf...")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"  onnx2tf stderr:\n{result.stderr[-2000:]}")
        raise RuntimeError("onnx2tf conversion failed — see output above")

    # Find the generated INT8 TFLite file
    saved_model_dir = exports_dir / "saved_model"
    int8_candidates = list(saved_model_dir.glob("*int8*.tflite"))
    if not int8_candidates:
        # fallback: any tflite file
        int8_candidates = list(saved_model_dir.glob("*.tflite"))

    if not int8_candidates:
        raise FileNotFoundError(f"No TFLite file found in {saved_model_dir}")

    src = sorted(int8_candidates)[-1]
    shutil.copy2(src, TFLITE_OUT)
    size_kb = TFLITE_OUT.stat().st_size / 1024
    print(f"  TFLite INT8 saved: {TFLITE_OUT} ({size_kb:.0f} KB)")

    # Clean up calibration file
    calib_path.unlink(missing_ok=True)


# ---------------------------------------------------------------------------
# Step 5 — Copy to Flutter assets
# ---------------------------------------------------------------------------

def copy_to_assets() -> None:
    dest = Path(__file__).parent / ASSETS_DEST
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(TFLITE_OUT, dest)
    print(f"  Copied to Flutter assets: {dest.resolve()}")


# ---------------------------------------------------------------------------
# Step 6 — Write labels file
# ---------------------------------------------------------------------------

def write_labels() -> None:
    LABELS_OUT.write_text("\n".join(COMMODITY_CLASSES))
    print(f"  Labels written: {LABELS_OUT}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    print("=" * 55)
    print("AgroVerify Commodity Classifier — Export Pipeline")
    print("=" * 55)

    if not CHECKPOINT.exists():
        print(f"\nCheckpoint not found: {CHECKPOINT}")
        print("Run train.py first.")
        sys.exit(1)

    print("\nStep 1: Loading PyTorch checkpoint...")
    model = load_model()
    print(f"  Loaded from {CHECKPOINT}")

    print("\nStep 2: Exporting to ONNX...")
    export_onnx(model)

    print("\nStep 3: Building INT8 calibration dataset...")
    calib = build_calib_dataset(n_images=200)

    print("\nStep 4: Converting ONNX → TFLite INT8 (onnx2tf)...")
    export_tflite_int8(calib)

    print("\nStep 5: Copying to Flutter assets...")
    copy_to_assets()

    print("\nStep 6: Writing labels...")
    write_labels()

    print("\n✅ Export complete.")
    print(f"   Model : {TFLITE_OUT}")
    print(f"   Labels: {LABELS_OUT}")
    print("\nNext: flutter pub get && flutter run")
