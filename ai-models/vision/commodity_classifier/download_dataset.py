"""
Commodity image dataset downloader for AgroVerify Edge.

Sources:
  1. iNaturalist API — research-grade, CC-licensed field observations (primary)
  2. Bing image crawl via icrawler — West African context keywords (supplement)

Output layout (matches train.py ImageFolder expectation):
  datasets/commodity_images/
    raw/<class>/          all downloaded images
    train/<class>/        70%
    val/<class>/          20%
    test/<class>/         10%

Usage:
  python download_dataset.py                   # 600 images/class (default)
  python download_dataset.py --per-class 400   # faster, lighter run
  python download_dataset.py --split-only      # re-split existing raw images
"""

import argparse
import hashlib
import io
import random
import shutil
import time
from pathlib import Path

import requests
from PIL import Image
from tqdm import tqdm

# ---------------------------------------------------------------------------
# Class definitions: iNaturalist taxon name + Bing search keywords
# ---------------------------------------------------------------------------
CLASSES = {
    "maize": {
        "taxon": "Zea mays",
        "keywords": [
            "maize corn crop field Nigeria harvest",
            "corn cob farm West Africa market",
        ],
    },
    "cassava": {
        "taxon": "Manihot esculenta",
        "keywords": [
            "cassava tuber crop Nigeria farm",
            "cassava root West Africa harvest",
        ],
    },
    "sorghum": {
        "taxon": "Sorghum bicolor",
        "keywords": [
            "sorghum guinea corn crop field Nigeria",
            "sorghum grain harvest West Africa",
        ],
    },
    "rice": {
        "taxon": "Oryza sativa",
        "keywords": [
            "rice paddy field Nigeria harvest",
            "rice grain bag West Africa market",
        ],
    },
    "soy": {
        "taxon": "Glycine max",
        "keywords": [
            "soybean crop field Nigeria harvest",
            "soya beans West Africa farm",
        ],
    },
    "groundnuts": {
        "taxon": "Arachis hypogaea",
        "keywords": [
            "groundnut peanut crop Nigeria farm",
            "groundnut pile market West Africa",
        ],
    },
    "yam": {
        "taxon": "Dioscorea rotundata",
        "keywords": [
            "yam tuber Nigeria market pile",
            "white yam West Africa farm harvest",
        ],
    },
    "millet": {
        "taxon": "Pennisetum glaucum",
        "keywords": [
            "pearl millet crop field Nigeria harvest",
            "millet grain bag West Africa",
        ],
    },
    "cocoa": {
        "taxon": "Theobroma cacao",
        "keywords": [
            "cocoa pod farm Nigeria harvest",
            "cacao fruit West Africa plantation",
        ],
    },
    "palm_oil": {
        "taxon": "Elaeis guineensis",
        "keywords": [
            "oil palm fresh fruit bunch Nigeria",
            "palm oil bunch West Africa harvest",
        ],
    },
}

# ---------------------------------------------------------------------------
# Paths and constants
# ---------------------------------------------------------------------------
DATASET_DIR = Path("datasets/commodity_images")
RAW_DIR = DATASET_DIR / "raw"

MIN_EDGE_PX = 150       # discard images smaller than this
INATURALIST_URL = "https://api.inaturalist.org/v1/observations"
TRAIN_RATIO = 0.70
VAL_RATIO = 0.20        # test = remaining 10%


# ---------------------------------------------------------------------------
# iNaturalist download
# ---------------------------------------------------------------------------

def _inaturalist_urls(taxon_name: str, target: int) -> list[str]:
    """Return up to target*2 photo URLs from iNaturalist (research-grade, CC)."""
    urls: list[str] = []
    page = 1
    while len(urls) < target * 2:
        try:
            resp = requests.get(
                INATURALIST_URL,
                params={
                    "taxon_name": taxon_name,
                    "quality_grade": "research",
                    "photos": "true",
                    "photo_license": "cc-by,cc-by-sa,cc0,cc-by-nc,cc-by-nc-sa",
                    "per_page": 200,
                    "page": page,
                    "order_by": "votes",
                },
                timeout=20,
            )
            resp.raise_for_status()
            results = resp.json().get("results", [])
            if not results:
                break
            for obs in results:
                for photo in obs.get("photos", []):
                    url = photo.get("url", "")
                    if url:
                        # prefer medium over square thumbnail
                        urls.append(url.replace("/square.", "/medium."))
            page += 1
            time.sleep(0.4)   # stay within rate limit (~100 req/min)
        except Exception as exc:
            print(f"    iNaturalist error (page {page}): {exc}")
            break
    return urls


def _download_one(url: str, dest: Path) -> bool:
    """Download, validate, and save a single image. Returns True on success."""
    try:
        resp = requests.get(url, timeout=12, stream=True)
        resp.raise_for_status()
        img = Image.open(io.BytesIO(resp.content)).convert("RGB")
        if min(img.size) < MIN_EDGE_PX:
            return False
        img.save(dest, "JPEG", quality=90)
        return True
    except Exception:
        return False


# ---------------------------------------------------------------------------
# Bing image supplement (icrawler)
# ---------------------------------------------------------------------------

def _bing_supplement(keyword: str, out_dir: Path, count: int, timeout: int = 120) -> None:
    """Download `count` images from Bing for `keyword` into `out_dir`.
    Hard timeout prevents icrawler hanging indefinitely."""
    import threading

    def _crawl():
        try:
            from icrawler.builtin import BingImageCrawler
            crawler = BingImageCrawler(
                downloader_threads=2,
                storage={"root_dir": str(out_dir)},
            )
            crawler.crawl(
                keyword=keyword,
                max_num=count,
                min_size=(MIN_EDGE_PX, MIN_EDGE_PX),
            )
        except ImportError:
            print("    icrawler not found — run: pip install icrawler")
        except Exception as exc:
            print(f"    Bing crawl error: {exc}")

    t = threading.Thread(target=_crawl, daemon=True)
    t.start()
    t.join(timeout=timeout)
    if t.is_alive():
        print(f"    Bing crawl timed out after {timeout}s — continuing with iNaturalist images only")


# ---------------------------------------------------------------------------
# Deduplication
# ---------------------------------------------------------------------------

def _deduplicate(directory: Path) -> int:
    """Remove duplicate images by MD5 hash. Returns count removed."""
    seen: set[str] = set()
    removed = 0
    for f in sorted(directory.iterdir()):
        if f.suffix.lower() not in {".jpg", ".jpeg", ".png", ".webp"}:
            continue
        digest = hashlib.md5(f.read_bytes()).hexdigest()
        if digest in seen:
            f.unlink()
            removed += 1
        else:
            seen.add(digest)
    return removed


# ---------------------------------------------------------------------------
# Per-class download
# ---------------------------------------------------------------------------

def download_class(class_name: str, meta: dict, per_class: int) -> None:
    raw_dir = RAW_DIR / class_name
    raw_dir.mkdir(parents=True, exist_ok=True)

    existing = [f for f in raw_dir.iterdir() if f.suffix.lower() in {".jpg", ".jpeg", ".png"}]
    if len(existing) >= per_class:
        print(f"  {class_name}: {len(existing)} images already present — skipping")
        return

    needed = per_class - len(existing)

    # --- Step 1: iNaturalist ---
    print(f"  Querying iNaturalist for '{meta['taxon']}'...")
    urls = _inaturalist_urls(meta["taxon"], needed)
    print(f"  {len(urls)} candidate URLs found")

    downloaded = len(existing)
    for i, url in enumerate(tqdm(urls, desc=f"  {class_name} [iNat]", unit="img", leave=False)):
        if downloaded >= per_class:
            break
        dest = raw_dir / f"inat_{i:05d}.jpg"
        if dest.exists():
            downloaded += 1
            continue
        if _download_one(url, dest):
            downloaded += 1

    # --- Step 2: Bing supplement ---
    if downloaded < per_class:
        shortfall = per_class - downloaded
        print(f"  {shortfall} short — supplementing with Bing...")
        per_keyword = max(1, shortfall // len(meta["keywords"]) + 1)
        for keyword in meta["keywords"]:
            _bing_supplement(keyword, raw_dir, per_keyword)

    dupes = _deduplicate(raw_dir)
    final = len([f for f in raw_dir.iterdir() if f.suffix.lower() in {".jpg", ".jpeg", ".png"}])
    print(f"  {class_name}: {final} unique images ({dupes} dupes removed)")


# ---------------------------------------------------------------------------
# Dataset split
# ---------------------------------------------------------------------------

def split_class(class_name: str) -> dict[str, int]:
    raw_dir = RAW_DIR / class_name
    images = [
        f for f in raw_dir.iterdir()
        if f.suffix.lower() in {".jpg", ".jpeg", ".png"}
    ]
    random.shuffle(images)

    n = len(images)
    n_train = int(n * TRAIN_RATIO)
    n_val = int(n * VAL_RATIO)
    splits = {
        "train": images[:n_train],
        "val": images[n_train:n_train + n_val],
        "test": images[n_train + n_val:],
    }

    for split_name, files in splits.items():
        dest_dir = DATASET_DIR / split_name / class_name
        dest_dir.mkdir(parents=True, exist_ok=True)
        # remove stale files from a previous split
        for old in dest_dir.iterdir():
            old.unlink()
        for f in files:
            shutil.copy2(f, dest_dir / f.name)

    return {k: len(v) for k, v in splits.items()}


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main(per_class: int, split_only: bool) -> None:
    random.seed(42)
    print(f"AgroVerify Dataset Builder")
    print(f"  Classes : {len(CLASSES)}")
    print(f"  Target  : {per_class} images/class")
    print(f"  Output  : {DATASET_DIR.resolve()}\n")

    if not split_only:
        for class_name, meta in CLASSES.items():
            print(f"\n[{class_name}]")
            download_class(class_name, meta, per_class)

    print("\nSplitting into train / val / test...")
    totals: dict[str, int] = {"train": 0, "val": 0, "test": 0}
    for class_name in CLASSES:
        raw_count = len([
            f for f in (RAW_DIR / class_name).iterdir()
            if f.suffix.lower() in {".jpg", ".jpeg", ".png"}
        ]) if (RAW_DIR / class_name).exists() else 0

        if raw_count == 0:
            print(f"  {class_name}: no raw images — skipping")
            continue

        counts = split_class(class_name)
        totals = {k: totals[k] + counts[k] for k in totals}
        print(f"  {class_name:12s}  train={counts['train']:4d}  val={counts['val']:4d}  test={counts['test']:4d}")

    print(f"\nDataset summary:")
    print(f"  train : {totals['train']:5d} images")
    print(f"  val   : {totals['val']:5d} images")
    print(f"  test  : {totals['test']:5d} images")
    print(f"  total : {sum(totals.values()):5d} images\n")
    print("Next step: python train.py")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Download AgroVerify commodity image dataset")
    parser.add_argument(
        "--per-class", type=int, default=600,
        help="Target images per class (default: 600, minimum recommended: 400)",
    )
    parser.add_argument(
        "--split-only", action="store_true",
        help="Skip download — only re-split existing raw images into train/val/test",
    )
    args = parser.parse_args()
    main(per_class=args.per_class, split_only=args.split_only)
