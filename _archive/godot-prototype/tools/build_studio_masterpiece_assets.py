#!/usr/bin/env python3
"""
tools/build_studio_masterpiece_assets.py
CCGS Masterpiece Art & Presentation Generator:
1. Native 960x640 Pristine celebration backgrounds (Zero baked text, zero fake buttons).
2. True Dual-Astronaut sprite sheet for Echo Planet (Two astronauts standing side-by-side).
3. Crisp, vibrant character and environment assets with zero blurry upscaling artifacts.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math

ROOT = Path(__file__).resolve().parents[1]
SPRITES_DIR = ROOT / "assets" / "sprites"

def ensure_dirs():
    for sub in ["", "common", "beat_factory", "echo_planet", "rhythm_kitchen"]:
        (SPRITES_DIR / sub).mkdir(parents=True, exist_ok=True)

def draw_outlined_box(draw: ImageDraw.ImageDraw, rect, fill, outline="#181624", width=4, radius=0):
    if radius > 0:
        draw.rounded_rectangle(rect, radius=radius, fill=fill, outline=outline, width=width)
    else:
        draw.rectangle(rect, fill=fill, outline=outline, width=width)

def draw_outlined_circle(draw: ImageDraw.ImageDraw, center, radius, fill, outline="#181624", width=4):
    cx, cy = center
    draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=fill, outline=outline, width=width)

def draw_star(draw: ImageDraw.ImageDraw, center, r_outer, r_inner, fill, outline="#181624", width=3, points=5, rot=0.0):
    cx, cy = center
    pts = []
    step = math.pi / points
    for i in range(points * 2):
        r = r_outer if i % 2 == 0 else r_inner
        ang = rot + i * step - math.pi / 2.0
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    draw.polygon(pts, fill=fill, outline=outline, width=width)

def draw_sunburst(draw: ImageDraw.ImageDraw, center, w, h, col1, col2, num_rays=24):
    cx, cy = center
    diag = math.sqrt(w * w + h * h) * 1.2
    draw.rectangle([0, 0, w, h], fill=col1)
    step = 2.0 * math.pi / num_rays
    for i in range(num_rays):
        if i % 2 == 0:
            a1 = i * step
            a2 = (i + 1) * step
            p1 = (cx, cy)
            p2 = (cx + diag * math.cos(a1), cy + diag * math.sin(a1))
            p3 = (cx + diag * math.cos(a2), cy + diag * math.sin(a2))
            draw.polygon([p1, p2, p3], fill=col2)

# =============================================================================
# 1. PRISTINE RESULTS SCREEN BACKGROUND (bg_results.png, 960x640)
# ZERO baked text, ZERO baked scoreboard card, ZERO baked buttons!
# =============================================================================
def build_pristine_results_bg():
    w, h = 960, 640
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)

    # 1. Festive Pink Sunburst Rays
    draw_sunburst(d, (w * 0.5, h * 0.42), w, h, "#ff9ebc", "#ffd4e2", num_rays=28)

    # 2. Overhead Stage Spotlight Cones (Soft Gold / Pale Amber)
    spot_overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(spot_overlay)
    # Left spotlight (highlighting cheering characters on left)
    sd.polygon([(w * 0.28, 0), (0, h), (w * 0.58, h)], fill=(255, 245, 180, 55))
    # Right spotlight (highlighting scoreboard card on right)
    sd.polygon([(w * 0.72, 0), (w * 0.45, h), (w, h)], fill=(255, 245, 180, 50))
    im = Image.alpha_composite(im, spot_overlay)
    d = ImageDraw.Draw(im)

    # 3. Festive Confetti & Sparkles in the air
    confetti_colors = ["#ffd524", "#4cc9f0", "#ff5d8f", "#70e000", "#ffffff"]
    import random
    rng = random.Random(42)  # Deterministic seed for reproducible crisp art
    for _ in range(60):
        cx = rng.randint(20, w - 20)
        cy = rng.randint(20, int(h * 0.85))
        col = rng.choice(confetti_colors)
        sz = rng.randint(5, 11)
        rot = rng.uniform(0, math.pi)
        if rng.random() < 0.35:
            # Star
            draw_star(d, (cx, cy), sz + 2, sz // 2, fill=col, outline="#b82650", width=2, rot=rot)
        elif rng.random() < 0.70:
            # Diamond
            d.polygon([(cx, cy - sz), (cx + sz, cy), (cx, cy + sz), (cx - sz, cy)], fill=col, outline="#b82650", width=2)
        else:
            # Streamer ribbon snippet
            d.arc([cx - sz, cy - sz, cx + sz, cy + sz], start=rng.randint(0, 180), end=rng.randint(200, 360), fill=col, width=4)

    # 4. Cheerful Stage Floor Cushion at Bottom
    draw_outlined_box(d, [-10, int(h * 0.86), w + 10, h + 10], fill="#fce4ec", outline="#181624", width=4)
    # Top border piping
    d.line([(-10, int(h * 0.86)), (w + 10, int(h * 0.86))], fill="#e63946", width=5)

    im.convert("RGB").save(SPRITES_DIR / "bg_results.png", format="PNG", optimize=True)
    print("Generated PRISTINE bg_results.png (960x640)")

# =============================================================================
# 2. PRISTINE TITLE SCREEN BACKGROUND (bg_title.png, 960x640)
# =============================================================================
def build_pristine_title_bg():
    w, h = 960, 640
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)

    # 1. Golden Yellow Sunburst
    draw_sunburst(d, (w * 0.5, h * 0.40), w, h, "#ffd000", "#ffdf4d", num_rays=24)

    # 2. Floating Musical Notes in background
    notes = [
        (int(w * 0.12), int(h * 0.24), "#ff3b7c", 22),
        (int(w * 0.88), int(h * 0.20), "#4cc9f0", 24),
        (int(w * 0.14), int(h * 0.62), "#4cc9f0", 18),
        (int(w * 0.86), int(h * 0.65), "#ff3b7c", 20),
    ]
    for nx, ny, ncol, nsz in notes:
        draw_outlined_circle(d, (nx, ny), nsz // 2 + 2, fill=ncol, outline="#181624", width=3)
        draw_outlined_box(d, [nx + nsz // 2 - 2, ny - nsz * 2, nx + nsz // 2 + 4, ny], fill=ncol, outline="#181624", width=3)
        d.line([(nx + nsz // 2 + 4, ny - nsz * 2), (nx + nsz // 2 + 16, ny - nsz * 2 + 6)], fill="#181624", width=4)

    # 3. Center Scalloped Cloud Logo Badge
    cx, cy = int(w * 0.5), int(h * 0.32)
    # Scalloped outer cloud puffs (Dark Navy/Black #1c1a2e)
    cloud_puffs = [
        (cx - 160, cy, 75), (cx - 100, cy - 55, 85), (cx, cy - 75, 95),
        (cx + 100, cy - 55, 85), (cx + 160, cy, 75), (cx + 120, cy + 45, 80),
        (cx, cy + 65, 90), (cx - 120, cy + 45, 80)
    ]
    # Draw cloud outline
    for px, py, pr in cloud_puffs:
        d.ellipse([px - pr - 6, py - pr - 6, px + pr + 6, py + pr + 6], fill="#ffffff")
    for px, py, pr in cloud_puffs:
        d.ellipse([px - pr - 2, py - pr - 2, px + pr + 2, py + pr + 2], fill="#181624")
    for px, py, pr in cloud_puffs:
        d.ellipse([px - pr, py - pr, px + pr, py + pr], fill="#1c1a2e")

    # Inside Cloud: Main Title "RHYTHM RHYTHM"
    try:
        font_large = ImageFont.truetype("arialbd.ttf", 46)
        font_sub = ImageFont.truetype("arialbd.ttf", 22)
    except:
        font_large = ImageFont.load_default()
        font_sub = ImageFont.load_default()

    d.text((cx, cy - 36), "RHYTHM", fill="#ffffff", font=font_large, anchor="mm")
    d.text((cx, cy + 12), "RHYTHM", fill="#ff5d8f", font=font_large, anchor="mm")

    # Groove Show Ribbon Badge under cloud
    rb_w, rb_h = 240, 44
    rb_x, rb_y = cx - rb_w // 2, cy + 54
    draw_outlined_box(d, [rb_x, rb_y, rb_x + rb_w, rb_y + rb_h], fill="#7952b3", outline="#ffffff", width=4, radius=18)
    draw_outlined_box(d, [rb_x, rb_y, rb_x + rb_w, rb_y + rb_h], fill=None, outline="#181624", width=3, radius=18)
    d.text((cx, rb_y + rb_h // 2), "GROOVE SHOW", fill="#ffd524", font=font_sub, anchor="mm")
    draw_star(d, (cx - 86, rb_y + rb_h // 2), 8, 4, fill="#ffd524", outline="#181624", width=2)
    draw_star(d, (cx + 86, rb_y + rb_h // 2), 8, 4, fill="#ffd524", outline="#181624", width=2)

    im.convert("RGB").save(SPRITES_DIR / "bg_title.png", format="PNG", optimize=True)
    print("Generated PRISTINE bg_title.png (960x640)")

# =============================================================================
# 3. PRISTINE STAGE SELECT BACKGROUND (bg_select.png, 960x640)
# Clean radial sunburst backdrop (Header banner and cards rendered dynamically!)
# =============================================================================
def build_pristine_select_bg():
    w, h = 960, 640
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)

    # 1. Sky Blue Sunburst
    draw_sunburst(d, (w * 0.5, h * 0.45), w, h, "#98ddca", "#bbf2e5", num_rays=24)

    # 2. Stage Floor Skirt at Bottom
    draw_outlined_box(d, [-10, int(h * 0.88), w + 10, h + 10], fill="#f7f9fa", outline="#181624", width=4)

    im.convert("RGB").save(SPRITES_DIR / "bg_select.png", format="PNG", optimize=True)
    print("Generated PRISTINE bg_select.png (960x640)")

# =============================================================================
# 4. DUAL ASTRONAUT SPRITE SHEET FOR ECHO PLANET (astronauts.png, 780x200)
# Frames (3 frames, 260x200 each):
# 0 = Listen (Both looking intently, hands down)
# 1 = Cheer  (Both leaping, arms high, joyous faces, sparkles!)
# 2 = Miss   (Both dizzy, spiral eyes, sweat drop)
# =============================================================================
def build_dual_astronaut_sprites():
    frame_w, frame_h = 260, 200
    im = Image.new("RGBA", (frame_w * 3, frame_h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)

    for fi in range(3):
        ox = fi * frame_w
        # Left character: Astronaut Girl (slightly smaller, cute pink chest badge, pink headphone nodes)
        # Right character: Astronaut Boy (slightly taller, cyan chest badge, cyan headphone nodes)
        
        # Base Y offsets for leaping in Cheer
        g_leap = 18 if fi == 1 else 0
        b_leap = 22 if fi == 1 else 0

        # --- ASTRONAUT GIRL (Left, Center X = ox + 82) ---
        gx = ox + 82
        gy = frame_h - 24 - g_leap

        # Girl Body / Spacesuit
        draw_outlined_box(d, [gx - 30, gy - 68, gx + 30, gy], fill="#ffffff", outline="#181624", width=4, radius=16)
        # Girl Feet
        draw_outlined_box(d, [gx - 26, gy - 12, gx - 6, gy + 4], fill="#e9ecef", outline="#181624", width=3, radius=6)
        draw_outlined_box(d, [gx + 6, gy - 12, gx + 26, gy + 4], fill="#e9ecef", outline="#181624", width=3, radius=6)
        # Girl Pink Chest Pocket/Badge
        draw_outlined_box(d, [gx - 14, gy - 52, gx + 14, gy - 32], fill="#ff5d8f", outline="#181624", width=3, radius=6)

        # Girl Arms
        if fi == 1:
            # Cheer: Arms stretched high up!
            d.line([(gx - 26, gy - 55), (gx - 42, gy - 95)], fill="#ffffff", width=14)
            d.line([(gx - 26, gy - 55), (gx - 42, gy - 95)], fill="#181624", width=4)
            draw_outlined_circle(d, (gx - 42, gy - 95), 8, fill="#ffffff", outline="#181624", width=3)
            d.line([(gx + 26, gy - 55), (gx + 38, gy - 95)], fill="#ffffff", width=14)
            d.line([(gx + 26, gy - 55), (gx + 38, gy - 95)], fill="#181624", width=4)
            draw_outlined_circle(d, (gx + 38, gy - 95), 8, fill="#ffffff", outline="#181624", width=3)
        elif fi == 2:
            # Miss: Arms slumped limp
            d.line([(gx - 26, gy - 55), (gx - 36, gy - 25)], fill="#ffffff", width=12)
            d.line([(gx - 26, gy - 55), (gx - 36, gy - 25)], fill="#181624", width=3)
            d.line([(gx + 26, gy - 55), (gx + 36, gy - 25)], fill="#ffffff", width=12)
            d.line([(gx + 26, gy - 55), (gx + 36, gy - 25)], fill="#181624", width=3)
        else:
            # Listen: Hands ready at waist
            d.line([(gx - 26, gy - 55), (gx - 34, gy - 36)], fill="#ffffff", width=12)
            d.line([(gx - 26, gy - 55), (gx - 34, gy - 36)], fill="#181624", width=3)
            d.line([(gx + 26, gy - 55), (gx + 34, gy - 36)], fill="#ffffff", width=12)
            d.line([(gx + 26, gy - 55), (gx + 34, gy - 36)], fill="#181624", width=3)

        # Girl Helmet (Outer sphere)
        draw_outlined_circle(d, (gx, gy - 92), 40, fill="#ffffff", outline="#181624", width=4)
        # Pink side ear antennas
        draw_outlined_box(d, [gx - 45, gy - 98, gx - 39, gy - 86], fill="#ff5d8f", outline="#181624", width=3, radius=3)
        draw_outlined_box(d, [gx + 39, gy - 98, gx + 45, gy - 86], fill="#ff5d8f", outline="#181624", width=3, radius=3)
        # Dark Purple Visor
        draw_outlined_box(d, [gx - 30, gy - 110, gx + 30, gy - 74], fill="#312244", outline="#181624", width=3, radius=14)
        # Visor glass reflection
        d.ellipse([gx - 24, gy - 108, gx - 8, gy - 100], fill="#8b5cf6")

        # Girl Eyes inside Visor
        if fi == 1:
            # Cheer: Happy arch eyes ^ ^
            d.arc([gx - 18, gy - 98, gx - 6, gy - 86], start=180, end=360, fill="#ffd524", width=3)
            d.arc([gx + 6, gy - 98, gx + 18, gy - 86], start=180, end=360, fill="#ffd524", width=3)
            # Joy mouth
            d.arc([gx - 8, gy - 88, gx + 8, gy - 80], start=0, end=180, fill="#ffffff", width=2)
        elif fi == 2:
            # Miss: Spiral / dizzy eyes X X
            d.line([(gx - 16, gy - 96), (gx - 8, gy - 88)], fill="#e63946", width=2)
            d.line([(gx - 16, gy - 88), (gx - 8, gy - 96)], fill="#e63946", width=2)
            d.line([(gx + 8, gy - 96), (gx + 16, gy - 88)], fill="#e63946", width=2)
            d.line([(gx + 8, gy - 88), (gx + 16, gy - 96)], fill="#e63946", width=2)
            # Sweat drop
            d.ellipse([gx + 26, gy - 116, gx + 34, gy - 106], fill="#4cc9f0")
        else:
            # Listen: Attentive cute dot eyes
            draw_outlined_circle(d, (gx - 12, gy - 92), 4, fill="#ffd524", outline="#ffffff", width=1)
            draw_outlined_circle(d, (gx + 12, gy - 92), 4, fill="#ffd524", outline="#ffffff", width=1)

        # --- ASTRONAUT BOY (Right, Center X = ox + 174) ---
        bx = ox + 174
        by = frame_h - 20 - b_leap

        # Boy Body / Spacesuit
        draw_outlined_box(d, [bx - 32, by - 74, bx + 32, by], fill="#ffffff", outline="#181624", width=4, radius=18)
        # Boy Feet
        draw_outlined_box(d, [bx - 28, by - 14, bx - 6, by + 4], fill="#e9ecef", outline="#181624", width=3, radius=6)
        draw_outlined_box(d, [bx + 6, by - 14, bx + 28, by + 4], fill="#e9ecef", outline="#181624", width=3, radius=6)
        # Boy Cyan Chest Badge
        draw_outlined_box(d, [bx - 16, by - 56, bx + 16, by - 34], fill="#4cc9f0", outline="#181624", width=3, radius=6)

        # Boy Arms
        if fi == 1:
            # Cheer: Arms high up!
            d.line([(bx - 28, by - 58), (bx - 38, by - 102)], fill="#ffffff", width=14)
            d.line([(bx - 28, by - 58), (bx - 38, by - 102)], fill="#181624", width=4)
            draw_outlined_circle(d, (bx - 38, by - 102), 8, fill="#ffffff", outline="#181624", width=3)
            d.line([(bx + 28, by - 58), (bx + 44, by - 102)], fill="#ffffff", width=14)
            d.line([(bx + 28, by - 58), (bx + 44, by - 102)], fill="#181624", width=4)
            draw_outlined_circle(d, (bx + 44, by - 102), 8, fill="#ffffff", outline="#181624", width=3)
        elif fi == 2:
            # Miss: Limp down
            d.line([(bx - 28, by - 58), (bx - 38, by - 25)], fill="#ffffff", width=12)
            d.line([(bx - 28, by - 58), (bx - 38, by - 25)], fill="#181624", width=3)
            d.line([(bx + 28, by - 58), (bx + 38, by - 25)], fill="#ffffff", width=12)
            d.line([(bx + 28, by - 58), (bx + 38, by - 25)], fill="#181624", width=3)
        else:
            # Listen: Hands steady
            d.line([(bx - 28, by - 58), (bx - 36, by - 38)], fill="#ffffff", width=12)
            d.line([(bx - 28, by - 58), (bx - 36, by - 38)], fill="#181624", width=3)
            d.line([(bx + 28, by - 58), (bx + 36, by - 38)], fill="#ffffff", width=12)
            d.line([(bx + 28, by - 58), (bx + 36, by - 38)], fill="#181624", width=3)

        # Boy Helmet
        draw_outlined_circle(d, (bx, by - 100), 42, fill="#ffffff", outline="#181624", width=4)
        # Cyan side ear nodes
        draw_outlined_box(d, [bx - 48, by - 106, bx - 42, by - 94], fill="#4cc9f0", outline="#181624", width=3, radius=3)
        draw_outlined_box(d, [bx + 42, by - 106, bx + 48, by - 94], fill="#4cc9f0", outline="#181624", width=3, radius=3)
        # Dark Purple Visor
        draw_outlined_box(d, [bx - 32, by - 118, bx + 32, by - 82], fill="#312244", outline="#181624", width=3, radius=14)
        # Visor glass reflection
        d.ellipse([bx - 26, by - 116, bx - 10, by - 108], fill="#38bdf8")

        # Boy Eyes
        if fi == 1:
            # Cheer: Happy arch eyes
            d.arc([bx - 20, gy - 104, bx - 6, gy - 92], start=180, end=360, fill="#ffd524", width=3)
            d.arc([bx + 6, gy - 104, bx + 20, gy - 92], start=180, end=360, fill="#ffd524", width=3)
            d.arc([bx - 8, gy - 92, bx + 8, gy - 84], start=0, end=180, fill="#ffffff", width=2)
            # Gold sparkle above duo
            draw_star(d, (ox + 130, 24), 14, 6, fill="#ffd524", outline="#181624", width=2)
        elif fi == 2:
            # Miss: Dizzy eyes
            d.line([(bx - 18, by - 104), (bx - 8, by - 94)], fill="#e63946", width=2)
            d.line([(bx - 18, by - 94), (bx - 8, by - 104)], fill="#e63946", width=2)
            d.line([(bx + 8, by - 104), (bx + 18, by - 94)], fill="#e63946", width=2)
            d.line([(bx + 8, by - 94), (bx + 18, by - 104)], fill="#e63946", width=2)
        else:
            # Listen: Attentive eyes
            draw_outlined_circle(d, (bx - 14, by - 98), 4, fill="#ffd524", outline="#ffffff", width=1)
            draw_outlined_circle(d, (bx + 14, by - 98), 4, fill="#ffd524", outline="#ffffff", width=1)

    im.save(SPRITES_DIR / "echo_planet" / "astronauts.png", format="PNG", optimize=True)
    print("Generated PRISTINE echo_planet/astronauts.png (780x200, Dual Astronauts)")

if __name__ == "__main__":
    ensure_dirs()
    build_pristine_results_bg()
    build_pristine_title_bg()
    build_pristine_select_bg()
    build_dual_astronaut_sprites()
    print("ALL CCGS MASTERPIECE ASSETS BUILT SUCCESSFULLY!")
