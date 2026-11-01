#!/usr/bin/env python3
"""
tools/build_studio_vector_sprites.py
Builds studio-grade, ultra-crisp, high-resolution (512x512 native) 2D game sprite sheets
for Rhythm Rhythm v0.3 using 4x Supersampling (SSAA) and mathematical vector geometry.

ZERO low-res crops, ZERO dirty color fringes, 100% transparent RGBA alpha channel.
Faithfully recreates the visual language of the 12 reference panels from v3 art set.
"""
import math
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SPRITES_DIR = ROOT / "assets" / "sprites"

SS = 4  # 4x Supersampling for ultra-crisp anti-aliased vector rendering

# Palette matching the v3 Visual Source of Truth
INK = (24, 22, 36, 255)         # Bold cartoon ink outline #181624
WHITE = (255, 255, 255, 255)
SKIN_PEACH = (254, 224, 195, 255) # Light warm peach skin tone
SKIN_BLUSH = (255, 150, 166, 255) # Rosy pink cheeks
HAIR_BROWN = (74, 46, 24, 255)    # Rich chocolate brown hair
CHEF_BOW = (230, 57, 70, 255)     # Scarlet red ascot bow tie #e63946
CHEF_SKIRT = (37, 99, 235, 255)   # Royal blue apron/skirt #2563eb
WORKER_HELMET = (255, 202, 0, 255)# Vivid construction yellow #ffca00
WORKER_STRIPE = (255, 93, 66, 255)# Orange helmet rim stripe
WORKER_DENIM = (35, 83, 152, 255) # Overalls denim blue #235398
WORKER_BUTTON = (226, 232, 240, 255)
LEVER_RED = (230, 57, 70, 255)    # Bright red lever knob
LEVER_BASE = (90, 94, 106, 255)   # Metallic grey console
ALIEN_CYAN = (112, 197, 213, 255) # Soft space cyan #70c5d5
ALIEN_BELLY = (187, 242, 246, 255)# Pale cyan belly
ALIEN_BULB = (255, 214, 10, 255)  # Glowing golden yellow bulb #ffd60a
ASTRONAUT_SUIT = (255, 255, 255, 255)
ASTRONAUT_VISOR = (30, 28, 50, 255)
ASTRONAUT_GLASS = (180, 225, 255, 140)
SPARKLE_GOLD = (255, 213, 36, 255)

def ensure_dirs():
    for sub in ["", "results", "beat_factory", "echo_planet", "rhythm_kitchen"]:
        (SPRITES_DIR / sub).mkdir(parents=True, exist_ok=True)

def create_ssaa_canvas(w: int, h: int) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    """Creates a high-res RGBA canvas at SSx scale."""
    im = Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    return im, d

def finalize_ssaa(im: Image.Image, w: int, h: int) -> Image.Image:
    """Downsamples with high-quality Lanczos filter to produce crisp anti-aliased RGBA."""
    return im.resize((w, h), resample=Image.Resampling.LANCZOS)

def draw_star(d: ImageDraw.ImageDraw, center: tuple[float, float], r_out: float, r_in: float,
              fill, outline=INK, width: float = 3.5, rot: float = 0.0):
    cx, cy = center
    pts = []
    for i in range(10):
        angle = rot + i * math.pi / 5.0 - math.pi / 2.0
        r = r_out if i % 2 == 0 else r_in
        pts.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    d.polygon(pts, fill=fill)
    if outline and width > 0:
        pts.append(pts[0])
        d.line(pts, fill=outline, width=int(width), joint="curve")

def draw_rounded_box(d: ImageDraw.ImageDraw, xy: list[float], fill, outline=INK, width: float = 4.0, radius: float = 16.0):
    x0, y0, x1, y1 = xy
    r = min(radius, (x1 - x0) / 2.0, (y1 - y0) / 2.0)
    d.rounded_rectangle([x0, y0, x1, y1], radius=int(r), fill=fill)
    if outline and width > 0:
        d.rounded_rectangle([x0, y0, x1, y1], radius=int(r), outline=outline, width=int(width))

def draw_circle(d: ImageDraw.ImageDraw, center: tuple[float, float], radius: float, fill, outline=INK, width: float = 4.0):
    cx, cy = center
    d.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=fill)
    if outline and width > 0:
        d.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], outline=outline, width=int(width))

# =============================================================================
# 1. RESULTS CHEERING TRIO (results/trio_celebration.png, 800x520)
# The 3 main characters celebrating together on the Results screen!
# =============================================================================
def build_results_trio():
    w, h = 800, 520
    im, d = create_ssaa_canvas(w, h)
    s = SS

    # Floor base Y
    base_y = 440 * s

    # -------------------------------------------------------------
    # A. WORKER (Left, Center X = 230 * s)
    # -------------------------------------------------------------
    wx = 230 * s
    wy = base_y

    # Legs & Boots
    d.ellipse([wx - 55 * s, wy - 30 * s, wx - 15 * s, wy + 2 * s], fill=(33, 37, 41, 255), outline=INK, width=int(5 * s))
    d.ellipse([wx + 15 * s, wy - 30 * s, wx + 55 * s, wy + 2 * s], fill=(33, 37, 41, 255), outline=INK, width=int(5 * s))

    # Overalls Body
    draw_rounded_box(d, [wx - 65 * s, wy - 145 * s, wx + 65 * s, wy - 20 * s], fill=WORKER_DENIM, outline=INK, width=5 * s, radius=28 * s)
    # Overalls Straps
    d.line([(wx - 42 * s, wy - 145 * s), (wx - 42 * s, wy - 75 * s)], fill=INK, width=int(14 * s))
    d.line([(wx - 42 * s, wy - 145 * s), (wx - 42 * s, wy - 75 * s)], fill=WORKER_DENIM, width=int(8 * s))
    draw_circle(d, (wx - 42 * s, wy - 75 * s), 7 * s, fill=WORKER_BUTTON, outline=INK, width=3 * s)

    d.line([(wx + 42 * s, wy - 145 * s), (wx + 42 * s, wy - 75 * s)], fill=INK, width=int(14 * s))
    d.line([(wx + 42 * s, wy - 145 * s), (wx + 42 * s, wy - 75 * s)], fill=WORKER_DENIM, width=int(8 * s))
    draw_circle(d, (wx + 42 * s, wy - 75 * s), 7 * s, fill=WORKER_BUTTON, outline=INK, width=3 * s)

    # White Undershirt Shoulders
    d.line([(wx - 58 * s, wy - 130 * s), (wx - 95 * s, wy - 210 * s)], fill=INK, width=int(22 * s))
    d.line([(wx - 58 * s, wy - 130 * s), (wx - 95 * s, wy - 210 * s)], fill=WHITE, width=int(14 * s))
    draw_circle(d, (wx - 95 * s, wy - 210 * s), 16 * s, fill=SKIN_PEACH, outline=INK, width=4 * s)

    d.line([(wx + 58 * s, wy - 130 * s), (wx + 95 * s, wy - 210 * s)], fill=INK, width=int(22 * s))
    d.line([(wx + 58 * s, wy - 130 * s), (wx + 95 * s, wy - 210 * s)], fill=WHITE, width=int(14 * s))
    draw_circle(d, (wx + 95 * s, wy - 210 * s), 16 * s, fill=SKIN_PEACH, outline=INK, width=4 * s)

    # Worker Head
    draw_circle(d, (wx, wy - 195 * s), 58 * s, fill=SKIN_PEACH, outline=INK, width=5 * s)
    # Hair sides
    draw_circle(d, (wx - 54 * s, wy - 190 * s), 16 * s, fill=HAIR_BROWN, outline=INK, width=4 * s)
    draw_circle(d, (wx + 54 * s, wy - 190 * s), 16 * s, fill=HAIR_BROWN, outline=INK, width=4 * s)

    # Face details (Ecstatic Joy)
    # Cheeks
    draw_circle(d, (wx - 36 * s, wy - 180 * s), 11 * s, fill=SKIN_BLUSH, outline=None, width=0)
    draw_circle(d, (wx + 36 * s, wy - 180 * s), 11 * s, fill=SKIN_BLUSH, outline=None, width=0)
    # Happy eyes (crescents)
    d.arc([wx - 42 * s, wy - 212 * s, wx - 18 * s, wy - 188 * s], start=190, end=350, fill=INK, width=int(5 * s))
    d.arc([wx + 18 * s, wy - 212 * s, wx + 42 * s, wy - 188 * s], start=190, end=350, fill=INK, width=int(5 * s))
    # Wide laughing mouth
    d.pieslice([wx - 26 * s, wy - 195 * s, wx + 26 * s, wy - 155 * s], start=0, end=180, fill=CHEF_BOW, outline=INK, width=int(4 * s))
    d.chord([wx - 24 * s, wy - 195 * s, wx + 24 * s, wy - 175 * s], start=0, end=180, fill=WHITE, outline=None)

    # Yellow Safety Helmet
    d.pieslice([wx - 64 * s, wy - 265 * s, wx + 64 * s, wy - 185 * s], start=180, end=360, fill=WORKER_HELMET, outline=INK, width=int(5 * s))
    # Helmet Rim
    draw_rounded_box(d, [wx - 72 * s, wy - 228 * s, wx + 72 * s, wy - 212 * s], fill=WORKER_HELMET, outline=INK, width=4 * s, radius=6 * s)
    # Orange Crest Badge
    draw_rounded_box(d, [wx - 22 * s, wy - 238 * s, wx + 22 * s, wy - 224 * s], fill=WORKER_STRIPE, outline=INK, width=3 * s, radius=4 * s)

    # -------------------------------------------------------------
    # B. ALIEN (Center, Center X = 400 * s, floating slightly)
    # -------------------------------------------------------------
    ax = 400 * s
    ay = base_y - 25 * s  # Floating in joy

    # Arms raised high
    d.line([(ax - 36 * s, ay - 110 * s), (ax - 70 * s, ay - 180 * s)], fill=INK, width=int(16 * s))
    d.line([(ax - 36 * s, ay - 110 * s), (ax - 70 * s, ay - 180 * s)], fill=ALIEN_CYAN, width=int(10 * s))
    draw_circle(d, (ax - 70 * s, ay - 180 * s), 10 * s, fill=ALIEN_CYAN, outline=INK, width=3 * s)

    d.line([(ax + 36 * s, ay - 110 * s), (ax + 70 * s, ay - 180 * s)], fill=INK, width=int(16 * s))
    d.line([(ax + 36 * s, ay - 110 * s), (ax + 70 * s, ay - 180 * s)], fill=ALIEN_CYAN, width=int(10 * s))
    draw_circle(d, (ax + 70 * s, ay - 180 * s), 10 * s, fill=ALIEN_CYAN, outline=INK, width=3 * s)

    # Little legs
    draw_rounded_box(d, [ax - 30 * s, ay - 40 * s, ax - 10 * s, ay], fill=ALIEN_CYAN, outline=INK, width=4 * s, radius=8 * s)
    draw_rounded_box(d, [ax + 10 * s, ay - 40 * s, ax + 30 * s, ay], fill=ALIEN_CYAN, outline=INK, width=4 * s, radius=8 * s)

    # Alien Body
    draw_rounded_box(d, [ax - 46 * s, ay - 120 * s, ax + 46 * s, ay - 25 * s], fill=ALIEN_CYAN, outline=INK, width=5 * s, radius=24 * s)
    # Pale belly patch
    draw_circle(d, (ax, ay - 70 * s), 25 * s, fill=ALIEN_BELLY, outline=None, width=0)

    # Alien Dome Head
    draw_circle(d, (ax, ay - 160 * s), 54 * s, fill=ALIEN_CYAN, outline=INK, width=5 * s)

    # Antenna Stem & Glowing Bulb
    d.line([(ax, ay - 214 * s), (ax, ay - 260 * s)], fill=INK, width=int(10 * s))
    d.line([(ax, ay - 214 * s), (ax, ay - 260 * s)], fill=ALIEN_CYAN, width=int(6 * s))
    # Glowing yellow bulb with star sparkle
    draw_circle(d, (ax, ay - 264 * s), 16 * s, fill=ALIEN_BULB, outline=INK, width=4 * s)
    draw_star(d, (ax, ay - 264 * s), 26 * s, 10 * s, fill=SPARKLE_GOLD, outline=INK, width=3 * s)

    # Face details (Cheering Alien)
    draw_circle(d, (ax - 22 * s, ay - 158 * s), 8 * s, fill=INK, outline=None, width=0)
    draw_circle(d, (ax + 22 * s, ay - 158 * s), 8 * s, fill=INK, outline=None, width=0)
    draw_circle(d, (ax - 20 * s, ay - 161 * s), 3 * s, fill=WHITE, outline=None, width=0)
    draw_circle(d, (ax + 24 * s, ay - 161 * s), 3 * s, fill=WHITE, outline=None, width=0)
    # Open singing mouth
    draw_circle(d, (ax, ay - 140 * s), 8 * s, fill=INK, outline=None, width=0)

    # -------------------------------------------------------------
    # C. CHEF (Right, Center X = 570 * s)
    # -------------------------------------------------------------
    cx = 570 * s
    cy = base_y

    # Chef Skirt / Blue Apron
    draw_rounded_box(d, [cx - 48 * s, cy - 85 * s, cx + 48 * s, cy - 10 * s], fill=CHEF_SKIRT, outline=INK, width=5 * s, radius=16 * s)
    # Little feet
    draw_circle(d, (cx - 24 * s, cy - 5 * s), 14 * s, fill=(33, 37, 41, 255), outline=INK, width=4 * s)
    draw_circle(d, (cx + 24 * s, cy - 5 * s), 14 * s, fill=(33, 37, 41, 255), outline=INK, width=4 * s)

    # Chef White Coat
    draw_rounded_box(d, [cx - 52 * s, cy - 155 * s, cx + 52 * s, cy - 75 * s], fill=WHITE, outline=INK, width=5 * s, radius=20 * s)
    # Red Ascot Bow Tie
    draw_circle(d, (cx, cy - 150 * s), 12 * s, fill=CHEF_BOW, outline=INK, width=3 * s)
    d.polygon([(cx, cy - 150 * s), (cx - 20 * s, cy - 138 * s), (cx - 16 * s, cy - 154 * s)], fill=CHEF_BOW)
    d.polygon([(cx, cy - 150 * s), (cx + 20 * s, cy - 138 * s), (cx + 16 * s, cy - 154 * s)], fill=CHEF_BOW)

    # Chef Arms raised cheering!
    d.line([(cx - 46 * s, cy - 145 * s), (cx - 85 * s, cy - 215 * s)], fill=INK, width=int(20 * s))
    d.line([(cx - 46 * s, cy - 145 * s), (cx - 85 * s, cy - 215 * s)], fill=WHITE, width=int(12 * s))
    draw_circle(d, (cx - 85 * s, cy - 215 * s), 14 * s, fill=SKIN_PEACH, outline=INK, width=4 * s)

    # Right arm holding frying pan high!
    d.line([(cx + 46 * s, cy - 145 * s), (cx + 85 * s, cy - 215 * s)], fill=INK, width=int(20 * s))
    d.line([(cx + 46 * s, cy - 145 * s), (cx + 85 * s, cy - 215 * s)], fill=WHITE, width=int(12 * s))
    draw_circle(d, (cx + 85 * s, cy - 215 * s), 14 * s, fill=SKIN_PEACH, outline=INK, width=4 * s)

    # Frying pan held high in victory
    d.line([(cx + 85 * s, cy - 215 * s), (cx + 120 * s, cy - 250 * s)], fill=INK, width=int(10 * s))
    d.ellipse([cx + 105 * s, cy - 295 * s, cx + 165 * s, cy - 235 * s], fill=(52, 58, 64, 255), outline=INK, width=int(5 * s))
    d.ellipse([cx + 115 * s, cy - 285 * s, cx + 155 * s, cy - 245 * s], fill=(73, 80, 87, 255), outline=None)

    # Chef Head
    draw_circle(d, (cx, cy - 195 * s), 56 * s, fill=SKIN_PEACH, outline=INK, width=5 * s)
    # Hair Buns on sides
    draw_circle(d, (cx - 58 * s, cy - 195 * s), 24 * s, fill=HAIR_BROWN, outline=INK, width=4 * s)
    draw_circle(d, (cx + 58 * s, cy - 195 * s), 24 * s, fill=HAIR_BROWN, outline=INK, width=4 * s)

    # Face details (Ecstatic Smile)
    draw_circle(d, (cx - 32 * s, wy - 180 * s), 10 * s, fill=SKIN_BLUSH, outline=None, width=0)
    draw_circle(d, (cx + 32 * s, wy - 180 * s), 10 * s, fill=SKIN_BLUSH, outline=None, width=0)
    d.arc([cx - 38 * s, wy - 212 * s, cx - 14 * s, wy - 188 * s], start=190, end=350, fill=INK, width=int(5 * s))
    d.arc([cx + 14 * s, wy - 212 * s, cx + 38 * s, wy - 188 * s], start=190, end=350, fill=INK, width=int(5 * s))
    d.pieslice([cx - 24 * s, wy - 195 * s, cx + 24 * s, wy - 155 * s], start=0, end=180, fill=CHEF_BOW, outline=INK, width=int(4 * s))
    d.chord([cx - 22 * s, wy - 195 * s, cx + 22 * s, wy - 175 * s], start=0, end=180, fill=WHITE, outline=None)

    # Tall Puffy Toque Blanche (Chef Hat) with pleats
    hat_cx, hat_cy = cx, cy - 275 * s
    draw_rounded_box(d, [cx - 44 * s, cy - 245 * s, cx + 44 * s, cy - 225 * s], fill=WHITE, outline=INK, width=4 * s, radius=6 * s)
    # Hat puffs
    puffs = [
        (hat_cx - 42 * s, hat_cy + 10 * s, 32 * s),
        (hat_cx - 20 * s, hat_cy - 12 * s, 36 * s),
        (hat_cx + 20 * s, hat_cy - 12 * s, 36 * s),
        (hat_cx + 42 * s, hat_cy + 10 * s, 32 * s),
    ]
    for px, py, pr in puffs:
        draw_circle(d, (px, py), pr, fill=WHITE, outline=INK, width=4 * s)
    # Hat center fill cover
    draw_rounded_box(d, [hat_cx - 40 * s, hat_cy - 5 * s, hat_cx + 40 * s, cy - 230 * s], fill=WHITE, outline=None, radius=4 * s)
    # Pleat lines
    d.line([(hat_cx - 18 * s, hat_cy - 8 * s), (hat_cx - 18 * s, cy - 228 * s)], fill=(203, 213, 225, 255), width=int(3 * s))
    d.line([(hat_cx, hat_cy - 12 * s), (hat_cx, cy - 228 * s)], fill=(203, 213, 225, 255), width=int(3 * s))
    d.line([(hat_cx + 18 * s, hat_cy - 8 * s), (hat_cx + 18 * s, cy - 228 * s)], fill=(203, 213, 225, 255), width=int(3 * s))

    # -------------------------------------------------------------
    # CELEBRATION SPARKLES & ACTION LINES
    # -------------------------------------------------------------
    # Left cheer lines
    for ly in [180 * s, 210 * s, 240 * s]:
        d.line([(wx - 110 * s, ly), (wx - 145 * s, ly - 20 * s)], fill=INK, width=int(5 * s))
    # Right cheer lines
    for ry in [180 * s, 210 * s, 240 * s]:
        d.line([(cx + 120 * s, ry), (cx + 155 * s, ry - 20 * s)], fill=INK, width=int(5 * s))

    # Gold celebration stars floating around
    draw_star(d, (120 * s, 140 * s), 22 * s, 10 * s, fill=SPARKLE_GOLD, outline=INK, width=3 * s, rot=0.2)
    draw_star(d, (310 * s, 110 * s), 16 * s, 7 * s, fill=SPARKLE_GOLD, outline=INK, width=3 * s, rot=-0.3)
    draw_star(d, (490 * s, 95 * s), 20 * s, 9 * s, fill=SPARKLE_GOLD, outline=INK, width=3 * s, rot=0.4)
    draw_star(d, (690 * s, 150 * s), 24 * s, 11 * s, fill=SPARKLE_GOLD, outline=INK, width=3 * s, rot=-0.2)

    final_im = finalize_ssaa(im, w, h)
    out_path = SPRITES_DIR / "results" / "trio_celebration.png"
    final_im.save(out_path, format="PNG", optimize=True)
    print(f"Generated STUDIO MASTERPIECE: {out_path} ({w}x{h})")

# =============================================================================
# 2. BEAT FACTORY WORKER (beat_factory/worker.png, 2048x512, 4 frames of 512x512)
# Frames: 0=Idle, 1=Pull Lever, 2=Hit/Stamp Punch, 3=Miss
# =============================================================================
def build_beat_factory_worker():
    fw, fh = 512, 512
    num_frames = 4
    im, d = create_ssaa_canvas(fw * num_frames, fh)
    s = SS

    base_y = 440 * s

    for fi in range(num_frames):
        ox = fi * fw * s
        cx = ox + 256 * s
        cy = base_y

        # Animation offsets
        pull_dx = -25 * s if fi == 1 else (15 * s if fi == 2 else 0)
        punch_dy = 12 * s if fi == 2 else 0
        head_tilt = -0.06 if fi == 1 else (0.05 if fi == 2 else (0.12 if fi == 3 else 0))

        # Lever console drawn on right
        lx = cx + 80 * s
        ly = cy - 20 * s
        # Console base
        draw_rounded_box(d, [lx - 32 * s, ly - 70 * s, lx + 32 * s, ly], fill=LEVER_BASE, outline=INK, width=5 * s, radius=12 * s)
        # Steel rod & red ball knob
        knob_x = lx - 30 * s if fi == 1 else (lx + 25 * s if fi == 2 else lx)
        knob_y = ly - 110 * s if fi == 1 else (ly - 85 * s if fi == 2 else ly - 125 * s)
        d.line([(lx, ly - 50 * s), (knob_x, knob_y)], fill=INK, width=int(14 * s))
        d.line([(lx, ly - 50 * s), (knob_x, knob_y)], fill=(173, 181, 189, 255), width=int(8 * s))
        draw_circle(d, (knob_x, knob_y), 22 * s, fill=LEVER_RED, outline=INK, width=4 * s)
        draw_circle(d, (knob_x - 6 * s, knob_y - 6 * s), 6 * s, fill=WHITE, outline=None, width=0)

        # Worker Boots
        draw_rounded_box(d, [cx - 65 * s + pull_dx, cy - 35 * s, cx - 15 * s + pull_dx, cy], fill=(33, 37, 41, 255), outline=INK, width=5 * s, radius=10 * s)
        draw_rounded_box(d, [cx + 15 * s + pull_dx, cy - 35 * s, cx + 65 * s + pull_dx, cy], fill=(33, 37, 41, 255), outline=INK, width=5 * s, radius=10 * s)

        # Overalls Body
        draw_rounded_box(d, [cx - 75 * s + pull_dx, cy - 165 * s + punch_dy, cx + 75 * s + pull_dx, cy - 25 * s], fill=WORKER_DENIM, outline=INK, width=5 * s, radius=32 * s)
        # Straps & Buttons
        for side in [-1, 1]:
            sx = cx + side * 46 * s + pull_dx
            d.line([(sx, cy - 165 * s + punch_dy), (sx, cy - 90 * s + punch_dy)], fill=INK, width=int(16 * s))
            d.line([(sx, cy - 165 * s + punch_dy), (sx, cy - 90 * s + punch_dy)], fill=WORKER_DENIM, width=int(10 * s))
            draw_circle(d, (sx, cy - 90 * s + punch_dy), 8 * s, fill=WORKER_BUTTON, outline=INK, width=3 * s)

        # Left Arm (Rests on side or swings)
        lax = cx - 75 * s + pull_dx
        lay = cy - 145 * s + punch_dy
        d.line([(lax, lay), (lax - 25 * s, lay + 75 * s)], fill=INK, width=int(22 * s))
        d.line([(lax, lay), (lax - 25 * s, lay + 75 * s)], fill=WHITE, width=int(14 * s))
        draw_circle(d, (lax - 25 * s, lay + 75 * s), 16 * s, fill=SKIN_PEACH, outline=INK, width=4 * s)

        # Right Arm (Holding Lever)
        rax = cx + 65 * s + pull_dx
        ray = cy - 145 * s + punch_dy
        d.line([(rax, ray), (knob_x, knob_y)], fill=INK, width=int(24 * s))
        d.line([(rax, ray), (knob_x, knob_y)], fill=WHITE, width=int(14 * s))
        draw_circle(d, (knob_x, knob_y), 18 * s, fill=SKIN_PEACH, outline=INK, width=4 * s)

        # Head
        hx = cx + pull_dx
        hy = cy - 225 * s + punch_dy
        draw_circle(d, (hx, hy), 66 * s, fill=SKIN_PEACH, outline=INK, width=5 * s)
        # Hair tufts on sides
        draw_circle(d, (hx - 62 * s, hy), 18 * s, fill=HAIR_BROWN, outline=INK, width=4 * s)
        draw_circle(d, (hx + 62 * s, hy), 18 * s, fill=HAIR_BROWN, outline=INK, width=4 * s)

        # Yellow Helmet
        d.pieslice([hx - 74 * s, hy - 85 * s, hx + 74 * s, hy + 5 * s], start=180, end=360, fill=WORKER_HELMET, outline=INK, width=int(5 * s))
        draw_rounded_box(d, [hx - 84 * s, hy - 40 * s, hx + 84 * s, hy - 22 * s], fill=WORKER_HELMET, outline=INK, width=4 * s, radius=8 * s)
        draw_rounded_box(d, [hx - 26 * s, hy - 52 * s, hx + 26 * s, hy - 36 * s], fill=WORKER_STRIPE, outline=INK, width=3 * s, radius=5 * s)

        # Face details per frame
        # Blush
        draw_circle(d, (hx - 40 * s, hy - 5 * s), 12 * s, fill=SKIN_BLUSH, outline=None, width=0)
        draw_circle(d, (hx + 40 * s, hy - 5 * s), 12 * s, fill=SKIN_BLUSH, outline=None, width=0)

        if fi == 0:  # Idle
            draw_circle(d, (hx - 26 * s, hy - 18 * s), 9 * s, fill=INK, outline=None, width=0)
            draw_circle(d, (hx + 26 * s, hy - 18 * s), 9 * s, fill=INK, outline=None, width=0)
            draw_circle(d, (hx - 23 * s, hy - 21 * s), 3 * s, fill=WHITE, outline=None, width=0)
            draw_circle(d, (hx + 29 * s, hy - 21 * s), 3 * s, fill=WHITE, outline=None, width=0)
            # Gentle smile
            d.arc([hx - 18 * s, hy - 12 * s, hx + 18 * s, hy + 18 * s], start=10, end=170, fill=INK, width=int(4 * s))
        elif fi == 1:  # Pull / Anticipation (focused)
            draw_circle(d, (hx - 26 * s, hy - 16 * s), 10 * s, fill=INK, outline=None, width=0)
            draw_circle(d, (hx + 26 * s, hy - 16 * s), 10 * s, fill=INK, outline=None, width=0)
            draw_circle(d, (hx - 23 * s, hy - 20 * s), 4 * s, fill=WHITE, outline=None, width=0)
            draw_circle(d, (hx + 29 * s, hy - 20 * s), 4 * s, fill=WHITE, outline=None, width=0)
            # Open determined mouth
            draw_circle(d, (hx, hy + 8 * s), 10 * s, fill=CHEF_BOW, outline=INK, width=3 * s)
        elif fi == 2:  # Hit / Perfect (cheering joyous)
            d.arc([hx - 44 * s, hy - 32 * s, hx - 14 * s, hy - 2 * s], start=190, end=350, fill=INK, width=int(5 * s))
            d.arc([hx + 14 * s, hy - 32 * s, hx + 44 * s, hy - 2 * s], start=190, end=350, fill=INK, width=int(5 * s))
            d.pieslice([hx - 26 * s, hy - 12 * s, hx + 26 * s, hy + 28 * s], start=0, end=180, fill=CHEF_BOW, outline=INK, width=int(4 * s))
            d.chord([hx - 24 * s, hy - 12 * s, hx + 24 * s, hy + 6 * s], start=0, end=180, fill=WHITE, outline=None)
            # Impact spark around lever
            draw_star(d, (knob_x + 35 * s, knob_y - 25 * s), 30 * s, 12 * s, fill=SPARKLE_GOLD, outline=INK, width=4 * s)
        elif fi == 3:  # Miss (dizzy eyes, sweat drop)
            # Dizzy X eyes
            for side in [-1, 1]:
                ex = hx + side * 28 * s
                ey = hy - 18 * s
                d.line([(ex - 12 * s, ey - 12 * s), (ex + 12 * s, ey + 12 * s)], fill=INK, width=int(5 * s))
                d.line([(ex - 12 * s, ey + 12 * s), (ex + 12 * s, ey - 12 * s)], fill=INK, width=int(5 * s))
            # Wavy sad mouth
            d.arc([hx - 22 * s, hy + 4 * s, hx + 22 * s, hy + 28 * s], start=190, end=350, fill=INK, width=int(5 * s))
            # Big blue sweatdrop
            d.pieslice([hx + 55 * s, hy - 45 * s, hx + 85 * s, hy - 15 * s], start=120, end=360, fill=(112, 197, 213, 255), outline=INK, width=int(3 * s))

    final_im = finalize_ssaa(im, fw * num_frames, fh)
    out_path = SPRITES_DIR / "beat_factory" / "worker.png"
    final_im.save(out_path, format="PNG", optimize=True)
    print(f"Generated STUDIO WORKER: {out_path} ({fw * num_frames}x{fh})")

# =============================================================================
# 3. ECHO PLANET ALIEN (echo_planet/alien.png, 2048x512, 4 frames of 512x512)
# Frames: 0=Idle, 1=Call/Sing, 2=Cheer/Perfect, 3=Miss
# =============================================================================
def build_echo_planet_alien():
    fw, fh = 512, 512
    num_frames = 4
    im, d = create_ssaa_canvas(fw * num_frames, fh)
    s = SS

    base_y = 440 * s

    for fi in range(num_frames):
        ox = fi * fw * s
        cx = ox + 256 * s
        cy = base_y - (25 * s if fi == 2 else 0)

        # Arms
        if fi == 2:  # Cheer: Arms stretched high
            d.line([(cx - 42 * s, cy - 130 * s), (cx - 85 * s, cy - 210 * s)], fill=INK, width=int(18 * s))
            d.line([(cx - 42 * s, cy - 130 * s), (cx - 85 * s, cy - 210 * s)], fill=ALIEN_CYAN, width=int(12 * s))
            draw_circle(d, (cx - 85 * s, cy - 210 * s), 12 * s, fill=ALIEN_CYAN, outline=INK, width=4 * s)

            d.line([(cx + 42 * s, cy - 130 * s), (cx + 85 * s, cy - 210 * s)], fill=INK, width=int(18 * s))
            d.line([(cx + 42 * s, cy - 130 * s), (cx + 85 * s, cy - 210 * s)], fill=ALIEN_CYAN, width=int(12 * s))
            draw_circle(d, (cx + 85 * s, cy - 210 * s), 12 * s, fill=ALIEN_CYAN, outline=INK, width=4 * s)
        else:
            # Idle / Sing: Arms resting cutely
            arm_y_off = -15 * s if fi == 1 else 0
            d.line([(cx - 46 * s, cy - 130 * s), (cx - 75 * s, cy - 80 * s + arm_y_off)], fill=INK, width=int(18 * s))
            d.line([(cx - 46 * s, cy - 130 * s), (cx - 75 * s, cy - 80 * s + arm_y_off)], fill=ALIEN_CYAN, width=int(12 * s))
            draw_circle(d, (cx - 75 * s, cy - 80 * s + arm_y_off), 12 * s, fill=ALIEN_CYAN, outline=INK, width=4 * s)

            d.line([(cx + 46 * s, cy - 130 * s), (cx + 75 * s, cy - 80 * s + arm_y_off)], fill=INK, width=int(18 * s))
            d.line([(cx + 46 * s, cy - 130 * s), (cx + 75 * s, cy - 80 * s + arm_y_off)], fill=ALIEN_CYAN, width=int(12 * s))
            draw_circle(d, (cx + 75 * s, cy - 80 * s + arm_y_off), 12 * s, fill=ALIEN_CYAN, outline=INK, width=4 * s)

        # Little legs
        draw_rounded_box(d, [cx - 38 * s, cy - 45 * s, cx - 12 * s, cy], fill=ALIEN_CYAN, outline=INK, width=5 * s, radius=12 * s)
        draw_rounded_box(d, [cx + 12 * s, cy - 45 * s, cx + 38 * s, cy], fill=ALIEN_CYAN, outline=INK, width=5 * s, radius=12 * s)

        # Body
        draw_rounded_box(d, [cx - 56 * s, cy - 145 * s, cx + 56 * s, cy - 30 * s], fill=ALIEN_CYAN, outline=INK, width=5 * s, radius=28 * s)
        # Belly patch
        draw_circle(d, (cx, cy - 85 * s), 32 * s, fill=ALIEN_BELLY, outline=None, width=0)

        # Head
        hy = cy - 200 * s
        draw_circle(d, (cx, hy), 72 * s, fill=ALIEN_CYAN, outline=INK, width=5 * s)

        # Antenna
        ant_drop = 25 * s if fi == 3 else 0
        ant_tip = (cx + (25 * s if fi == 3 else 0), hy - 95 * s + ant_drop)
        d.line([(cx, hy - 68 * s), ant_tip], fill=INK, width=int(12 * s))
        d.line([(cx, hy - 68 * s), ant_tip], fill=ALIEN_CYAN, width=int(7 * s))
        draw_circle(d, ant_tip, 20 * s, fill=ALIEN_BULB, outline=INK, width=4 * s)

        # Sparkles or Singing waves
        if fi == 1:  # Singing waves
            d.arc([ant_tip[0] - 35 * s, ant_tip[1] - 35 * s, ant_tip[0] + 35 * s, ant_tip[1] + 35 * s], start=210, end=330, fill=SPARKLE_GOLD, width=int(4 * s))
            d.arc([ant_tip[0] - 50 * s, ant_tip[1] - 50 * s, ant_tip[0] + 50 * s, ant_tip[1] + 50 * s], start=210, end=330, fill=SPARKLE_GOLD, width=int(4 * s))
        elif fi == 2:  # Star burst
            draw_star(d, ant_tip, 34 * s, 14 * s, fill=SPARKLE_GOLD, outline=INK, width=4 * s)

        # Face details
        draw_circle(d, (cx - 42 * s, hy + 5 * s), 12 * s, fill=SKIN_BLUSH, outline=None, width=0)
        draw_circle(d, (cx + 42 * s, hy + 5 * s), 12 * s, fill=SKIN_BLUSH, outline=None, width=0)

        if fi == 0:  # Idle
            draw_circle(d, (cx - 28 * s, hy - 10 * s), 11 * s, fill=INK, outline=None, width=0)
            draw_circle(d, (cx + 28 * s, hy - 10 * s), 11 * s, fill=INK, outline=None, width=0)
            draw_circle(d, (cx - 25 * s, hy - 14 * s), 4 * s, fill=WHITE, outline=None, width=0)
            draw_circle(d, (cx + 31 * s, hy - 14 * s), 4 * s, fill=WHITE, outline=None, width=0)
            d.arc([cx - 16 * s, hy - 2 * s, cx + 16 * s, hy + 22 * s], start=10, end=170, fill=INK, width=int(4 * s))
        elif fi == 1:  # Sing (round 'O' mouth)
            draw_circle(d, (cx - 28 * s, hy - 12 * s), 12 * s, fill=INK, outline=None, width=0)
            draw_circle(d, (cx + 28 * s, hy - 12 * s), 12 * s, fill=INK, outline=None, width=0)
            draw_circle(d, (cx - 24 * s, hy - 16 * s), 5 * s, fill=WHITE, outline=None, width=0)
            draw_circle(d, (cx + 32 * s, hy - 16 * s), 5 * s, fill=WHITE, outline=None, width=0)
            draw_circle(d, (cx, hy + 12 * s), 15 * s, fill=INK, outline=None, width=0)
            draw_circle(d, (cx, hy + 12 * s), 10 * s, fill=CHEF_BOW, outline=None, width=0)
        elif fi == 2:  # Cheer
            d.arc([cx - 44 * s, hy - 25 * s, cx - 14 * s, hy + 5 * s], start=190, end=350, fill=INK, width=int(5 * s))
            d.arc([cx + 14 * s, hy - 25 * s, cx + 44 * s, hy + 5 * s], start=190, end=350, fill=INK, width=int(5 * s))
            d.pieslice([cx - 24 * s, hy - 5 * s, cx + 24 * s, hy + 35 * s], start=0, end=180, fill=CHEF_BOW, outline=INK, width=int(4 * s))
        elif fi == 3:  # Miss (sad teary eyes)
            d.arc([cx - 38 * s, hy - 22 * s, cx - 14 * s, hy - 2 * s], start=10, end=170, fill=INK, width=int(5 * s))
            d.arc([cx + 14 * s, hy - 22 * s, cx + 38 * s, hy - 2 * s], start=10, end=170, fill=INK, width=int(5 * s))
            d.arc([cx - 18 * s, hy + 8 * s, cx + 18 * s, hy + 30 * s], start=190, end=350, fill=INK, width=int(5 * s))

    final_im = finalize_ssaa(im, fw * num_frames, fh)
    out_path = SPRITES_DIR / "echo_planet" / "alien.png"
    final_im.save(out_path, format="PNG", optimize=True)
    print(f"Generated STUDIO ALIEN: {out_path} ({fw * num_frames}x{fh})")

# =============================================================================
# 4. ECHO PLANET DUAL ASTRONAUTS (echo_planet/astronauts.png, 1536x512, 3 frames)
# Standardized at 512x512 per frame!
# Frames: 0=Listen/Idle, 1=Response/Cheer, 2=Miss
# =============================================================================
def build_echo_planet_astronauts():
    fw, fh = 512, 512
    num_frames = 3
    im, d = create_ssaa_canvas(fw * num_frames, fh)
    s = SS

    base_y = 440 * s

    for fi in range(num_frames):
        ox = fi * fw * s
        # Two astronauts standing side by side
        # Left: Astronaut Girl (X = ox + 175*s), Right: Astronaut Boy (X = ox + 335*s)
        leap_g = 22 * s if fi == 1 else 0
        leap_b = 26 * s if fi == 1 else 0

        # --- ASTRONAUT GIRL ---
        gx = ox + 175 * s
        gy = base_y - leap_g

        # Girl Boots
        draw_rounded_box(d, [gx - 45 * s, gy - 25 * s, gx - 12 * s, gy], fill=(233, 236, 239, 255), outline=INK, width=4 * s, radius=8 * s)
        draw_rounded_box(d, [gx + 12 * s, gy - 25 * s, gx + 45 * s, gy], fill=(233, 236, 239, 255), outline=INK, width=4 * s, radius=8 * s)

        # Girl Body / Spacesuit
        draw_rounded_box(d, [gx - 55 * s, gy - 125 * s, gx + 55 * s, gy - 15 * s], fill=WHITE, outline=INK, width=5 * s, radius=24 * s)
        # Girl Pink Badge
        draw_rounded_box(d, [gx - 24 * s, gy - 95 * s, gx + 24 * s, gy - 65 * s], fill=(255, 93, 143, 255), outline=INK, width=3 * s, radius=8 * s)

        # Girl Arms
        if fi == 1: # Cheer/Response: Arms up waving
            d.line([(gx - 45 * s, gy - 105 * s), (gx - 75 * s, gy - 175 * s)], fill=INK, width=int(18 * s))
            d.line([(gx - 45 * s, gy - 105 * s), (gx - 75 * s, gy - 175 * s)], fill=WHITE, width=int(12 * s))
            draw_circle(d, (gx - 75 * s, gy - 175 * s), 12 * s, fill=WHITE, outline=INK, width=4 * s)

            d.line([(gx + 45 * s, gy - 105 * s), (gx + 75 * s, gy - 175 * s)], fill=INK, width=int(18 * s))
            d.line([(gx + 45 * s, gy - 105 * s), (gx + 75 * s, gy - 175 * s)], fill=WHITE, width=int(12 * s))
            draw_circle(d, (gx + 75 * s, gy - 175 * s), 12 * s, fill=WHITE, outline=INK, width=4 * s)
        else:
            d.line([(gx - 45 * s, gy - 105 * s), (gx - 65 * s, gy - 55 * s)], fill=INK, width=int(18 * s))
            d.line([(gx - 45 * s, gy - 105 * s), (gx - 65 * s, gy - 55 * s)], fill=WHITE, width=int(12 * s))
            draw_circle(d, (gx - 65 * s, gy - 55 * s), 12 * s, fill=WHITE, outline=INK, width=4 * s)

            d.line([(gx + 45 * s, gy - 105 * s), (gx + 65 * s, gy - 55 * s)], fill=INK, width=int(18 * s))
            d.line([(gx + 45 * s, gy - 105 * s), (gx + 65 * s, gy - 55 * s)], fill=WHITE, width=int(12 * s))
            draw_circle(d, (gx + 65 * s, gy - 55 * s), 12 * s, fill=WHITE, outline=INK, width=4 * s)

        # Girl Helmet (Bubble dome)
        draw_circle(d, (gx, gy - 180 * s), 64 * s, fill=WHITE, outline=INK, width=5 * s)
        # Visor
        draw_circle(d, (gx, gy - 180 * s), 48 * s, fill=ASTRONAUT_VISOR, outline=INK, width=4 * s)
        # Visor glass reflection
        d.arc([gx - 40 * s, gy - 220 * s, gx + 40 * s, gy - 140 * s], start=200, end=270, fill=WHITE, width=int(6 * s))
        # Face inside visor
        if fi == 0:
            draw_circle(d, (gx - 18 * s, gy - 180 * s), 6 * s, fill=WHITE, outline=None, width=0)
            draw_circle(d, (gx + 18 * s, gy - 180 * s), 6 * s, fill=WHITE, outline=None, width=0)
            d.arc([gx - 10 * s, gy - 172 * s, gx + 10 * s, gy - 160 * s], start=10, end=170, fill=WHITE, width=int(3 * s))
        elif fi == 1: # Joy
            d.arc([gx - 24 * s, gy - 190 * s, gx - 8 * s, gy - 172 * s], start=190, end=350, fill=WHITE, width=int(4 * s))
            d.arc([gx + 8 * s, gy - 190 * s, gx + 24 * s, gy - 172 * s], start=190, end=350, fill=WHITE, width=int(4 * s))
            draw_circle(d, (gx, gy - 168 * s), 6 * s, fill=(255, 93, 143, 255), outline=None, width=0)
        elif fi == 2: # Miss
            for side in [-1, 1]:
                ex = gx + side * 16 * s
                ey = gy - 180 * s
                d.line([(ex - 6 * s, ey - 6 * s), (ex + 6 * s, ey + 6 * s)], fill=WHITE, width=int(3 * s))
                d.line([(ex - 6 * s, ey + 6 * s), (ex + 6 * s, ey - 6 * s)], fill=WHITE, width=int(3 * s))

        # --- ASTRONAUT BOY ---
        bx = ox + 335 * s
        by = base_y - leap_b

        # Boy Boots
        draw_rounded_box(d, [bx - 48 * s, by - 26 * s, bx - 14 * s, by], fill=(233, 236, 239, 255), outline=INK, width=4 * s, radius=8 * s)
        draw_rounded_box(d, [bx + 14 * s, by - 26 * s, bx + 48 * s, by], fill=(233, 236, 239, 255), outline=INK, width=4 * s, radius=8 * s)

        # Boy Body / Spacesuit
        draw_rounded_box(d, [bx - 60 * s, by - 135 * s, bx + 60 * s, by - 16 * s], fill=WHITE, outline=INK, width=5 * s, radius=26 * s)
        # Boy Cyan Badge
        draw_rounded_box(d, [bx - 26 * s, by - 105 * s, bx + 26 * s, by - 75 * s], fill=(76, 201, 240, 255), outline=INK, width=3 * s, radius=8 * s)

        # Boy Arms
        if fi == 1:
            d.line([(bx - 50 * s, by - 115 * s), (bx - 80 * s, by - 185 * s)], fill=INK, width=int(18 * s))
            d.line([(bx - 50 * s, by - 115 * s), (bx - 80 * s, by - 185 * s)], fill=WHITE, width=int(12 * s))
            draw_circle(d, (bx - 80 * s, by - 185 * s), 13 * s, fill=WHITE, outline=INK, width=4 * s)

            d.line([(bx + 50 * s, by - 115 * s), (bx + 80 * s, by - 185 * s)], fill=INK, width=int(18 * s))
            d.line([(bx + 50 * s, by - 115 * s), (bx + 80 * s, by - 185 * s)], fill=WHITE, width=int(12 * s))
            draw_circle(d, (bx + 80 * s, by - 185 * s), 13 * s, fill=WHITE, outline=INK, width=4 * s)
        else:
            d.line([(bx - 50 * s, by - 115 * s), (bx - 70 * s, by - 65 * s)], fill=INK, width=int(18 * s))
            d.line([(bx - 50 * s, by - 115 * s), (bx - 70 * s, by - 65 * s)], fill=WHITE, width=int(12 * s))
            draw_circle(d, (bx - 70 * s, by - 65 * s), 13 * s, fill=WHITE, outline=INK, width=4 * s)

            d.line([(bx + 50 * s, by - 115 * s), (bx + 70 * s, by - 65 * s)], fill=INK, width=int(18 * s))
            d.line([(bx + 50 * s, by - 115 * s), (bx + 70 * s, by - 65 * s)], fill=WHITE, width=int(12 * s))
            draw_circle(d, (bx + 70 * s, by - 65 * s), 13 * s, fill=WHITE, outline=INK, width=4 * s)

        # Boy Helmet
        draw_circle(d, (bx, by - 190 * s), 68 * s, fill=WHITE, outline=INK, width=5 * s)
        draw_circle(d, (bx, by - 190 * s), 52 * s, fill=ASTRONAUT_VISOR, outline=INK, width=4 * s)
        d.arc([bx - 44 * s, by - 232 * s, bx + 44 * s, by - 148 * s], start=200, end=270, fill=WHITE, width=int(6 * s))

        if fi == 0:
            draw_circle(d, (bx - 19 * s, by - 190 * s), 6 * s, fill=WHITE, outline=None, width=0)
            draw_circle(d, (bx + 19 * s, by - 190 * s), 6 * s, fill=WHITE, outline=None, width=0)
            d.arc([bx - 11 * s, by - 182 * s, bx + 11 * s, by - 170 * s], start=10, end=170, fill=WHITE, width=int(3 * s))
        elif fi == 1:
            d.arc([bx - 26 * s, by - 200 * s, bx - 8 * s, by - 182 * s], start=190, end=350, fill=WHITE, width=int(4 * s))
            d.arc([bx + 8 * s, by - 200 * s, bx + 26 * s, by - 182 * s], start=190, end=350, fill=WHITE, width=int(4 * s))
            draw_circle(d, (bx, by - 176 * s), 7 * s, fill=(76, 201, 240, 255), outline=None, width=0)
            draw_star(d, (bx + 80 * s, by - 230 * s), 28 * s, 11 * s, fill=SPARKLE_GOLD, outline=INK, width=3 * s)
        elif fi == 2:
            for side in [-1, 1]:
                ex = bx + side * 18 * s
                ey = by - 190 * s
                d.line([(ex - 7 * s, ey - 7 * s), (ex + 7 * s, ey + 7 * s)], fill=WHITE, width=int(3 * s))
                d.line([(ex - 7 * s, ey + 7 * s), (ex + 7 * s, ey - 7 * s)], fill=WHITE, width=int(3 * s))

    final_im = finalize_ssaa(im, fw * num_frames, fh)
    out_path = SPRITES_DIR / "echo_planet" / "astronauts.png"
    final_im.save(out_path, format="PNG", optimize=True)
    print(f"Generated STUDIO ASTRONAUTS: {out_path} ({fw * num_frames}x{fh})")

# =============================================================================
# 5. RHYTHM KITCHEN CHEF (rhythm_kitchen/chef.png, 2560x512, 5 frames of 512x512)
# Frames: 0=Idle, 1=Pan Left, 2=Pan Right, 3=Cheer, 4=Miss
# =============================================================================
def build_rhythm_kitchen_chef():
    fw, fh = 512, 512
    num_frames = 5
    im, d = create_ssaa_canvas(fw * num_frames, fh)
    s = SS

    base_y = 440 * s

    for fi in range(num_frames):
        ox = fi * fw * s
        cx = ox + 256 * s
        cy = base_y

        pan_dir = -1 if fi == 1 else (1 if fi == 2 else 0)
        is_cheer = fi == 3
        is_miss = fi == 4

        # Chef Skirt
        draw_rounded_box(d, [cx - 60 * s, cy - 90 * s, cx + 60 * s, cy - 15 * s], fill=CHEF_SKIRT, outline=INK, width=5 * s, radius=20 * s)
        # Feet
        draw_circle(d, (cx - 30 * s, cy - 10 * s), 16 * s, fill=(33, 37, 41, 255), outline=INK, width=4 * s)
        draw_circle(d, (cx + 30 * s, cy - 10 * s), 16 * s, fill=(33, 37, 41, 255), outline=INK, width=4 * s)

        # Chef Double-Breasted Coat
        draw_rounded_box(d, [cx - 68 * s, cy - 175 * s, cx + 68 * s, cy - 80 * s], fill=WHITE, outline=INK, width=5 * s, radius=24 * s)
        # Double row buttons
        for by_off in [-45, -25]:
            draw_circle(d, (cx - 20 * s, cy + by_off * s - 80 * s), 5 * s, fill=(203, 213, 225, 255), outline=INK, width=2 * s)
            draw_circle(d, (cx + 20 * s, cy + by_off * s - 80 * s), 5 * s, fill=(203, 213, 225, 255), outline=INK, width=2 * s)

        # Red Ascot Tie
        draw_circle(d, (cx, cy - 170 * s), 14 * s, fill=CHEF_BOW, outline=INK, width=3 * s)
        d.polygon([(cx, cy - 170 * s), (cx - 22 * s, cy - 156 * s), (cx - 18 * s, cy - 174 * s)], fill=CHEF_BOW)
        d.polygon([(cx, cy - 170 * s), (cx + 22 * s, cy - 156 * s), (cx + 18 * s, cy - 174 * s)], fill=CHEF_BOW)

        # Pan & Arms
        pan_cx = cx + (pan_dir * 135 * s if pan_dir != 0 else (125 * s if is_cheer else 105 * s))
        pan_cy = cy - 190 * s if pan_dir != 0 else (cy - 275 * s if is_cheer else (cy - 110 * s if is_miss else cy - 155 * s))

        # Left Arm
        d.line([(cx - 60 * s, cy - 160 * s), (cx - 95 * s, cy - 115 * s if not is_cheer else cy - 225 * s)], fill=INK, width=int(22 * s))
        d.line([(cx - 60 * s, cy - 160 * s), (cx - 95 * s, cy - 115 * s if not is_cheer else cy - 225 * s)], fill=WHITE, width=int(14 * s))
        draw_circle(d, (cx - 95 * s, cy - 115 * s if not is_cheer else cy - 225 * s), 16 * s, fill=SKIN_PEACH, outline=INK, width=4 * s)

        # Right Arm (holding skillet)
        d.line([(cx + 60 * s, cy - 160 * s), (pan_cx - 45 * s, pan_cy + 15 * s)], fill=INK, width=int(22 * s))
        d.line([(cx + 60 * s, cy - 160 * s), (pan_cx - 45 * s, pan_cy + 15 * s)], fill=WHITE, width=int(14 * s))
        draw_circle(d, (pan_cx - 45 * s, pan_cy + 15 * s), 16 * s, fill=SKIN_PEACH, outline=INK, width=4 * s)

        # Cast Iron Skillet
        d.line([(pan_cx - 45 * s, pan_cy + 15 * s), (pan_cx, pan_cy)], fill=INK, width=int(12 * s))
        d.ellipse([pan_cx - 45 * s, pan_cy - 45 * s, pan_cx + 45 * s, pan_cy + 45 * s], fill=(52, 58, 64, 255), outline=INK, width=int(5 * s))
        d.ellipse([pan_cx - 35 * s, pan_cy - 35 * s, pan_cx + 35 * s, pan_cy + 35 * s], fill=(73, 80, 87, 255), outline=None)

        # Head
        hy = cy - 225 * s
        draw_circle(d, (cx, hy), 68 * s, fill=SKIN_PEACH, outline=INK, width=5 * s)
        # Hair Buns
        draw_circle(d, (cx - 68 * s, hy), 26 * s, fill=HAIR_BROWN, outline=INK, width=4 * s)
        draw_circle(d, (cx + 68 * s, hy), 26 * s, fill=HAIR_BROWN, outline=INK, width=4 * s)

        # Chef Hat
        hat_cy = hy - 95 * s
        draw_rounded_box(d, [cx - 52 * s, hy - 58 * s, cx + 52 * s, hy - 36 * s], fill=WHITE, outline=INK, width=4 * s, radius=8 * s)
        puffs = [
            (cx - 50 * s, hat_cy + 12 * s, 36 * s),
            (cx - 24 * s, hat_cy - 14 * s, 40 * s),
            (cx + 24 * s, hat_cy - 14 * s, 40 * s),
            (cx + 50 * s, hat_cy + 12 * s, 36 * s),
        ]
        for px, py, pr in puffs:
            draw_circle(d, (px, py), pr, fill=WHITE, outline=INK, width=4 * s)
        draw_rounded_box(d, [cx - 48 * s, hat_cy - 6 * s, cx + 48 * s, hy - 42 * s], fill=WHITE, outline=None, radius=4 * s)
        d.line([(cx - 22 * s, hat_cy - 10 * s), (cx - 22 * s, hy - 40 * s)], fill=(203, 213, 225, 255), width=int(3 * s))
        d.line([(cx, hat_cy - 14 * s), (cx, hy - 40 * s)], fill=(203, 213, 225, 255), width=int(3 * s))
        d.line([(cx + 22 * s, hat_cy - 10 * s), (cx + 22 * s, hy - 40 * s)], fill=(203, 213, 225, 255), width=int(3 * s))

        # Face details
        draw_circle(d, (cx - 42 * s, hy - 6 * s), 13 * s, fill=SKIN_BLUSH, outline=None, width=0)
        draw_circle(d, (cx + 42 * s, hy - 6 * s), 13 * s, fill=SKIN_BLUSH, outline=None, width=0)

        if fi == 0:  # Idle
            draw_circle(d, (cx - 28 * s, hy - 18 * s), 10 * s, fill=INK, outline=None, width=0)
            draw_circle(d, (cx + 28 * s, hy - 18 * s), 10 * s, fill=INK, outline=None, width=0)
            draw_circle(d, (cx - 25 * s, hy - 22 * s), 4 * s, fill=WHITE, outline=None, width=0)
            draw_circle(d, (cx + 31 * s, hy - 22 * s), 4 * s, fill=WHITE, outline=None, width=0)
            d.arc([cx - 20 * s, hy - 12 * s, cx + 20 * s, hy + 20 * s], start=10, end=170, fill=INK, width=int(4 * s))
        elif fi in [1, 2]:  # Pan Left / Right (fierce focus smile)
            look_dx = -6 * s if fi == 1 else 6 * s
            draw_circle(d, (cx - 28 * s + look_dx, hy - 18 * s), 10 * s, fill=INK, outline=None, width=0)
            draw_circle(d, (cx + 28 * s + look_dx, hy - 18 * s), 10 * s, fill=INK, outline=None, width=0)
            draw_circle(d, (cx - 25 * s + look_dx, hy - 22 * s), 4 * s, fill=WHITE, outline=None, width=0)
            draw_circle(d, (cx + 31 * s + look_dx, hy - 22 * s), 4 * s, fill=WHITE, outline=None, width=0)
            d.pieslice([cx - 22 * s, hy - 10 * s, cx + 22 * s, hy + 24 * s], start=0, end=180, fill=CHEF_BOW, outline=INK, width=int(4 * s))
        elif fi == 3:  # Cheer
            d.arc([cx - 44 * s, hy - 32 * s, cx - 14 * s, hy - 2 * s], start=190, end=350, fill=INK, width=int(5 * s))
            d.arc([cx + 14 * s, hy - 32 * s, cx + 44 * s, hy - 2 * s], start=190, end=350, fill=INK, width=int(5 * s))
            d.pieslice([cx - 26 * s, hy - 12 * s, cx + 26 * s, hy + 28 * s], start=0, end=180, fill=CHEF_BOW, outline=INK, width=int(4 * s))
            d.chord([cx - 24 * s, hy - 12 * s, cx + 24 * s, hy + 6 * s], start=0, end=180, fill=WHITE, outline=None)
            draw_star(d, (pan_cx, pan_cy - 65 * s), 30 * s, 12 * s, fill=SPARKLE_GOLD, outline=INK, width=4 * s)
        elif fi == 4:  # Miss
            for side in [-1, 1]:
                ex = cx + side * 28 * s
                ey = hy - 18 * s
                d.line([(ex - 12 * s, ey - 12 * s), (ex + 12 * s, ey + 12 * s)], fill=INK, width=int(5 * s))
                d.line([(ex - 12 * s, ey + 12 * s), (ex + 12 * s, ey - 12 * s)], fill=INK, width=int(5 * s))
            d.arc([cx - 22 * s, hy + 4 * s, cx + 22 * s, hy + 28 * s], start=190, end=350, fill=INK, width=int(5 * s))
            d.pieslice([cx + 55 * s, hy - 45 * s, cx + 85 * s, hy - 15 * s], start=120, end=360, fill=(112, 197, 213, 255), outline=INK, width=int(3 * s))

    final_im = finalize_ssaa(im, fw * num_frames, fh)
    out_path = SPRITES_DIR / "rhythm_kitchen" / "chef.png"
    final_im.save(out_path, format="PNG", optimize=True)
    print(f"Generated STUDIO CHEF: {out_path} ({fw * num_frames}x{fh})")

# =============================================================================
# 5. KITCHEN INGREDIENTS (rhythm_kitchen/ingredients.png, 1024x512, 2 frames of 512x512)
# Frame 0: Ripe Red Tomato, Frame 1: Crisp Green Lettuce Head
# =============================================================================
def build_kitchen_ingredients():
    fw, fh = 512, 512
    num_frames = 2
    im, d = create_ssaa_canvas(fw * num_frames, fh)
    s = SS

    # Frame 0: Glossy Red Tomato
    cx0, cy0 = 256 * s, 256 * s
    draw_circle(d, (cx0, cy0 + 15 * s), 135 * s, fill=(230, 57, 70, 255), outline=INK, width=6 * s)
    # Specular shine
    d.ellipse([cx0 - 85 * s, cy0 - 55 * s, cx0 - 35 * s, cy0 - 15 * s], fill=(255, 150, 166, 255))
    # Green Calyx Star
    draw_star(d, (cx0, cy0 - 105 * s), 65 * s, 22 * s, fill=(43, 147, 72, 255), outline=INK, width=5 * s)
    # Stem
    d.line([(cx0, cy0 - 105 * s), (cx0, cy0 - 145 * s)], fill=INK, width=int(14 * s))
    d.line([(cx0, cy0 - 105 * s), (cx0, cy0 - 145 * s)], fill=(43, 147, 72, 255), width=int(8 * s))

    # Frame 1: Fresh Green Lettuce
    cx1, cy1 = (fw + 256) * s, 256 * s
    draw_circle(d, (cx1, cy1 + 10 * s), 140 * s, fill=(82, 183, 136, 255), outline=INK, width=6 * s)
    # Leaf layers
    for r_off, col in [(105, (116, 198, 157, 255)), (70, (183, 228, 199, 255))]:
        draw_circle(d, (cx1 - 25 * s, cy1 - 5 * s), r_off * s, fill=col, outline=INK, width=4 * s)

    final_im = finalize_ssaa(im, fw * num_frames, fh)
    out_path = SPRITES_DIR / "rhythm_kitchen" / "ingredients.png"
    final_im.save(out_path, format="PNG", optimize=True)
    print(f"Generated STUDIO INGREDIENTS: {out_path} ({fw * num_frames}x{fh})")

# =============================================================================
# 6. BEAT FACTORY CARDBOARD BOXES (beat_factory/boxes.png, 1536x512, 3 frames)
# Frame 0: Normal Box, Frame 1: Perfect Gold Sealed Box, Frame 2: Miss Flattened Box
# =============================================================================
def build_beat_factory_boxes():
    fw, fh = 512, 512
    num_frames = 3
    im, d = create_ssaa_canvas(fw * num_frames, fh)
    s = SS

    BOX_BROWN = (224, 169, 109, 255)
    BOX_TAPE = (212, 154, 91, 255)

    for fi in range(num_frames):
        ox = fi * fw * s
        cx, cy = ox + 256 * s, 270 * s

        if fi == 2:  # Flattened
            bw, bh = 290 * s, 110 * s
            draw_rounded_box(d, [cx - bw // 2, cy + 40 * s, cx + bw // 2, cy + 40 * s + bh], fill=BOX_BROWN, outline=INK, width=6 * s, radius=18 * s)
            # Dizzy eyes
            for side in [-1, 1]:
                ex = cx + side * 45 * s
                ey = cy + 85 * s
                d.line([(ex - 14 * s, ey - 14 * s), (ex + 14 * s, ey + 14 * s)], fill=INK, width=int(5 * s))
                d.line([(ex - 14 * s, ey + 14 * s), (ex + 14 * s, ey - 14 * s)], fill=INK, width=int(5 * s))
        else:
            bw, bh = 220 * s, 220 * s
            draw_rounded_box(d, [cx - bw // 2, cy - bh // 2, cx + bw // 2, cy + bh // 2], fill=BOX_BROWN, outline=INK, width=6 * s, radius=24 * s)
            # Center packing tape
            d.line([(cx - bw // 2, cy), (cx + bw // 2, cy)], fill=INK, width=int(26 * s))
            d.line([(cx - bw // 2, cy), (cx + bw // 2, cy)], fill=BOX_TAPE, width=int(18 * s))

            if fi == 0:  # Cute normal face
                draw_circle(d, (cx - 42 * s, cy + 45 * s), 10 * s, fill=INK, outline=None, width=0)
                draw_circle(d, (cx + 42 * s, cy + 45 * s), 10 * s, fill=INK, outline=None, width=0)
                d.arc([cx - 24 * s, cy + 45 * s, cx + 24 * s, cy + 75 * s], start=10, end=170, fill=INK, width=int(4 * s))
            elif fi == 1:  # Gold Sealed Box (Perfect!)
                draw_star(d, (cx, cy - bh // 2), 42 * s, 18 * s, fill=SPARKLE_GOLD, outline=INK, width=5 * s)
                # Joyful eyes
                d.arc([cx - 56 * s, cy + 30 * s, cx - 28 * s, cy + 58 * s], start=190, end=350, fill=INK, width=int(5 * s))
                d.arc([cx + 28 * s, cy + 30 * s, cx + 56 * s, cy + 58 * s], start=190, end=350, fill=INK, width=int(5 * s))
                draw_circle(d, (cx - 48 * s, cy + 58 * s), 10 * s, fill=SKIN_BLUSH, outline=None, width=0)
                draw_circle(d, (cx + 48 * s, cy + 58 * s), 10 * s, fill=SKIN_BLUSH, outline=None, width=0)

    final_im = finalize_ssaa(im, fw * num_frames, fh)
    out_path = SPRITES_DIR / "beat_factory" / "boxes.png"
    final_im.save(out_path, format="PNG", optimize=True)
    print(f"Generated STUDIO BOXES: {out_path} ({fw * num_frames}x{fh})")

def main():
    ensure_dirs()
    print("Building all Rhythm Rhythm v0.3 studio-grade vector assets...")
    build_results_trio()
    build_beat_factory_worker()
    build_echo_planet_alien()
    build_echo_planet_astronauts()
    build_rhythm_kitchen_chef()
    build_kitchen_ingredients()
    build_beat_factory_boxes()
    print("ALL STUDIO VECTOR ASSETS SUCCESSFULLY COMPILED!")

if __name__ == "__main__":
    main()
