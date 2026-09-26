"""App icon: white shield with a crossed-out phone on the brand red gradient.
Writes store/icon-1024.png (no alpha, as Apple requires) and the iOS/Android icon sets.
Usage: python scripts/make_icon.py <path to materialicons-regular.otf>"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = sys.argv[1]
S = 1024

bg = Image.new("RGB", (S, S))
top, bottom = (232, 58, 76), (150, 18, 38)
px = bg.load()
for y in range(S):
    for x in range(S):
        t = (x * 0.35 + y * 0.65) / S
        px[x, y] = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))

draw = ImageDraw.Draw(bg)
shield = ImageFont.truetype(FONT, 820)
draw.text((S / 2, S / 2 + 10), chr(0xE596), font=shield, fill=(255, 255, 255), anchor="mm")
phone = ImageFont.truetype(FONT, 400)
draw.text((S / 2, S / 2 - 10), chr(0xE4A6), font=phone, fill=(206, 32, 52), anchor="mm")

os.makedirs(os.path.join(ROOT, "store"), exist_ok=True)
bg.save(os.path.join(ROOT, "store", "icon-1024.png"))

ios = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
for image in json.load(open(os.path.join(ios, "Contents.json")))["images"]:
    name = image.get("filename")
    if not name:
        continue
    size = round(float(image["size"].split("x")[0]) * int(image["scale"].rstrip("x")))
    bg.resize((size, size), Image.LANCZOS).save(os.path.join(ios, name))

res = os.path.join(ROOT, "android", "app", "src", "main", "res")
for folder, size in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
    bg.resize((size, size), Image.LANCZOS).save(os.path.join(res, f"mipmap-{folder}", "ic_launcher.png"))
print("icons written")
