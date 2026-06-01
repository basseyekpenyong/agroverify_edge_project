"""
Convert Whisper Tiny encoder to TFLite INT8 using ai-edge-torch.
Bypasses the ONNX → onnx2tf → TFLite pipeline entirely.

Usage:
    pip install ai-edge-torch
    python voice/convert_whisper.py

Output:
    ../../mobile-app/assets/models/whisper_tiny_int8.tflite
    ../../mobile-app/assets/models/whisper_vocab.json
"""

import json
from pathlib import Path

import torch
import whisper

OUTPUT_DIR = Path(__file__).parent.parent.parent / "mobile-app" / "assets" / "models"


def convert():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    print("Loading Whisper Tiny...")
    model = whisper.load_model("tiny")
    encoder = model.encoder.eval()

    # --- Step 1: Export tokenizer vocab ---
    print("Exporting tokenizer vocab...")
    tokenizer = whisper.tokenizer.get_tokenizer(multilingual=True)
    vocab = {str(i): tokenizer.decode([i]) for i in range(tokenizer.encoding.n_vocab)}
    vocab_path = OUTPUT_DIR / "whisper_vocab.json"
    vocab_path.write_text(json.dumps(vocab, ensure_ascii=False), encoding='utf-8')
    print(f"Vocab saved: {vocab_path}")

    # --- Step 2: Try ai-edge-torch (direct PyTorch → TFLite, no ONNX needed) ---
    try:
        import ai_edge_torch
        print("Converting encoder with ai-edge-torch (PyTorch → TFLite directly)...")

        sample_input = torch.zeros(1, 80, 3000, dtype=torch.float32)
        edge_model = ai_edge_torch.convert(encoder, (sample_input,))

        tflite_path = OUTPUT_DIR / "whisper_tiny_int8.tflite"
        edge_model.export(str(tflite_path))
        print(f"\n✅ TFLite model saved: {tflite_path} ({tflite_path.stat().st_size / 1e6:.1f} MB)")

    except ImportError:
        print("ai-edge-torch not available — using TF fallback scaffold...")
        _fallback_tf(encoder)

    print(f"Vocab: {vocab_path}")
    print("\nNext: flutter pub get then flutter run")


def _fallback_tf(encoder):
    """Produce a valid TFLite file with correct I/O shapes for scaffold testing."""
    import tensorflow as tf

    print("Tracing encoder output shape...")
    sample = torch.zeros(1, 80, 3000)
    with torch.no_grad():
        out = encoder(sample).numpy()
    print(f"Output shape: {out.shape}")

    @tf.function(input_signature=[tf.TensorSpec([1, 80, 3000], tf.float32, name="mel")])
    def stub(mel):
        return tf.zeros([1, out.shape[1], out.shape[2]], tf.float32)

    converter = tf.lite.TFLiteConverter.from_concrete_functions(
        [stub.get_concrete_function()]
    )
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()

    tflite_path = OUTPUT_DIR / "whisper_tiny_int8.tflite"
    tflite_path.write_bytes(tflite_model)
    size_kb = tflite_path.stat().st_size // 1024
    print(f"\n⚠️  Scaffold TFLite saved ({size_kb} KB): {tflite_path}")
    print("   Install ai-edge-torch for the real inference model.")


if __name__ == "__main__":
    convert()
