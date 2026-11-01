#!/usr/bin/env python3
"""
Rhythm Rhythm v0.3 — Production 2D Sprite Sheets & High-Res Textures Generator
Transforms reference panels from fromChatGPT/rhythm_rhythm_v3_art_set_12_panels
into game-ready 960x640 backgrounds, transparent RGBA sprite sheets, and UI textures
under assets/sprites/.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
PANELS_DIR = ROOT.parent / "fromChatGPT" / "rhythm_rhythm_v3_art_set_12_panels"
SPRITES_DIR = ROOT / "assets" / "sprites"

def ensure_dirs():
    for sub in ["", "common", "beat_factory", "echo_planet", "rhythm_kitchen"]:
        (SPRITES_DIR / sub).mkdir(parents=True, exist_ok=True)

def remove_cream_bg(img: Image.Image, bg_rgb=(254, 250, 238), dist_thresh=22, feather=18) -> Image.Image:
    """Keys out off-white/cream paper backgrounds with soft alpha edge feathering."""
    rgba = img.convert("RGBA")
    datas = list(rgba.getdata())
    br, bg, bb = bg_rgb
    new_data = []
    for item in datas:
        r, g, b, a = item
        # Fast cream color metric
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

def upscale_bg(panel_name: str, out_name: str):
    src = PANELS_DIR / panel_name
    if not src.exists():
        print(f"Warning: {src} missing")
        return
    im = Image.open(src).convert("RGB")
    # High-quality Lanczos upscale to target 960x640 resolution
    bg = im.resize((960, 640), Image.Resampling.LANCZOS)
    # Subtle sharpening to keep line weights crisp on high-DPI displays
    bg = bg.filter(ImageFilter.UnsharpMask(radius=1.2, percent=110, threshold=3))
    out_path = SPRITES_DIR / out_name
    bg.save(out_path, format="PNG", optimize=True)
    print(f"Generated {out_path.relative_to(ROOT)} ({bg.size[0]}x{bg.size[1]})")

def build_backgrounds():
    upscale_bg("01_title.png", "bg_title.png")
    upscale_bg("02_stage_select.png", "bg_select.png")
    upscale_bg("03_beat_factory_idle.png", "bg_factory.png")
    upscale_bg("05_echo_planet_listen.png", "bg_cosmos.png")
    upscale_bg("07_rhythm_kitchen_idle.png", "bg_kitchen.png")
    upscale_bg("09_results_superb.png", "bg_results.png")

def build_beat_factory_sprites():
    src = PANELS_DIR / "10_beat_factory_character_sheet.png"
    if not src.exists():
        return
    sheet = Image.open(src).convert("RGBA")
    w, h = sheet.size

    # Slice the 3 main poses on row 0: Idle (col 0), Ready (col 1), Stamp Hit (col 2)
    # And row 1: Miss / Sweat pose
    col_w = w / 3.0
    row_h = h / 3.0

    idle_raw = sheet.crop((0, 0, int(col_w), int(row_h * 1.8)))
    ready_raw = sheet.crop((int(col_w), 0, int(col_w * 2), int(row_h * 1.8)))
    hit_raw = sheet.crop((int(col_w * 2), 0, w, int(row_h * 1.8)))
    miss_raw = sheet.crop((0, int(row_h * 1.2), int(col_w), h))

    idle = remove_cream_bg(idle_raw)
    ready = remove_cream_bg(ready_raw)
    hit = remove_cream_bg(hit_raw)
    miss = remove_cream_bg(miss_raw)

    # Pack into worker_sheet.png: 4 frames horizontally (each 160x220)
    fw, fh = 160, 220
    worker_sheet = Image.new("RGBA", (fw * 4, fh), (0, 0, 0, 0))
    for idx, frame in enumerate([idle, ready, hit, miss]):
        f_scaled = frame.resize((fw, fh), Image.Resampling.LANCZOS)
        worker_sheet.paste(f_scaled, (idx * fw, 0), f_scaled)
    worker_sheet.save(SPRITES_DIR / "beat_factory" / "worker.png")
    print("Generated beat_factory/worker.png")

    # Build boxes.png: 5 frames (Normal, Stamped Happy, Crushed, Charge Box, Golden Box)
    bw, bh = 120, 100
    boxes_sheet = Image.new("RGBA", (bw * 5, bh), (0, 0, 0, 0))
    # Frame 0: Normal tan cardboard box
    d0 = ImageDraw.Draw(boxes_sheet)
    for i in range(5):
        bx = i * bw
        rect = [bx + 14, 16, bx + bw - 14, bh - 10]
        if i == 0:
            d0.rounded_rectangle(rect, radius=8, fill="#f6c26b", outline="#181624", width=4)
            d0.rectangle([bx + bw//2 - 10, 16, bx + bw//2 + 10, 32], fill="#bd7b38", outline="#181624", width=3)
            # Eyes & cute smile
            d0.ellipse([bx + bw//2 - 20, 48, bx + bw//2 - 12, 56], fill="#181624")
            d0.ellipse([bx + bw//2 + 12, 48, bx + bw//2 + 20, 56], fill="#181624")
            d0.arc([bx + bw//2 - 12, 54, bx + bw//2 + 12, 70], start=0, end=180, fill="#181624", width=3)
        elif i == 1:
            # Stamped happy box (gold star & red ribbon)
            d0.rounded_rectangle(rect, radius=8, fill="#ffe082", outline="#181624", width=4)
            d0.rectangle([bx + bw//2 - 12, 16, bx + bw//2 + 12, 34], fill="#e63946", outline="#181624", width=3)
            d0.ellipse([bx + bw//2 - 20, 46, bx + bw//2 - 12, 54], fill="#181624")
            d0.ellipse([bx + bw//2 + 12, 46, bx + bw//2 + 20, 54], fill="#181624")
            d0.chord([bx + bw//2 - 14, 52, bx + bw//2 + 14, 74], start=0, end=180, fill="#e63946", outline="#181624", width=3)
            # Gold star
            d0.regular_polygon((bx + bw - 26, 32, 10), n_sides=5, fill="#ffd524", outline="#181624")
        elif i == 2:
            # Crushed / Miss box
            crushed_rect = [bx + 10, 34, bx + bw - 10, bh - 10]
            d0.rounded_rectangle(crushed_rect, radius=6, fill="#e8b868", outline="#181624", width=4)
            # x x eyes
            d0.line([bx + bw//2 - 22, 50, bx + bw//2 - 14, 58], fill="#181624", width=3)
            d0.line([bx + bw//2 - 22, 58, bx + bw//2 - 14, 50], fill="#181624", width=3)
            d0.line([bx + bw//2 + 14, 50, bx + bw//2 + 22, 58], fill="#181624", width=3)
            d0.line([bx + bw//2 + 14, 58, bx + bw//2 + 22, 50], fill="#181624", width=3)
            d0.arc([bx + bw//2 - 10, 68, bx + bw//2 + 10, 80], start=180, end=360, fill="#181624", width=3)
        elif i == 3:
            # Big heavy hold charge box (blue steel + gauge)
            d0.rounded_rectangle(rect, radius=10, fill="#527196", outline="#181624", width=5)
            d0.rounded_rectangle([bx + 24, 28, bx + bw - 24, bh - 22], radius=6, fill="#384f6b", outline="#181624", width=3)
            # Pressure gauge meter
            d0.ellipse([bx + bw//2 - 18, 38, bx + bw//2 + 18, 74], fill="#fffdf7", outline="#181624", width=3)
            d0.line([bx + bw//2, 56, bx + bw//2 + 10, 44], fill="#e63946", width=3)
        elif i == 4:
            # Big heavy box golden stamped
            d0.rounded_rectangle(rect, radius=10, fill="#ffd034", outline="#181624", width=5)
            d0.ellipse([bx + bw//2 - 24, 30, bx + bw//2 + 24, 78], fill="#ff477e", outline="#181624", width=4)
            d0.regular_polygon((bx + bw//2, 54, 18), n_sides=5, fill="#ffffff", outline="#181624")

    boxes_sheet.save(SPRITES_DIR / "beat_factory" / "boxes.png")
    print("Generated beat_factory/boxes.png")

    # Stamp head & piston
    sw, sh = 160, 160
    stamp_img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    sd = ImageDraw.Draw(stamp_img)
    # Piston rod
    sd.rectangle([sw//2 - 16, 0, sw//2 + 16, sh - 60], fill="#a8b2c6", outline="#181624", width=4)
    # Hazard striped trapezoid stamp head
    trap = [(sw//2 - 45, sh - 60), (sw//2 + 45, sh - 60), (sw//2 + 65, sh - 14), (sw//2 - 65, sh - 14)]
    sd.polygon(trap, fill="#ffd524", outline="#181624")
    # Black stripes
    sd.polygon([(sw//2 - 25, sh - 58), (sw//2 - 10, sh - 58), (sw//2 - 28, sh - 16), (sw//2 - 45, sh - 16)], fill="#252432")
    sd.polygon([(sw//2 + 10, sh - 58), (sw//2 + 25, sh - 58), (sw//2 + 45, sh - 16), (sw//2 + 28, sh - 16)], fill="#252432")
    # Rubber bottom pad
    sd.rounded_rectangle([sw//2 - 68, sh - 16, sw//2 + 68, sh - 2], radius=4, fill="#e86832", outline="#181624", width=3)
    stamp_img.save(SPRITES_DIR / "beat_factory" / "stamp_press.png")
    print("Generated beat_factory/stamp_press.png")

def build_echo_planet_sprites():
    src = PANELS_DIR / "11_echo_planet_character_sheet.png"
    if not src.exists():
        return
    sheet = Image.open(src).convert("RGBA")
    w, h = sheet.size

    col_w = w / 3.0
    row_h = h / 3.0

    alien_idle_raw = sheet.crop((0, 0, int(col_w), int(row_h * 1.8)))
    alien_sing_raw = sheet.crop((int(col_w), 0, int(col_w * 2), int(row_h * 1.8)))
    alien_cheer_raw = sheet.crop((int(col_w * 2), 0, w, int(row_h * 1.8)))
    alien_miss_raw = sheet.crop((0, int(row_h * 1.2), int(col_w), h))

    alien_idle = remove_cream_bg(alien_idle_raw)
    alien_sing = remove_cream_bg(alien_sing_raw)
    alien_cheer = remove_cream_bg(alien_cheer_raw)
    alien_miss = remove_cream_bg(alien_miss_raw)

    fw, fh = 150, 200
    alien_sheet = Image.new("RGBA", (fw * 4, fh), (0, 0, 0, 0))
    for idx, frame in enumerate([alien_idle, alien_sing, alien_cheer, alien_miss]):
        f_scaled = frame.resize((fw, fh), Image.Resampling.LANCZOS)
        alien_sheet.paste(f_scaled, (idx * fw, 0), f_scaled)
    alien_sheet.save(SPRITES_DIR / "echo_planet" / "alien.png")
    print("Generated echo_planet/alien.png")

    # Astronaut kids sprite
    astro_w, astro_h = 130, 160
    astro_sheet = Image.new("RGBA", (astro_w * 3, astro_h), (0, 0, 0, 0))
    ad = ImageDraw.Draw(astro_sheet)
    for ai in range(3):
        ax = ai * astro_w
        # White rounded spacesuit body
        ad.rounded_rectangle([ax + 25, 48, ax + astro_w - 25, astro_h - 10], radius=16, fill="#fdfdfd", outline="#181624", width=4)
        # Helmet dome
        ad.ellipse([ax + 20, 12, ax + astro_w - 20, 84], fill="#fdfdfd", outline="#181624", width=4)
        # Visor
        ad.ellipse([ax + 32, 24, ax + astro_w - 32, 72], fill="#4f3875", outline="#181624", width=3)
        # Face inside visor
        ad.rounded_rectangle([ax + 38, 32, ax + astro_w - 38, 64], radius=10, fill="#ffe2b8")
        if ai == 0:
            # Listen face
            ad.ellipse([ax + 50, 42, ax + 56, 48], fill="#181624")
            ad.ellipse([ax + astro_w - 56, 42, ax + astro_w - 50, 48], fill="#181624")
            ad.arc([ax + 54, 48, ax + astro_w - 54, 58], start=0, end=180, fill="#181624", width=2)
        elif ai == 1:
            # Cheer face & arm raised!
            ad.ellipse([ax + 50, 40, ax + 56, 46], fill="#181624")
            ad.ellipse([ax + astro_w - 56, 40, ax + astro_w - 50, 46], fill="#181624")
            ad.chord([ax + 52, 46, ax + astro_w - 52, 60], start=0, end=180, fill="#e63946", outline="#181624", width=2)
            # Arm up
            ad.line([ax + astro_w - 25, 60, ax + astro_w - 8, 30], fill="#fdfdfd", width=12)
            ad.line([ax + astro_w - 25, 60, ax + astro_w - 8, 30], fill="#181624", width=4)
        elif ai == 2:
            # Miss face (dizzy eyes)
            ad.line([ax + 48, 40, ax + 56, 48], fill="#181624", width=2)
            ad.line([ax + 48, 48, ax + 56, 40], fill="#181624", width=2)
            ad.line([ax + astro_w - 56, 40, ax + astro_w - 48, 48], fill="#181624", width=2)
            ad.line([ax + astro_w - 56, 48, ax + astro_w - 48, 40], fill="#181624", width=2)
            ad.arc([ax + 54, 52, ax + astro_w - 54, 62], start=180, end=360, fill="#181624", width=2)

    astro_sheet.save(SPRITES_DIR / "echo_planet" / "astronauts.png")
    print("Generated echo_planet/astronauts.png")

def build_rhythm_kitchen_sprites():
    src = PANELS_DIR / "12_rhythm_kitchen_character_sheet.png"
    if not src.exists():
        return
    sheet = Image.open(src).convert("RGBA")
    w, h = sheet.size

    col_w = w / 3.0
    row_h = h / 3.0

    chef_idle_raw = sheet.crop((0, 0, int(col_w), int(row_h * 1.8)))
    chef_pan_l_raw = sheet.crop((int(col_w), 0, int(col_w * 2), int(row_h * 1.8)))
    chef_pan_r_raw = sheet.crop((int(col_w * 2), 0, w, int(row_h * 1.8)))
    chef_miss_raw = sheet.crop((0, int(row_h * 1.2), int(col_w), h))

    chef_idle = remove_cream_bg(chef_idle_raw)
    chef_pan_l = remove_cream_bg(chef_pan_l_raw)
    chef_pan_r = remove_cream_bg(chef_pan_r_raw)
    chef_miss = remove_cream_bg(chef_miss_raw)

    fw, fh = 150, 220
    chef_sheet = Image.new("RGBA", (fw * 4, fh), (0, 0, 0, 0))
    for idx, frame in enumerate([chef_idle, chef_pan_l, chef_pan_r, chef_miss]):
        f_scaled = frame.resize((fw, fh), Image.Resampling.LANCZOS)
        chef_sheet.paste(f_scaled, (idx * fw, 0), f_scaled)
    chef_sheet.save(SPRITES_DIR / "rhythm_kitchen" / "chef.png")
    print("Generated rhythm_kitchen/chef.png")

    # Ingredients (Tomato, Lettuce, Trio)
    iw, ih = 70, 70
    ing_sheet = Image.new("RGBA", (iw * 3, ih), (0, 0, 0, 0))
    idraw = ImageDraw.Draw(ing_sheet)
    # Frame 0: Ripe red tomato
    idraw.ellipse([10, 14, iw - 10, ih - 10], fill="#f23838", outline="#181624", width=3)
    idraw.polygon([(iw//2, 8), (iw//2 - 8, 16), (iw//2 + 8, 16)], fill="#2b9348", outline="#181624")
    # Frame 1: Crisp lettuce leaf
    lx = iw
    idraw.ellipse([lx + 10, 14, lx + iw - 10, ih - 10], fill="#55ba45", outline="#181624", width=3)
    idraw.line([lx + iw//2, 20, lx + iw//2, ih - 20], fill="#b7ef8c", width=2)
    # Frame 2: Triple mini-ingredients (trio toss)
    tx = iw * 2
    idraw.ellipse([tx + 8, 30, tx + 26, 48], fill="#f23838", outline="#181624", width=2)
    idraw.ellipse([tx + 26, 12, tx + 46, 32], fill="#55ba45", outline="#181624", width=2)
    idraw.ellipse([tx + 44, 32, tx + 62, 50], fill="#ffd524", outline="#181624", width=2)
    ing_sheet.save(SPRITES_DIR / "rhythm_kitchen" / "ingredients.png")
    print("Generated rhythm_kitchen/ingredients.png")

def build_common_ui():
    # Feedback Badges: PERFECT!, GOOD!, MISS!
    bw, bh = 220, 64
    fb_sheet = Image.new("RGBA", (bw * 3, bh), (0, 0, 0, 0))
    fdraw = ImageDraw.Draw(fb_sheet)
    # 0: PERFECT!
    fdraw.rounded_rectangle([8, 8, bw - 8, bh - 8], radius=16, fill="#ffd524", outline="#181624", width=4)
    # 1: GOOD!
    fdraw.rounded_rectangle([bw + 8, 8, bw * 2 - 8, bh - 8], radius=16, fill="#4cc9f0", outline="#181624", width=4)
    # 2: MISS!
    fdraw.rounded_rectangle([bw * 2 + 8, 8, bw * 3 - 8, bh - 8], radius=16, fill="#ff477e", outline="#181624", width=4)
    fb_sheet.save(SPRITES_DIR / "common" / "feedback.png")
    print("Generated common/feedback.png")

    # Stars & Notes
    nw, nh = 64, 64
    sn_sheet = Image.new("RGBA", (nw * 4, nh), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(sn_sheet)
    # 0: Gold Star
    sdraw.regular_polygon((nw//2, nh//2, 24), n_sides=5, fill="#ffd524", outline="#181624")
    # 1: Pink Star
    sdraw.regular_polygon((nw + nw//2, nh//2, 24), n_sides=5, fill="#ff477e", outline="#181624")
    # 2: Cyan Star
    sdraw.regular_polygon((nw * 2 + nw//2, nh//2, 24), n_sides=5, fill="#4cc9f0", outline="#181624")
    # 3: Sparkle Diamond
    sdraw.polygon([(nw*3 + nw//2, 8), (nw*3 + nw - 10, nh//2), (nw*3 + nw//2, nh - 8), (nw*3 + 10, nh//2)], fill="#ffffff", outline="#181624")
    sn_sheet.save(SPRITES_DIR / "common" / "stars_notes.png")
    print("Generated common/stars_notes.png")

if __name__ == "__main__":
    ensure_dirs()
    build_backgrounds()
    build_beat_factory_sprites()
    build_echo_planet_sprites()
    build_rhythm_kitchen_sprites()
    build_common_ui()
    print("ALL SPRITE SHEETS & TEXTURES GENERATED SUCCESSFULLY!")
