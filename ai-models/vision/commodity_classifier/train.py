"""
Commodity Image Classifier Training
Architecture: EfficientNet-Lite (MobileNetV3 fallback)
Target: >= 85% top-1 accuracy, < 2s inference on mid-range Android
"""

import torch
import torch.nn as nn
import torchvision.transforms as transforms
import torchvision.datasets as datasets
import torchvision.models as models
from torch.utils.data import DataLoader
from pathlib import Path

COMMODITY_CLASSES = [
    "maize", "cassava", "sorghum", "rice", "soy",
    "groundnuts", "yam", "millet", "cocoa", "palm_oil",
]
NUM_CLASSES = len(COMMODITY_CLASSES)
BATCH_SIZE = 32
EPOCHS = 30
IMG_SIZE = 224
DATASET_DIR = Path("datasets/commodity_images")
MODEL_OUT = Path("checkpoints/commodity_classifier.pt")

train_transform = transforms.Compose([
    transforms.RandomResizedCrop(IMG_SIZE),
    transforms.RandomHorizontalFlip(),
    transforms.ColorJitter(brightness=0.3, contrast=0.3, saturation=0.3),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
])

val_transform = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(IMG_SIZE),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
])


def build_model() -> nn.Module:
    # MobileNetV3-Small: fast, accurate, quantization-friendly
    model = models.mobilenet_v3_small(weights=models.MobileNet_V3_Small_Weights.DEFAULT)
    model.classifier[-1] = nn.Linear(model.classifier[-1].in_features, NUM_CLASSES)
    return model


def train():
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Training on: {device}")

    train_dataset = datasets.ImageFolder(DATASET_DIR / "train", transform=train_transform)
    val_dataset = datasets.ImageFolder(DATASET_DIR / "val", transform=val_transform)

    train_loader = DataLoader(train_dataset, batch_size=BATCH_SIZE, shuffle=True, num_workers=4)
    val_loader = DataLoader(val_dataset, batch_size=BATCH_SIZE, num_workers=4)

    model = build_model().to(device)
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.AdamW(model.parameters(), lr=1e-3, weight_decay=1e-4)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=EPOCHS)

    best_acc = 0.0
    for epoch in range(EPOCHS):
        model.train()
        for images, labels in train_loader:
            images, labels = images.to(device), labels.to(device)
            optimizer.zero_grad()
            loss = criterion(model(images), labels)
            loss.backward()
            optimizer.step()

        # Validation
        model.eval()
        correct = total = 0
        with torch.no_grad():
            for images, labels in val_loader:
                images, labels = images.to(device), labels.to(device)
                preds = model(images).argmax(dim=1)
                correct += (preds == labels).sum().item()
                total += labels.size(0)

        acc = correct / total
        print(f"Epoch {epoch+1}/{EPOCHS}  val_acc={acc:.4f}")
        scheduler.step()

        if acc > best_acc:
            best_acc = acc
            MODEL_OUT.parent.mkdir(parents=True, exist_ok=True)
            torch.save(model.state_dict(), MODEL_OUT)
            print(f"  Saved best model (acc={best_acc:.4f})")

    print(f"Training complete. Best val accuracy: {best_acc:.4f}")


if __name__ == "__main__":
    train()
