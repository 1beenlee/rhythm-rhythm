#!/usr/bin/env python3
"""
tools/build_perfect_sprites.py
Builds pixel-perfect, clean, transparent 2D sprite sheets and 960x640 backgrounds
from the 12 reference panels in fromChatGPT/rhythm_rhythm_v3_art_set_12_panels.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
PANELS_DIR = ROOT.parent / "fromChatGPT" / "rhythm_rhythm_v3_art_set_12_panels"
SPRITES_DIR = ROOT / "assets" / "sprites"

def ensure_dirs():
    for sub in ["", "common", "beat_factory", "echo_planet", "rhythm_kitchen"]:
        (SPRITES_DIR / sub).mkdir(parents=True, exist_ok=True)

def remove_cream_bg(img: Image.Image, bg_rgb=(254, 250, 238), dist_thresh=28, feather=16) -> Image.Image:
    """Keys out off-white/cream paper backgrounds with soft alpha edge feathering."""
    rgba = img.convert("RGBA")
    datas = list(rgba.getdata())
    br, bg, bb = bg_rgb
    new_data = []
    for item in datas:
        r, g, b, a = item
        dist = abs(r - br) + abs(g - bg) + abs(b - bb)
        if dist < dist_thresh:
            new_data.append((r, g, b, 0))
        elif dist < dist_thresh + feather:
            alpha = int(((dist - dist_thresh) / float(feather)) * 255.0)
            new_data.append((r, g, b, min(a, alpha)))
        else:
            new_data.append(item)
    rgba.putdata(new_data)
    return rgba

def clean_and_upscale_bg(panel_name: str, out_name: str, patch_areas=None):
    src = PANELS_DIR / panel_name
    if not src.exists():
        print(f"Warning: {src} missing")
        return
    im = Image.open(src).convert("RGB")
    d = ImageDraw.Draw(im)

    # Always patch the top-left black pill ("01 타이틀 화면", etc.)
    # In 384x341 image, the pill is roughly (8, 6, 175, 42)
    # Sample background color near the pill
    bg_sample = im.getpixel((180, 24))
    d.rounded_rectangle([6, 6, 175, 42], radius=14, fill=bg_sample)

    if patch_areas:
        for area, fill_color in patch_areas:
            d.rectangle(area, fill=fill_color)

    # High-quality Lanczos upscale to target 960x640 resolution
    bg = im.resize((960, 640), Image.Resampling.LANCZOS)
    bg = bg.filter(ImageFilter.UnsharpMask(radius=1.2, percent=110, threshold=3))
    out_path = SPRITES_DIR / out_name
    bg.save(out_path, format="PNG", optimize=True)
    print(f"Generated {out_name} (960x640)")

def build_backgrounds():
    # 01 Title Screen: patch top-left pill
    clean_and_upscale_bg("01_title.png", "bg_title.png")

    # 02 Stage Select: patch top-left pill
    clean_and_upscale_bg("02_stage_select.png", "bg_select.png")

    # 09 Results Screen: patch top-left pill
    clean_and_upscale_bg("09_results_superb.png", "bg_results.png")

    # 03 Beat Factory: Clean factory wall & conveyor (remove static characters & duplicate boxes)
    im3 = Image.open(PANELS_DIR / "03_beat_factory_idle.png").convert("RGB")
    d3 = ImageDraw.Draw(im3)
    wall_col = (252, 224, 162)
    belt_col = (99, 105, 122)
    # Patch top pill & mockup HUD
    d3.rectangle([0, 0, 384, 85], fill=wall_col)
    # Patch worker & speech bubble area: fill with warm factory wall
    d3.rectangle([130, 85, 330, 290], fill=wall_col)
    # Patch conveyor boxes: draw clean flat conveyor belt line
    d3.rectangle([0, 295, 384, 341], fill=belt_col)
    # Re-draw the 4 silver roller circles on the conveyor
    for rx in [65, 150, 235, 320]:
        d3.ellipse([rx - 16, 310, rx + 16, 342], fill=(205, 212, 227), outline=(24, 22, 36), width=3)
        d3.ellipse([rx - 6, 320, rx + 6, 332], fill=(46, 50, 66))

    bg3 = im3.resize((960, 640), Image.Resampling.LANCZOS)
    bg3.save(SPRITES_DIR / "bg_factory.png", format="PNG", optimize=True)
    print("Generated clean bg_factory.png (960x640)")

    # 05 Echo Planet: Clean cosmos landscape
    im5 = Image.open(PANELS_DIR / "05_echo_planet_listen.png").convert("RGB")
    d5 = ImageDraw.Draw(im5)
    sky_col = (79, 47, 150)
    # Patch top pill & HUD
    d5.rectangle([0, 0, 384, 85], fill=(45, 30, 107))
    # Patch speech bubble and alien from background
    d5.rectangle([20, 85, 290, 270], fill=sky_col)
    # Re-draw twinkle stars in the cleared sky
    for sx, sy in [(50, 120), (90, 180), (140, 110), (220, 140), (260, 190)]:
        d5.ellipse([sx - 3, sy - 3, sx + 3, sy + 3], fill=(255, 213, 36))

    bg5 = im5.resize((960, 640), Image.Resampling.LANCZOS)
    bg5.save(SPRITES_DIR / "bg_cosmos.png", format="PNG", optimize=True)
    print("Generated clean bg_cosmos.png (960x640)")

    # 07 Rhythm Kitchen: Clean kitchen background
    im7 = Image.open(PANELS_DIR / "07_rhythm_kitchen_idle.png").convert("RGB")
    d7 = ImageDraw.Draw(im7)
    tile_col = (253, 230, 168)
    counter_col = (184, 117, 62)
    # Patch top pill & HUD
    d7.rectangle([0, 0, 384, 85], fill=tile_col)
    # Patch center chef & bowls area with clean tile grid
    d7.rectangle([110, 85, 280, 275], fill=tile_col)
    # Tile grout lines
    for gy in [110, 155, 200, 245]:
        d7.line([110, gy, 280, gy], fill=(230, 190, 112), width=2)
    for gx in [150, 195, 240]:
        d7.line([gx, 85, gx, 275], fill=(230, 190, 112), width=2)
    # Patch counter ledge
    d7.rectangle([0, 275, 384, 341], fill=counter_col)
    d7.line([0, 275, 384, 275], fill=(24, 22, 36), width=3)

    bg7 = im7.resize((960, 640), Image.Resampling.LANCZOS)
    bg7.save(SPRITES_DIR / "bg_kitchen.png", format="PNG", optimize=True)
    print("Generated clean bg_kitchen.png (960x640)")

def build_worker_sprites():
    src = PANELS_DIR / "10_beat_factory_character_sheet.png"
    im10 = Image.open(src).convert("RGB")
    crops = [
        (20, 52, 98, 175),    # 0: Idle
        (100, 52, 200, 175),  # 1: Ready
        (200, 52, 288, 175),  # 2: Hit
        (290, 52, 372, 175)   # 3: Cheer
    ]
    fw, fh = 160, 220
    worker_sheet = Image.new("RGBA", (fw * 4, fh), (0, 0, 0, 0))
    for idx, box in enumerate(crops):
        cropped = im10.crop(box)
        transparent = remove_cream_bg(cropped)
        # Scale to fit nicely inside (fw, fh) while maintaining aspect ratio
        tw = int(fw * 0.85)
        th = int(fh * 0.85)
        scaled = transparent.resize((tw, th), Image.Resampling.LANCZOS)
        px = idx * fw + (fw - tw) // 2
        py = fh - th
        worker_sheet.paste(scaled, (px, py), scaled)
    worker_sheet.save(SPRITES_DIR / "beat_factory" / "worker.png")
    print("Generated beat_factory/worker.png (4 clean frames)")

def build_alien_sprites():
    src = PANELS_DIR / "11_echo_planet_character_sheet.png"
    im11 = Image.open(src).convert("RGB")
    crops = [
        (25, 52, 105, 175),   # 0: Idle
        (110, 52, 205, 175),  # 1: Sing
        (210, 52, 280, 175),  # 2: Listen
        (280, 52, 370, 175)   # 3: Success
    ]
    fw, fh = 150, 200
    alien_sheet = Image.new("RGBA", (fw * 4, fh), (0, 0, 0, 0))
    for idx, box in enumerate(crops):
        cropped = im11.crop(box)
        transparent = remove_cream_bg(cropped)
        tw = int(fw * 0.85)
        th = int(fh * 0.85)
        scaled = transparent.resize((tw, th), Image.Resampling.LANCZOS)
        px = idx * fw + (fw - tw) // 2
        py = fh - th
        alien_sheet.paste(scaled, (px, py), scaled)
    alien_sheet.save(SPRITES_DIR / "echo_planet" / "alien.png")
    print("Generated echo_planet/alien.png (4 clean frames)")

def build_chef_sprites():
    src = PANELS_DIR / "12_rhythm_kitchen_character_sheet.png"
    im12 = Image.open(src).convert("RGB")
    crops = [
        (18, 52, 98, 175),    # 0: Idle
        (100, 52, 202, 175),  # 1: Left Pan
        (204, 52, 290, 175),  # 2: Right Pan
        (290, 52, 375, 175)   # 3: Cheer
    ]
    fw, fh = 150, 220
    chef_sheet = Image.new("RGBA", (fw * 4, fh), (0, 0, 0, 0))
    for idx, box in enumerate(crops):
        cropped = im12.crop(box)
        transparent = remove_cream_bg(cropped)
        tw = int(fw * 0.85)
        th = int(fh * 0.85)
        scaled = transparent.resize((tw, th), Image.Resampling.LANCZOS)
        px = idx * fw + (fw - tw) // 2
        py = fh - th
        chef_sheet.paste(scaled, (px, py), scaled)
    chef_sheet.save(SPRITES_DIR / "rhythm_kitchen" / "chef.png")
    print("Generated rhythm_kitchen/chef.png (4 clean frames)")

if __name__ == "__main__":
    ensure_dirs()
    build_backgrounds()
    build_worker_sprites()
    build_alien_sprites()
    build_chef_sprites()
    print("PERFECT ART ASSETS SUCCESSFULLY GENERATED!")
