#!/usr/bin/env python3
"""
Hybrid screenshot useful-zone cropper.

Method:
1) Deterministic: remove black borders and find high-saliency content interval.
2) Visual AI signal: use OCR boxes (Tesseract) to refine the useful area.
3) Hybrid selection with deterministic fallback.

Outputs:
- Cropped images in output directory.
- crop-metadata.json with bbox, confidence, method, and checks.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import numpy as np
import pytesseract
from PIL import Image


@dataclass
class BBox:
    x: int
    y: int
    w: int
    h: int

    @property
    def x2(self) -> int:
        return self.x + self.w

    @property
    def y2(self) -> int:
        return self.y + self.h

    @property
    def area(self) -> int:
        return max(0, self.w) * max(0, self.h)

    def clamp(self, width: int, height: int) -> "BBox":
        x = max(0, min(self.x, width - 1))
        y = max(0, min(self.y, height - 1))
        x2 = max(x + 1, min(self.x2, width))
        y2 = max(y + 1, min(self.y2, height))
        return BBox(x, y, x2 - x, y2 - y)

    def expand(self, px: int, py: int, width: int, height: int) -> "BBox":
        return BBox(self.x - px, self.y - py, self.w + (2 * px), self.h + (2 * py)).clamp(
            width, height
        )

    def to_dict(self) -> dict:
        return {"x": self.x, "y": self.y, "w": self.w, "h": self.h}


def bbox_from_mask(mask: np.ndarray) -> BBox | None:
    ys, xs = np.where(mask)
    if len(xs) == 0 or len(ys) == 0:
        return None
    x0, x1 = int(xs.min()), int(xs.max()) + 1
    y0, y1 = int(ys.min()), int(ys.max()) + 1
    return BBox(x0, y0, x1 - x0, y1 - y0)


def gray_from_rgb(img: np.ndarray) -> np.ndarray:
    return (
        0.299 * img[:, :, 0].astype(np.float32)
        + 0.587 * img[:, :, 1].astype(np.float32)
        + 0.114 * img[:, :, 2].astype(np.float32)
    )


def edge_strength(gray: np.ndarray) -> np.ndarray:
    gx = np.abs(np.diff(gray, axis=1))
    gy = np.abs(np.diff(gray, axis=0))
    gx = np.pad(gx, ((0, 0), (0, 1)), mode="edge")
    gy = np.pad(gy, ((0, 1), (0, 0)), mode="edge")
    e = gx + gy
    vmax = float(np.percentile(e, 99.0))
    if vmax <= 0.0:
        return np.zeros_like(e)
    return np.clip(e / vmax, 0.0, 1.0)


def min_interval_for_mass(
    scores: np.ndarray, mass_target: float, min_width: int, max_width: int
) -> tuple[int, int]:
    n = len(scores)
    if n <= 1:
        return 0, max(1, n)

    csum = np.zeros(n + 1, dtype=np.float64)
    csum[1:] = np.cumsum(scores.astype(np.float64))
    total = float(csum[-1])

    if total <= 1e-9:
        width = max(min_width, min(n, int(0.75 * n)))
        start = max(0, (n - width) // 2)
        return start, start + width

    target = mass_target * total
    best = (0, n)
    best_width = n + 1

    j = 0
    for i in range(n):
        if j < i:
            j = i
        while j < n and (csum[j + 1] - csum[i]) < target:
            j += 1
        if j >= n:
            break
        width = j - i + 1
        if width < min_width or width > max_width:
            continue
        if width < best_width:
            best = (i, j + 1)
            best_width = width

    if best_width <= n:
        return best

    width = max(min_width, min(max_width, int(0.8 * n)))
    start = max(0, (n - width) // 2)
    return start, start + width


def ocr_boxes(pil_img: Image.Image, min_conf: int = 35) -> list[BBox]:
    data = pytesseract.image_to_data(
        pil_img, output_type=pytesseract.Output.DICT, config="--psm 11"
    )
    out: list[BBox] = []
    n = len(data["text"])
    for i in range(n):
        txt = (data["text"][i] or "").strip()
        conf_raw = data["conf"][i]
        try:
            conf = int(float(conf_raw))
        except ValueError:
            conf = -1
        if not txt or conf < min_conf:
            continue
        x, y, w, h = (
            int(data["left"][i]),
            int(data["top"][i]),
            int(data["width"][i]),
            int(data["height"][i]),
        )
        if w <= 1 or h <= 1:
            continue
        out.append(BBox(x, y, w, h))
    return out


def union_boxes(boxes: Iterable[BBox]) -> BBox | None:
    boxes = list(boxes)
    if not boxes:
        return None
    x0 = min(b.x for b in boxes)
    y0 = min(b.y for b in boxes)
    x1 = max(b.x2 for b in boxes)
    y1 = max(b.y2 for b in boxes)
    return BBox(x0, y0, x1 - x0, y1 - y0)


def iou(a: BBox, b: BBox) -> float:
    xi1, yi1 = max(a.x, b.x), max(a.y, b.y)
    xi2, yi2 = min(a.x2, b.x2), min(a.y2, b.y2)
    iw, ih = max(0, xi2 - xi1), max(0, yi2 - yi1)
    inter = iw * ih
    union = a.area + b.area - inter
    if union <= 0:
        return 0.0
    return inter / union


def box_mean(arr: np.ndarray, b: BBox) -> float:
    if b.w <= 0 or b.h <= 0:
        return 0.0
    return float(np.mean(arr[b.y : b.y2, b.x : b.x2]))


def center_expand_bbox(
    saliency: np.ndarray,
    dark_mask: np.ndarray,
    max_box: BBox,
    min_seed_w_frac: float = 0.38,
    min_seed_h_frac: float = 0.42,
    step_w_frac: float = 0.02,
    step_h_frac: float = 0.02,
) -> BBox:
    h, w = saliency.shape
    sx = max_box.x + int((1.0 - min_seed_w_frac) * max_box.w / 2.0)
    sy = max_box.y + int((1.0 - min_seed_h_frac) * max_box.h / 2.0)
    sw = max(2, int(min_seed_w_frac * max_box.w))
    sh = max(2, int(min_seed_h_frac * max_box.h))
    b = BBox(sx, sy, sw, sh).clamp(w, h)

    step_w = max(2, int(step_w_frac * w))
    step_h = max(2, int(step_h_frac * h))
    global_sal = float(np.mean(saliency[max_box.y : max_box.y2, max_box.x : max_box.x2])) + 1e-6

    def accept(strip: BBox) -> bool:
        strip_sal = box_mean(saliency, strip)
        strip_dark = box_mean(dark_mask, strip)
        if strip_dark > 0.90 and strip_sal < (0.70 * global_sal):
            return False
        if strip_sal >= (0.33 * global_sal):
            return True
        if strip_dark <= 0.58:
            return True
        return False

    changed = True
    while changed:
        changed = False

        # left
        if b.x > max_box.x:
            nx = max(max_box.x, b.x - step_w)
            strip = BBox(nx, b.y, b.x - nx, b.h)
            if strip.w > 0 and accept(strip):
                b = BBox(nx, b.y, b.x2 - nx, b.h)
                changed = True

        # right
        if b.x2 < max_box.x2:
            nx2 = min(max_box.x2, b.x2 + step_w)
            strip = BBox(b.x2, b.y, nx2 - b.x2, b.h)
            if strip.w > 0 and accept(strip):
                b = BBox(b.x, b.y, nx2 - b.x, b.h)
                changed = True

        # up
        if b.y > max_box.y:
            ny = max(max_box.y, b.y - step_h)
            strip = BBox(b.x, ny, b.w, b.y - ny)
            if strip.h > 0 and accept(strip):
                b = BBox(b.x, ny, b.w, b.y2 - ny)
                changed = True

        # down
        if b.y2 < max_box.y2:
            ny2 = min(max_box.y2, b.y2 + step_h)
            strip = BBox(b.x, b.y2, b.w, ny2 - b.y2)
            if strip.h > 0 and accept(strip):
                b = BBox(b.x, b.y, b.w, ny2 - b.y)
                changed = True

    return b.clamp(w, h)


def hybrid_crop(
    pil_img: Image.Image,
    mass_target: float = 0.92,
    min_w_frac: float = 0.55,
    min_h_frac: float = 0.45,
) -> tuple[BBox, dict]:
    rgb = np.array(pil_img.convert("RGB"))
    h, w = rgb.shape[:2]

    non_black = np.any(rgb > 18, axis=2)
    nb = bbox_from_mask(non_black) or BBox(0, 0, w, h)
    nb = nb.clamp(w, h)

    crop = rgb[nb.y : nb.y2, nb.x : nb.x2]
    ch, cw = crop.shape[:2]

    gray = gray_from_rgb(crop)
    edges = edge_strength(gray)

    # OCR as visual AI signal
    crop_pil = Image.fromarray(crop)
    text_boxes = ocr_boxes(crop_pil, min_conf=35)
    text_mask = np.zeros((ch, cw), dtype=np.float32)
    for tb in text_boxes:
        x1 = max(0, min(tb.x, cw - 1))
        y1 = max(0, min(tb.y, ch - 1))
        x2 = max(x1 + 1, min(tb.x2, cw))
        y2 = max(y1 + 1, min(tb.y2, ch))
        text_mask[y1:y2, x1:x2] = 1.0

    saliency = (0.65 * edges) + (1.8 * text_mask)
    col_scores = saliency.sum(axis=0)
    row_scores = saliency.sum(axis=1)

    # Deterministic trim: detect right-side conference panel using continuous
    # dark columns + low saliency. This produces a hard cutoff that AI
    # refinement must respect.
    left_ref = float(np.mean(col_scores[: max(1, int(0.55 * cw))])) + 1e-6
    # Compute darkness on the center/lower band to avoid browser top-bar noise.
    y0 = int(0.14 * ch)
    y1 = int(0.94 * ch)
    band = gray[y0:y1, :] if y1 > y0 else gray
    dark_col_ratio = np.mean(band < 52.0, axis=0)  # per-column darkness
    panel_cut_local = None
    dark_idx = np.where(dark_col_ratio > 0.88)[0]
    if dark_idx.size > 0:
        run_start = int(dark_idx[0])
        prev = int(dark_idx[0])
        best_start, best_end = run_start, prev
        for i in dark_idx[1:]:
            i = int(i)
            if i == prev + 1:
                prev = i
            else:
                if (prev - run_start) > (best_end - best_start):
                    best_start, best_end = run_start, prev
                run_start, prev = i, i
        if (prev - run_start) > (best_end - best_start):
            best_start, best_end = run_start, prev

        run_len = best_end - best_start + 1
        if best_start >= int(0.62 * cw) and run_len >= int(0.08 * cw):
            # Move a few px left to avoid keeping panel edge.
            panel_cut_local = max(0, best_start - int(0.01 * cw))
    if panel_cut_local is not None:
        col_scores[panel_cut_local:] = 0.0

    min_w = max(1, int(min_w_frac * cw))
    min_h = max(1, int(min_h_frac * ch))
    xs, xe = min_interval_for_mass(col_scores, mass_target, min_width=min_w, max_width=cw)
    ys, ye = min_interval_for_mass(row_scores, mass_target, min_width=min_h, max_width=ch)
    det_mass = BBox(nb.x + xs, nb.y + ys, xe - xs, ye - ys).clamp(w, h)

    # New deterministic core: start at center and expand until marginal utility fails.
    expand_bounds = nb
    if panel_cut_local is not None:
        expand_bounds = BBox(nb.x, nb.y, max(1, panel_cut_local), nb.h).clamp(w, h)
    dark_mask = (gray < 52.0).astype(np.float32)
    det_expand_local = center_expand_bbox(
        saliency,
        dark_mask,
        BBox(expand_bounds.x - nb.x, expand_bounds.y - nb.y, expand_bounds.w, expand_bounds.h),
    )
    det_expand = BBox(
        nb.x + det_expand_local.x,
        nb.y + det_expand_local.y,
        det_expand_local.w,
        det_expand_local.h,
    ).clamp(w, h)

    # Prefer center-expansion unless it is clearly too small.
    det = det_expand
    if det.area < int(0.62 * det_mass.area):
        det = det_mass

    ai_union_local = union_boxes(text_boxes)
    ai_used = False
    method = "deterministic"
    final = det
    ai_score = 0.0

    if ai_union_local is not None and len(text_boxes) >= 6:
        # Ignore OCR boxes that are likely in the right panel.
        if panel_cut_local is not None:
            filtered = [b for b in text_boxes if b.x2 <= panel_cut_local]
            if len(filtered) >= 4:
                ai_union_local = union_boxes(filtered)

        ai_global = BBox(
            nb.x + ai_union_local.x,
            nb.y + ai_union_local.y,
            ai_union_local.w,
            ai_union_local.h,
        ).expand(px=int(0.03 * w), py=int(0.04 * h), width=w, height=h)
        overlap = iou(det, ai_global)
        ai_score = min(1.0, (len(text_boxes) / 35.0)) * min(1.0, overlap + 0.35)
        if ai_global.area > int(0.15 * det.area):
            final = union_boxes([det, ai_global]) or det
            final = final.clamp(w, h)
            ai_used = True
            method = "hybrid"

    # Enforce hard right cutoff if a right conference panel was detected.
    if panel_cut_local is not None:
        max_x2 = nb.x + panel_cut_local
        if final.x2 > max_x2:
            final = BBox(final.x, final.y, max(1, max_x2 - final.x), final.h).clamp(w, h)

    # Final sanity padding and clamp.
    final = final.expand(px=int(0.008 * w), py=int(0.01 * h), width=w, height=h)
    if final.w < int(0.30 * w) or final.h < int(0.30 * h):
        final = nb
        method = "fallback_non_black"
        ai_used = False

    # Confidence combines OCR and edge richness.
    edge_density = float(np.mean(edges))
    text_density = float(np.mean(text_mask))
    confidence = min(0.99, 0.40 + (0.35 * min(1.0, edge_density * 2.2)) + (0.24 * min(1.0, text_density * 12.0)))
    if method == "fallback_non_black":
        confidence *= 0.75

    meta = {
        "method": method,
        "ai_used": ai_used,
        "confidence": round(confidence, 4),
        "ai_score": round(ai_score, 4),
        "checks": {
            "has_text": len(text_boxes) > 0,
            "text_boxes_count": len(text_boxes),
            "edge_density": round(edge_density, 4),
            "text_density": round(text_density, 4),
            "right_panel_cut_detected": panel_cut_local is not None,
        },
        "non_black_bbox": nb.to_dict(),
        "deterministic_bbox": det.to_dict(),
        "deterministic_mass_bbox": det_mass.to_dict(),
        "deterministic_expand_bbox": det_expand.to_dict(),
    }
    return final, meta


def collect_images(input_dir: Path, pattern: str) -> list[Path]:
    return sorted([p for p in input_dir.glob(pattern) if p.is_file()])


def main() -> None:
    parser = argparse.ArgumentParser(description="Crop useful area from screenshots (hybrid deterministic + OCR).")
    parser.add_argument("--input-dir", required=True, help="Directory containing screenshots.")
    parser.add_argument("--output-dir", help="Directory to write cropped screenshots.")
    parser.add_argument(
        "--in-place",
        action="store_true",
        help="Overwrite valid screenshots in input-dir instead of writing to a separate folder.",
    )
    parser.add_argument("--pattern", default="*.png", help="Glob pattern inside input-dir (default: *.png).")
    parser.add_argument("--mass-target", type=float, default=0.92, help="Saliency mass target for interval selection.")
    parser.add_argument("--min-w-frac", type=float, default=0.55, help="Minimum crop width fraction.")
    parser.add_argument("--min-h-frac", type=float, default=0.45, help="Minimum crop height fraction.")
    args = parser.parse_args()

    input_dir = Path(args.input_dir)
    if args.in_place:
        output_dir = input_dir
    else:
        if not args.output_dir:
            raise SystemExit("Either --output-dir or --in-place is required.")
        output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    images = collect_images(input_dir, args.pattern)
    if not images:
        raise SystemExit(f"No images matched pattern '{args.pattern}' in {input_dir}")

    results = []
    for img_path in images:
        pil = Image.open(img_path)
        bbox, meta = hybrid_crop(
            pil,
            mass_target=args.mass_target,
            min_w_frac=args.min_w_frac,
            min_h_frac=args.min_h_frac,
        )
        cropped = pil.crop((bbox.x, bbox.y, bbox.x2, bbox.y2))
        out_path = output_dir / img_path.name
        cropped.save(out_path)

        results.append(
            {
                "file": img_path.name,
                "input_path": str(img_path),
                "output_path": str(out_path),
                "image_size": {"w": pil.width, "h": pil.height},
                "crop_box": bbox.to_dict(),
                "crop_ratio": round((bbox.area / float(pil.width * pil.height)), 4),
                **meta,
            }
        )

    metadata_path = output_dir / "crop-metadata.json"
    with metadata_path.open("w", encoding="utf-8") as f:
        json.dump({"count": len(results), "items": results}, f, ensure_ascii=False, indent=2)

    print(f"Processed {len(results)} images")
    print(f"Cropped output: {output_dir}")
    print(f"Metadata: {metadata_path}")


if __name__ == "__main__":
    main()
