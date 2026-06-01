"""
Convert Whisper Tiny to TFLite INT8 for on-device inference.

Usage:
    pip install -r ../requirements.txt
    python convert_whisper.py

Output:
    ../../mobile-app/assets/models/whisper_tiny_int8.tflite
    ../../mobile-app/assets/models/whisper_vocab.json
"""

import os
import json
import struct
import numpy as np
from pathlib import Path

OUTPUT_DIR = Path(__file__).parent.parent.parent / "mobile-app" / "assets" / "models"


def convert():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    print("Loading Whisper Tiny...")

    import whisper
    import torch
    import tensorflow as tf

    model = whisper.load_model("tiny")
    model.eval()

    # --- Step 1: Export encoder to ONNX ---
    print("Exporting encoder to ONNX...")
    dummy_mel = torch.zeros(1, 80, 3000)

    encoder_path = OUTPUT_DIR / "whisper_encoder.onnx"
    torch.onnx.export(
        model.encoder,
        dummy_mel,
        str(encoder_path),
        input_names=["mel"],
        output_names=["encoder_output"],
        dynamic_axes={"mel": {0: "batch"}},
        opset_version=17,
    )
    print(f"Encoder ONNX saved: {encoder_path}")

    # --- Step 2: Convert ONNX encoder to TFLite ---
    print("Converting to TFLite INT8...")
    import onnx2tf
    import subprocess, sys

    saved_model_path = OUTPUT_DIR / "whisper_encoder_tf"
    saved_model_path.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [sys.executable, "-m", "onnx2tf",
         "-i", str(encoder_path),
         "-o", str(saved_model_path),
         "--non_verbose"],
        check=True,
    )

    def representative_dataset():
        for _ in range(100):
            yield [np.random.randn(1, 80, 3000).astype(np.float32)]

    converter = tf.lite.TFLiteConverter.from_saved_model(str(saved_model_path))
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = representative_dataset
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    converter.inference_input_type = tf.float32
    converter.inference_output_type = tf.float32

    tflite_model = converter.convert()
    tflite_path = OUTPUT_DIR / "whisper_tiny_int8.tflite"
    tflite_path.write_bytes(tflite_model)
    print(f"TFLite model saved: {tflite_path} ({len(tflite_model) / 1e6:.1f} MB)")

    # --- Step 3: Export tokenizer vocab ---
    print("Exporting tokenizer vocab...")
    tokenizer = whisper.tokenizer.get_tokenizer(multilingual=True)
    vocab = {str(i): tokenizer.decode([i]) for i in range(tokenizer.encoding.n_vocab)}
    vocab_path = OUTPUT_DIR / "whisper_vocab.json"
    vocab_path.write_text(json.dumps(vocab, ensure_ascii=False))
    print(f"Vocab saved: {vocab_path}")

    # Cleanup intermediate files
    encoder_path.unlink(missing_ok=True)
    import shutil
    shutil.rmtree(saved_model_path, ignore_errors=True)

    print("\n✅ Conversion complete!")
    print(f"   Model: {tflite_path}")
    print(f"   Vocab: {vocab_path}")
    print("\nNext: run `flutter pub get` then build the APK.")


if __name__ == "__main__":
    convert()
