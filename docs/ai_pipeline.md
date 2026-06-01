# AgroVerify Edge — AI Model Pipeline Design

**Version:** 1.0  
**Covers:** Voice (Whisper Tiny) + Vision (Commodity Classifier) — both offline, on-device, INT8

---

## Overview

```
┌─────────────────────────────────────────────────────────┐
│                    TRAINING (Cloud / Dev Machine)        │
│                                                         │
│  PyTorch Model Training                                 │
│       ↓                                                 │
│  ONNX Export (opset 17)                                 │
│       ↓                                                 │
│  TensorFlow SavedModel Conversion                       │
│       ↓                                                 │
│  TFLite INT8 Post-Training Quantization                 │
│       ↓                                                 │
│  Benchmark → Package → Upload to Model Manifest API     │
└─────────────────────────────────────────────────────────┘
                         ↓ OTA (when online)
┌─────────────────────────────────────────────────────────┐
│                    ON-DEVICE (Android)                   │
│                                                         │
│  tflite_flutter loads .tflite model                     │
│  Inference → result + confidence score                  │
│  Result logged to ai_inferences table                   │
└─────────────────────────────────────────────────────────┘
```

---

## Model 1 — Voice: Whisper Tiny (Speech-to-Text)

### Purpose
Offline multilingual transcription for transaction field input in Hausa, Igbo, Yoruba, and Nigerian Pidgin English.

### Source Model
- **Model:** OpenAI Whisper Tiny
- **Parameters:** 39M
- **Pretrained checkpoint:** `openai/whisper-tiny` (HuggingFace)

### Pipeline Steps

```
1. Download Whisper Tiny PyTorch checkpoint
        ↓
2. Export encoder + decoder to ONNX (opset 17)
   - Use: optimum.exporters.onnx
        ↓
3. Convert ONNX → TensorFlow SavedModel
   - Use: onnx-tf
        ↓
4. Apply INT8 Post-Training Quantization
   - Use: tf.lite.TFLiteConverter
   - Representative dataset: 100 audio samples per language
        ↓
5. Export: whisper_tiny_int8.tflite (~40MB)
        ↓
6. Benchmark on target device (Snapdragon 665, 4GB RAM)
   - Target: < 3s for 10s audio clip
        ↓
7. Package with metadata (language list, version, checksum)
```

### Input / Output Contract
| | Format |
|---|---|
| Input | Float32 mel-spectrogram, shape [1, 80, 3000] |
| Output | Int32 token IDs → decoded string via tokenizer |
| Languages | ha (Hausa), ig (Igbo), yo (Yoruba), pcm (Pidgin) |

### On-Device Integration (Flutter)
```dart
// tflite_flutter usage pattern
final interpreter = await Interpreter.fromAsset('whisper_tiny_int8.tflite');
interpreter.run(melSpectrogram, outputTokens);
final text = whisperTokenizer.decode(outputTokens);
```

### Latency Targets
| Device Class | Target |
|---|---|
| 4GB RAM, Snapdragon 665 | < 3s for 10s audio |
| 2GB RAM, Snapdragon 460 | < 5s for 10s audio |

---

## Model 2 — Vision: Commodity Image Classifier

### Purpose
On-device classification of commodity photos to verify the declared commodity type matches the captured image.

### Architecture
- **Base:** EfficientNet-Lite0 (MobileNetV3 fallback)
- **Output classes:** 10 commodity types
- **Input size:** 224 × 224 × 3 (RGB)

### Commodity Classes
```
0: maize       5: groundnuts
1: cassava     6: yam
2: sorghum     7: millet
3: rice        8: cocoa
4: soy         9: palm_oil
```

### Dataset Requirements
| Requirement | Target |
|---|---|
| Images per class | ≥ 500 |
| Total images | ≥ 5,000 |
| Sources | Field photos + PlantVillage + custom capture |
| Augmentations | Rotation, brightness, crop, blur (outdoor conditions) |

### Pipeline Steps

```
1. Curate dataset (≥500 images × 10 classes)
   - Split: 80% train / 10% val / 10% test
        ↓
2. Train EfficientNet-Lite0 in PyTorch
   - Transfer learning from ImageNet pretrained weights
   - Fine-tune final 2 layers first, then full model
   - Loss: CrossEntropyLoss
   - Optimizer: AdamW, lr=1e-4, weight_decay=1e-2
   - Epochs: 30, early stopping on val accuracy
        ↓
3. Evaluate: target > 85% top-1 accuracy on test set
        ↓
4. Export to ONNX (opset 17)
   torch.onnx.export(model, dummy_input, "classifier.onnx")
        ↓
5. Convert ONNX → TensorFlow SavedModel
   onnx_tf.backend.prepare(model).export_graph("saved_model/")
        ↓
6. INT8 Post-Training Quantization
   converter = tf.lite.TFLiteConverter.from_saved_model(...)
   converter.optimizations = [tf.lite.Optimize.DEFAULT]
   converter.representative_dataset = representative_dataset_gen
   converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
        ↓
7. Export: commodity_classifier_int8.tflite (~6MB)
        ↓
8. Benchmark on target device
   - Target: < 2s inference, < 5% accuracy drop vs float32
        ↓
9. Package with metadata (class labels, version, checksum)
```

### On-Device Integration (Flutter)
```dart
// tflite_flutter usage pattern
final interpreter = await Interpreter.fromAsset('commodity_classifier_int8.tflite');
final input = preprocessImage(image); // resize to 224x224, normalize
final output = List.filled(10, 0.0).reshape([1, 10]);
interpreter.run(input, output);
final classIndex = output[0].indexOf(output[0].reduce(max));
final confidence = output[0][classIndex];
```

### Latency Targets
| Device Class | Target |
|---|---|
| 4GB RAM, Snapdragon 665 | < 2s |
| 2GB RAM, Snapdragon 460 | < 3s |

---

## Model Budget

| Model | Size (INT8) | RAM at Inference |
|---|---|---|
| Whisper Tiny | ~40MB | ~120MB |
| Commodity Classifier | ~6MB | ~20MB |
| **Total** | **~46MB** | **~140MB** |

✅ Within 50MB storage budget (F-AI requirement)
✅ Within 200MB RAM budget (NF-PERF-05)

---

## OTA Update Flow

```
1. Device connects to internet
2. WorkManager triggers OTA check job
3. GET /api/v1/models/latest → returns {model_type, version, url, checksum}
4. Compare version with locally stored model_version in SQLite
5. If newer: download .tflite to temp file
6. Verify SHA-256 checksum against manifest
7. If checksum matches: swap model file, update model_version in SQLite
8. If checksum fails: delete temp file, keep old model, log error
9. All ai_inferences records log model_version used
```

---

## Toolchain Summary

| Step | Tool | Version |
|---|---|---|
| Training | PyTorch | 2.3+ |
| ONNX export | torch.onnx / optimum | latest |
| ONNX → TF | onnx-tf | 1.10+ |
| TFLite conversion | TensorFlow | 2.16+ |
| On-device runtime | tflite_flutter | 0.10.4 |
| Audio preprocessing | librosa (training) / flutter_sound (device) | — |
| Image preprocessing | torchvision (training) / image (device) | — |

See [ai-models/requirements.txt](../ai-models/requirements.txt) for pinned versions.
