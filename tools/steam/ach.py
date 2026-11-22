from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps, ImageEnhance
import math
EMO = ImageFont.truetype("/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf", 109)
ICONS = {
 "palier1": "👣", "palier3": "🪜", "palier6": "🕳️", "final": "🏮", "finals4": "👑", "flawless": "🛡️",
 "perfect10": "⚔️", "crit50": "💥", "plunge": "☄️", "shade": "👻", "rich": "💎", "arsenal": "🗡️",
 "forge": "🔨", "charms": "📿", "curse": "💀", "daily": "☀️", "rush": "⏱️", "room": "🗝️",
 "palier10": "🌀", "nightmare": "😈", "kills500": "🎯", "elite25": "🐺", "parry100": "🧱",
 "trophy": "🏆", "wardrobe": "🧥", "fashion": "🎩", "noel": "🎄", "gift": "🎁", "calendar": "🎉",
}
S = 256
def emoji(ch):
    im = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
    ImageDraw.Draw(im).text((80, 80), ch, font=EMO, embedded_color=True, anchor="mm")
    bb = im.getchannel("A").getbbox()
    return im.crop(bb) if bb else im
def medal(ch, unlocked=True):
    s = 4
    W = S * s
    im = Image.new("RGBA", (W, W), (12, 10, 16, 255))
    d = ImageDraw.Draw(im)
    c = W / 2
    # fond : vignette chaude
    halo = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(halo).ellipse([c - W * 0.5, c - W * 0.5, c + W * 0.5, c + W * 0.5], fill=(255, 150, 60, 60) if unlocked else (90, 100, 130, 40))
    im = Image.alpha_composite(im, halo.filter(ImageFilter.GaussianBlur(W * 0.12)))
    d = ImageDraw.Draw(im)
    R = W * 0.44
    ring = (196, 150, 72) if unlocked else (92, 96, 110)
    ring_hi = (250, 214, 140) if unlocked else (140, 145, 160)
    d.ellipse([c - R, c - R, c + R, c + R], fill=ring)
    d.ellipse([c - R + W * 0.012, c - R + W * 0.012, c + R - W * 0.03, c + R - W * 0.03], outline=ring_hi, width=int(W * 0.012))
    r2 = R * 0.84
    inner = (34, 28, 40) if unlocked else (26, 27, 32)
    d.ellipse([c - r2, c - r2, c + r2, c + r2], fill=inner, outline=(60, 40, 20) if unlocked else (40, 42, 48), width=int(W * 0.01))
    # petits rivets
    for k in range(12):
        a = k * math.tau / 12
        px, py = c + math.cos(a) * R * 0.92, c + math.sin(a) * R * 0.92
        rr = W * 0.012
        d.ellipse([px - rr, py - rr, px + rr, py + rr], fill=ring_hi)
    # pictogramme : l'emoji en relief doré (ou gris éteint)
    e = emoji(ch)
    sc = (r2 * 1.15) / max(e.size)
    e = e.resize((int(e.width * sc), int(e.height * sc)), Image.LANCZOS)
    a = e.getchannel("A")
    g = ImageOps.grayscale(e.convert("RGB"))
    g = ImageOps.autocontrast(g, cutoff=2)
    if unlocked:
        col = ImageOps.colorize(g, black=(110, 60, 18), white=(255, 236, 180), mid=(225, 170, 80))
    else:
        col = ImageOps.colorize(g, black=(40, 42, 50), white=(140, 145, 158), mid=(85, 88, 100))
    glyph = col.convert("RGBA"); glyph.putalpha(a)
    shadow = Image.new("RGBA", glyph.size, (0, 0, 0, 0)); shadow.putalpha(a.point(lambda v: int(v * 0.8)))
    ox, oy = int(c - glyph.width / 2), int(c - glyph.height / 2)
    sh = Image.new("RGBA", (W, W), (0, 0, 0, 0)); sh.alpha_composite(shadow, (ox + int(W * 0.012), oy + int(W * 0.018)))
    im = Image.alpha_composite(im, sh.filter(ImageFilter.GaussianBlur(W * 0.01)))
    if unlocked:
        gl = Image.new("RGBA", (W, W), (0, 0, 0, 0)); gg = Image.new("RGBA", glyph.size, (255, 170, 70, 0)); gg.putalpha(a.point(lambda v: int(v * 0.6)))
        gl.alpha_composite(gg, (ox, oy)); im = Image.alpha_composite(im, gl.filter(ImageFilter.GaussianBlur(W * 0.03)))
    im.alpha_composite(glyph, (ox, oy))
    return im.resize((S, S), Image.LANCZOS).convert("RGB")
if __name__ == "__main__":
    import os; os.makedirs("ach", exist_ok=True)
    for id, ch in ICONS.items():
        medal(ch, True).save(f"ach/ACH_{id.upper()}.jpg", quality=92)
        medal(ch, False).save(f"ach/ACH_{id.upper()}_locked.jpg", quality=92)
    ids = list(ICONS)
    sheet = Image.new("RGB", (10 * 128, 6 * 128), (20, 20, 24))
    for i, id in enumerate(ids):
        sheet.paste(Image.open(f"ach/ACH_{id.upper()}.jpg").resize((128, 128)), ((i % 10) * 128, (i // 10) * 128 * 2 // 2 if False else (i // 10) * 256))
        sheet.paste(Image.open(f"ach/ACH_{id.upper()}_locked.jpg").resize((128, 128)), ((i % 10) * 128, (i // 10) * 256 + 128))
    sheet.save("_ach_sheet.jpg", quality=88)
