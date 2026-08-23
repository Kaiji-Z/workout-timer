#!/usr/bin/env python
"""Generate the GitHub social preview (1280x640) for WorkoutTimer.

Design: Flat Vitality — warm amber gradient ("汗水") + deep indigo accents
("冷静"), flat shapes, no glow. Regenerate with:
    python scripts/make_social_preview.py

The phone mockup is composed inside-out from one set of concentric insets
(screen -> white bezel -> indigo frame), drawn at 4x supersampling so every
rounded corner is smooth and the frame border is uniform by construction.
A self-check at the end measures the visible indigo border on all four
sides and fails loudly if it is not uniform.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "promotion" / "social-preview.png"

W, H = 1280, 640
AMBER_TOP = (255, 183, 77)    # #FFB74D
AMBER_BOT = (255, 167, 38)    # #FFA726
INDIGO = (26, 35, 126)        # #1A237E
INK = (33, 33, 33)            # #212121
WHITE = (255, 255, 255)

F_CN_BOLD = "C:/Windows/Fonts/msyhbd.ttc"
F_CN = "C:/Windows/Fonts/msyh.ttc"
F_EN = str(ROOT / "fonts" / "Rajdhani-SemiBold-5.ttf")

SS = 4          # supersample factor for rounded shapes
SHOT_H = 524    # screenshot height in final px; width follows source aspect
BEZEL = 8       # white bezel around the screenshot
BORDER = 6      # visible indigo frame around the bezel
R_SCREEN, R_BEZEL, R_FRAME = 26, 34, 40  # concentric: 26 + 8 = 34 + 6 = 40
PX, PY = 940, 44  # top-left of the phone frame on the canvas


def gradient(w: int, h: int) -> Image.Image:
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        for x in range(w):
            t = x / w * 0.35 + y / h * 0.65
            px[x, y] = tuple(int(a + (b - a) * t) for a, b in zip(AMBER_TOP, AMBER_BOT))
    return img


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius, fill=255)
    return m


def build_phone() -> tuple[Image.Image, int, int]:
    """Return the phone mockup (frame+bezel+screen) and its final size."""
    src = Image.open(ROOT / "docs" / "screenshots" / "timer.jpg").convert("RGB")
    shot_w = round(SHOT_H * src.width / src.height)
    shot = src.resize((shot_w * SS, SHOT_H * SS), Image.LANCZOS)

    out_w = shot_w + 2 * (BEZEL + BORDER)
    out_h = SHOT_H + 2 * (BEZEL + BORDER)

    phone = Image.new("RGBA", (out_w * SS, out_h * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(phone)
    # Indigo frame (outermost) -> white bezel -> screenshot. One inset chain,
    # so corner centers coincide by construction (40 = 34 + 6 = 26 + 8 + 6).
    d.rounded_rectangle(
        [0, 0, out_w * SS - 1, out_h * SS - 1], R_FRAME * SS, fill=INDIGO + (255,)
    )
    inset1 = BORDER * SS
    d.rounded_rectangle(
        [inset1, inset1, out_w * SS - 1 - inset1, out_h * SS - 1 - inset1],
        R_BEZEL * SS, fill=WHITE + (255,),
    )
    inset2 = (BORDER + BEZEL) * SS
    phone.paste(shot, (inset2, inset2), rounded_mask(shot.size, R_SCREEN * SS))

    return phone.resize((out_w, out_h), Image.LANCZOS), out_w, out_h


def build_button() -> Image.Image:
    """White circular control button with indigo play triangle (brand echo)."""
    r = 44
    pad = 8
    size = (r + pad) * 2
    btn = Image.new("RGBA", (size * SS, size * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(btn)
    d.ellipse([pad * SS, pad * SS, (pad + 2 * r) * SS - 1, (pad + 2 * r) * SS - 1], fill=WHITE + (255,))
    cx = cy = size * SS // 2
    d.polygon(
        [(cx - 10 * SS, cy - 16 * SS), (cx - 10 * SS, cy + 16 * SS), (cx + 18 * SS, cy)],
        fill=INDIGO + (255,),
    )
    return btn.resize((size, size), Image.LANCZOS)


def text_w(draw: ImageDraw.ImageDraw, s: str, font: ImageFont.FreeTypeFont) -> int:
    return draw.textbbox((0, 0), s, font=font)[2]


def check_uniform_frame(im: Image.Image, out_w: int, out_h: int) -> None:
    """Measure the visible indigo border on all four sides; fail if uneven."""
    px = im.load()
    cy, cx = PY + out_h // 2, PX + out_w // 2

    def is_indigo(p):
        return abs(p[0] - INDIGO[0]) < 30 and abs(p[1] - INDIGO[1]) < 30 and abs(p[2] - INDIGO[2]) < 40

    def is_white(p):
        return all(v > 235 for v in p[:3])

    widths = {}
    # Left: walk right from outside the frame until white bezel starts.
    x, n = PX - 3, 0
    while not is_indigo(px[x, cy]):
        x += 1
    while not is_white(px[x, cy]):
        n += 1
        x += 1
    widths["left"] = n
    # Right: walk left.
    x, n = PX + out_w + 2, 0
    while not is_indigo(px[x, cy]):
        x -= 1
    while not is_white(px[x, cy]):
        n += 1
        x -= 1
    widths["right"] = n
    # Top / bottom on the vertical center line.
    y, n = PY - 3, 0
    while not is_indigo(px[cx, y]):
        y += 1
    while not is_white(px[cx, y]):
        n += 1
        y += 1
    widths["top"] = n
    y, n = PY + out_h + 2, 0
    while not is_indigo(px[cx, y]):
        y -= 1
    while not is_white(px[cx, y]):
        n += 1
        y -= 1
    widths["bottom"] = n
    print(f"frame border widths: {widths}")
    if len(set(widths.values())) != 1:
        raise SystemExit("FAIL: indigo frame is not uniform — fix the insets")


def main() -> None:
    bg = gradient(W, H).convert("RGBA")

    # Decorative flat circles behind the phone (white at low alpha, per app theme).
    deco = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dd = ImageDraw.Draw(deco)
    dd.ellipse([820, -180, 1380, 380], fill=(255, 255, 255, 24))
    dd.ellipse([1010, 380, 1420, 790], fill=(255, 255, 255, 16))
    bg = Image.alpha_composite(bg, deco)

    phone, out_w, out_h = build_phone()

    # Flat soft shadow (separation, not glow).
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle(
        [PX + 10, PY + 16, PX + 10 + out_w, PY + 16 + out_h], R_FRAME, fill=(60, 40, 10, 70)
    )
    bg = Image.alpha_composite(bg, sh.filter(ImageFilter.GaussianBlur(14)))
    bg.paste(phone, (PX, PY), phone)

    # White circular control button, overlapping the phone's lower-left frame.
    btn = build_button()
    bx, by = PX - 34, PY + out_h - 110
    bsh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(bsh).ellipse(
        [bx + 4, by + 8, bx + 2 * 44 + 4, by + 2 * 44 + 8], fill=(60, 40, 10, 80)
    )
    bg = Image.alpha_composite(bg, bsh.filter(ImageFilter.GaussianBlur(8)))
    bg.paste(btn, (bx - 8, by - 8), btn)

    # ---- Text block -----------------------------------------------------
    d = ImageDraw.Draw(bg)
    f_pill = ImageFont.truetype(F_CN_BOLD, 24)
    f_title = ImageFont.truetype(F_CN_BOLD, 92)
    f_en = ImageFont.truetype(F_EN, 52)
    f_tag = ImageFont.truetype(F_CN_BOLD, 38)
    f_feat = ImageFont.truetype(F_CN, 28)
    f_repo = ImageFont.truetype(F_EN, 30)

    x0 = 84
    pill_t = "免费开源 · FREE & OPEN SOURCE"
    tw = text_w(d, pill_t, f_pill)
    pw, phh = tw + 48, 46
    py0 = 96
    d.rounded_rectangle([x0, py0, x0 + pw, py0 + phh], phh // 2, fill=INDIGO)
    d.text((x0 + 24, py0 + 8), pill_t, font=f_pill, fill=WHITE)

    d.text((x0, 168), "撸铁计时器", font=f_title, fill=INK)
    d.text((x0 + 6, 286), "WORKOUT TIMER", font=f_en, fill=INDIGO)

    d.text((x0, 386), "组间休息，精准掌控", font=f_tag, fill=INK)
    d.text((x0 + 4, 452), "870+ 动作库 · AI 训练计划 · 数据不出手机", font=f_feat, fill=INK)
    d.text((x0 + 4, 548), "github.com/Kaiji-Z/workout-timer", font=f_repo, fill=INDIGO)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    bg.convert("RGB").save(OUT, "PNG")
    print(f"saved {OUT} ({W}x{H})")
    check_uniform_frame(bg.convert("RGB"), out_w, out_h)


if __name__ == "__main__":
    main()
