"""Google Play graphics: 512x512 icon and 1024x500 feature graphic (no alpha).
Usage: python scripts/make_play_graphics.py <materialicons-regular.otf> <roboto-bold.ttf>"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONS, BOLD = sys.argv[1], sys.argv[2]
out = os.path.join(ROOT, "store", "play")
os.makedirs(out, exist_ok=True)

icon = Image.open(os.path.join(ROOT, "store", "icon-1024.png")).convert("RGB")
icon.resize((512, 512), Image.LANCZOS).save(os.path.join(out, "icon-512.png"))

W, H = 1024, 500
fg = Image.new("RGB", (W, H))
top, bottom = (232, 58, 76), (150, 18, 38)
px = fg.load()
for y in range(H):
    for x in range(W):
        t = (x / W * 0.6 + y / H * 0.4)
        px[x, y] = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
d = ImageDraw.Draw(fg)
d.text((230, H / 2 + 8), chr(0xE596), font=ImageFont.truetype(ICONS, 380), fill=(255, 255, 255), anchor="mm")
d.text((230, H / 2 - 4), chr(0xE4A6), font=ImageFont.truetype(ICONS, 180), fill=(206, 32, 52), anchor="mm")
d.text((440, 190), "Blacklist", font=ImageFont.truetype(BOLD, 96), fill=(255, 255, 255), anchor="lm")
d.text((444, 290), "Call Blocker", font=ImageFont.truetype(BOLD, 64), fill=(255, 225, 228), anchor="lm")
d.text((446, 370), "Stop spam & scam calls", font=ImageFont.truetype(BOLD, 34), fill=(255, 205, 210), anchor="lm")
fg.save(os.path.join(out, "feature-graphic.png"))
print("ok", out)
