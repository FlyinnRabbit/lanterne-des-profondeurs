# Logo : lanterne médiévale (dessin vectoriel en PIL, rendu à 4x puis réduit)
from PIL import Image, ImageDraw, ImageFilter
import math, sys
S = 2048
def lerp(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))

def lantern(bg=True):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = S // 2
    if bg:
        # fond : carré arrondi bleu nuit avec halo chaud
        mask = Image.new("L", (S, S), 0)
        ImageDraw.Draw(mask).rounded_rectangle([40, 40, S - 40, S - 40], radius=360, fill=255)
        base = Image.new("RGBA", (S, S), (10, 12, 26, 255))
        glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        for r in range(900, 0, -12):
            t = r / 900
            a = int(200 * (1 - t) ** 1.5)
            gd.ellipse([cx - r, 1180 - r, cx + r, 1180 + r], fill=(255, 170, 70, a))
        base = Image.alpha_composite(base, glow)
        img.paste(base, (0, 0), mask)
        d = ImageDraw.Draw(img)
        ImageDraw.Draw(img).rounded_rectangle([40, 40, S - 40, S - 40], radius=360, outline=(90, 110, 160, 255), width=18)
    iron = (52, 47, 56, 255)
    iron_hi = (120, 112, 124, 255)
    # anneau et crochet
    d.ellipse([cx - 120, 150, cx + 120, 390], outline=iron, width=46)
    d.rectangle([cx - 28, 370, cx + 28, 470], fill=iron)
    # toit pyramidal à pans + fleuron
    d.polygon([(cx, 430), (cx + 360, 760), (cx - 360, 760)], fill=iron)
    d.polygon([(cx, 430), (cx + 130, 760), (cx - 130, 760)], fill=(52, 47, 55, 255))
    for k in (-1, 1):
        d.line([(cx, 440), (cx + k * 360, 760)], fill=iron_hi, width=14)
    d.rectangle([cx - 400, 740, cx + 400, 820], fill=iron)
    d.rectangle([cx - 400, 740, cx + 400, 760], fill=iron_hi)
    # corps vitré : verre ambré dégradé
    top, bot = 820, 1560
    body = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    for y in range(top, bot):
        t = (y - top) / (bot - top)
        c = lerp((255, 214, 120), (230, 120, 40), t)
        w = 330 - int(40 * t)
        bd.line([(cx - w, y), (cx + w, y)], fill=c + (255,))
    # flamme et cœur lumineux
    fl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fl)
    for r in range(260, 0, -6):
        a = int(200 * (1 - r / 260) ** 1.2)
        fd.ellipse([cx - r, 1180 - r * 1.25, cx + r, 1180 + r * 0.9], fill=(255, 250, 220, a))
    body = Image.alpha_composite(body, fl.filter(ImageFilter.GaussianBlur(20)))
    bd = ImageDraw.Draw(body)
    # flamme
    flame = [(cx, 960), (cx + 70, 1120), (cx + 60, 1220), (cx, 1270), (cx - 60, 1220), (cx - 70, 1120)]
    bd.polygon(flame, fill=(255, 255, 235, 255))
    bd.polygon([(cx, 1060), (cx + 32, 1160), (cx, 1235), (cx - 32, 1160)], fill=(255, 190, 80, 255))
    # bougie
    bd.rectangle([cx - 70, 1270, cx + 70, 1520], fill=(245, 232, 200, 255))
    bd.ellipse([cx - 70, 1250, cx + 70, 1290], fill=(255, 245, 220, 255))
    bd.line([(cx, 1240), (cx, 1275)], fill=(60, 40, 30, 255), width=10)
    img = Image.alpha_composite(img, body)
    d = ImageDraw.Draw(img)
    # montants et barreaux en fer forgé
    for k in (-1, 1):
        d.line([(cx + k * 345, 800), (cx + k * 305, 1580)], fill=iron, width=58)
        d.line([(cx + k * 350, 800), (cx + k * 312, 1580)], fill=iron_hi, width=12)
    for k in (-0.5, 0.5):
        x0 = cx + int(k * 330); x1 = cx + int(k * 290)
        d.line([(x0, 820), (x1, 1560)], fill=iron, width=26)
    for y in (1010, 1330):
        w = 340 - int(40 * (y - 820) / 740)
        d.line([(cx - w, y), (cx + w, y)], fill=iron, width=24)
    # croisillons décoratifs (losanges) en haut des vitres
    for k in (-1, 0, 1):
        x = cx + k * 165
        d.polygon([(x, 850), (x + 40, 900), (x, 950), (x - 40, 900)], outline=iron, width=14)
    # base
    d.rectangle([cx - 380, 1560, cx + 380, 1650], fill=iron)
    d.rectangle([cx - 380, 1560, cx + 380, 1580], fill=iron_hi)
    d.polygon([(cx - 330, 1650), (cx + 330, 1650), (cx + 260, 1740), (cx - 260, 1740)], fill=iron)
    for k in (-1, 1):
        d.ellipse([cx + k * 240 - 50, 1720, cx + k * 240 + 50, 1800], fill=iron)
    return img

full = lantern(True)
out = sys.argv[1]
full.resize((1024, 1024), Image.LANCZOS).save(f"{out}/icon_1024.png")
full.resize((256, 256), Image.LANCZOS).save(f"{out}/icon.png")
lantern(False).resize((512, 512), Image.LANCZOS).save(f"{out}/lantern_logo.png")
ico = full.resize((256, 256), Image.LANCZOS)
ico.save(f"{out}/icon.ico", sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
print("ok")
