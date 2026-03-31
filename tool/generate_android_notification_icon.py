"""Build white-on-transparent notification_icon.png from assets/icon/icon.png."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "icon" / "icon.png"
RES = ROOT / "android" / "app" / "src" / "main" / "res"

# Android status-bar icon sizes (dp -> px at each density, baseline 24dp)
DENSITIES = {
    "drawable-mdpi": 24,
    "drawable-hdpi": 36,
    "drawable-xhdpi": 48,
    "drawable-xxhdpi": 72,
    "drawable-xxxhdpi": 96,
}


def is_foreground(r: int, g: int, b: int) -> bool:
    """White logo only — exclude light teal gradient (sum can exceed 650)."""
    mx, mn = max(r, g, b), min(r, g, b)
    chroma = mx - mn
    if mn >= 220 and chroma <= 28:
        return True
    if mn >= 235:
        return True
    return False


def foreground_bbox(im: Image.Image, pad: int) -> tuple[int, int, int, int]:
    """Tight crop around logo so downsizing preserves the silhouette."""
    w, h = im.size
    px = im.load()
    min_x, min_y, max_x, max_y = w, h, 0, 0
    found = False
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 16:
                continue
            if not is_foreground(r, g, b):
                continue
            found = True
            min_x = min(min_x, x)
            min_y = min(min_y, y)
            max_x = max(max_x, x)
            max_y = max(max_y, y)
    if not found:
        return 0, 0, w, h
    min_x = max(0, min_x - pad)
    min_y = max(0, min_y - pad)
    max_x = min(w - 1, max_x + pad)
    max_y = min(h - 1, max_y + pad)
    return min_x, min_y, max_x + 1, max_y + 1


def main() -> None:
    im = Image.open(SRC).convert("RGBA")
    x0, y0, x1, y1 = foreground_bbox(im, pad=max(4, min(im.size) // 64))
    cropped = im.crop((x0, y0, x1, y1))

    for folder, size in DENSITIES.items():
        out_dir = RES / folder
        out_dir.mkdir(parents=True, exist_ok=True)
        small = cropped.resize((size, size), Image.Resampling.LANCZOS)
        px = small.load()
        out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        op = out.load()
        for y in range(size):
            for x in range(size):
                r, g, b, a = px[x, y]
                if a < 16:
                    op[x, y] = (0, 0, 0, 0)
                elif is_foreground(r, g, b):
                    op[x, y] = (255, 255, 255, 255)
                else:
                    op[x, y] = (0, 0, 0, 0)
        dest = out_dir / "notification_icon.png"
        out.save(dest)
        print(f"Wrote {dest.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
