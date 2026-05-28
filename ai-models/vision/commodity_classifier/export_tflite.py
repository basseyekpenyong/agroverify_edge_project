"""
Export Pipeline: PyTorch → ONNX → TensorFlow → TFLite (INT8)
Run after training: python export_tflite.py
"""

import torch
import torchvision.models as models
import torch.nn as nn
import numpy as np
import tensorflow as tf
from pathlib import Path

NUM_CLASSES = 10
IMG_SIZE = 224
CHECKPOINT = Path("checkpoints/commodity_classifier.pt")
ONNX_OUT = Path("exports/commodity_classifier.onnx")
TFLITE_OUT = Path("exports/commodity_classifier_int8.tflite")
LABELS_OUT = Path("exports/labels.txt")

COMMODITY_CLASSES = [
    "maize", "cassava", "sorghum", "rice", "soy",
    "groundnuts", "yam", "millet", "cocoa", "palm_oil",
]


def load_pytorch_model():
    model = models.mobilenet_v3_small(weights=None)
    model.classifier[-1] = nn.Linear(model.classifier[-1].in_features, NUM_CLASSES)
    model.load_state_dict(torch.load(CHECKPOINT, map_location="cpu"))
    model.eval()
    return model


def export_onnx(model):
    ONNX_OUT.parent.mkdir(parents=True, exist_ok=True)
    dummy = torch.randn(1, 3, IMG_SIZE, IMG_SIZE)
    torch.onnx.export(
        model, dummy, str(ONNX_OUT),
        input_names=["input"], output_names=["output"],
        dynamic_axes={"input": {0: "batch"}, "output": {0: "batch"}},
        opset_version=17,
    )
    print(f"ONNX exported: {ONNX_OUT}")


def export_tflite_int8():
    # Load the SavedModel (converted from ONNX separately via onnx-tf)
    saved_model_dir = "exports/saved_model"
    converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_dir)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    converter.inference_input_type = tf.int8
    converter.inference_output_type = tf.int8

    # Representative dataset for INT8 calibration
    def representative_dataset():
        for _ in range(100):
            yield [np.random.rand(1, IMG_SIZE, IMG_SIZE, 3).astype(np.float32)]

    converter.representative_dataset = representative_dataset
    tflite_model = converter.convert()

    TFLITE_OUT.parent.mkdir(parents=True, exist_ok=True)
    TFLITE_OUT.write_bytes(tflite_model)
    print(f"TFLite INT8 exported: {TFLITE_OUT} ({len(tflite_model)/1024:.1f} KB)")


def write_labels():
    LABELS_OUT.write_text("\n".join(COMMODITY_CLASSES))
    print(f"Labels written: {LABELS_OUT}")


if __name__ == "__main__":
    print("Step 1: Loading PyTorch model...")
    model = load_pytorch_model()

    print("Step 2: Exporting to ONNX...")
    export_onnx(model)

    print("Step 3: Exporting TFLite INT8 (requires onnx-tf SavedModel)...")
    export_tflite_int8()

    write_labels()
    print("Export pipeline complete.")
