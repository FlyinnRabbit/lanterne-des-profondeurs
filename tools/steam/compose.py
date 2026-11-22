import sys, os
from PIL import Image, ImageEnhance, ImageFilter, ImageDraw
sys.path.insert(0, os.path.dirname(__file__)); from logo import make_logo, fit
K="/tmp/keyart/"
O="out/"
os.makedirs(O + "screenshots", exist_ok=True)
def load(n, crop960, size, gamma=1.0, bright=1.0):
    im=Image.open(K+n+".png").convert("RGB")
    x0,y0,x1,y1=[v*4 for v in crop960]
    im=im.crop((x0,y0,x1,y1)).resize(size, Image.LANCZOS)
    if bright!=1.0: im=ImageEnhance.Brightness(im).enhance(bright)
    return im.convert("RGBA")
def shade(im, side, strength=170, frac=0.55):
    """assombrit progressivement un côté (pour la lisibilité du logo)"""
    w,h=im.size; g=Image.new("L",(w,h),0); d=ImageDraw.Draw(g)
    if side in ("right","left"):
        n=int(w*frac)
        for i in range(n):
            a=int(strength*(i/n)**1.4)
            x=w-n+i if side=="right" else n-1-i
            d.line([(x,0),(x,h)],fill=a)
    else:
        n=int(h*frac)
        for i in range(n):
            a=int(strength*(1-i/n)**1.4)
            y=i if side=="top" else h-1-i
            d.line([(0,y),(w,y)],fill=a)
    dark=Image.new("RGBA",(w,h),(5,4,10,255)); dark.putalpha(g)
    return Image.alpha_composite(im,dark)
def place(im, logo, box):
    x,y,w,h=box; f=fit(logo,w,h); im.alpha_composite(f,(int(x+(w-f.width)/2),int(y+(h-f.height)/2))); return im
# python3 compose.py [en] : « en » produit les visuels avec le titre anglais (dossier out/en/)
TITLES={"fr": ("Lanterne des","Profondeurs"), "en": ("Lantern of","the Depths")}
LANG=sys.argv[1] if len(sys.argv) > 1 else "fr"
if LANG == "itch":
    LANG = "fr"; ITCH = True
else:
    ITCH = False
if LANG != "fr":
    O=O+LANG+"/"
    os.makedirs(O, exist_ok=True)
LOGO=make_logo(TITLES[LANG])
LOGO_ST=make_logo(TITLES[LANG], stacked=True)
LOGO_TXT=make_logo(TITLES[LANG], lantern=False)
# Capsule principale 1232x706 : l'Œil d'en Dessous et le héros, logo à droite
m=load("boss_oeil_1",(120,0,890,441),(1232,706),bright=1.08); m=shade(m,"right",200,0.5)
place(m,LOGO_ST,(700,90,510,520)); m.convert("RGB").save(O+"main_capsule_1232x706.jpg",quality=93)
# En-tête 920x430 (et en-tête de bibliothèque)
h=load("boss_oeil_1",(150,0,960,378),(920,430),bright=1.08); h=shade(h,"right",210,0.55)
place(h,LOGO_ST,(500,25,405,380)); h.convert("RGB").save(O+"header_capsule_920x430.jpg",quality=93)
h.convert("RGB").save(O+"library_header_920x430.jpg",quality=93)
# Petite capsule 462x174 : le logo remplit presque tout
s=load("boss_oeil_1",(150,40,850,304),(462,174),bright=0.35)
s=place(s,LOGO_TXT,(10,8,442,158)); s.convert("RGB").save(O+"small_capsule_462x174.jpg",quality=93)
# Verticale 748x896 : la Lanterne au-dessus du Sanctuaire
v=load("title_1",(425,0,876,540),(748,896),bright=1.15); v=shade(v,"top",120,0.3)
place(v,LOGO_TXT,(40,40,668,200)); v.convert("RGB").save(O+"vertical_capsule_748x896.jpg",quality=93)
# Capsule de bibliothèque 600x900
c=load("title_1",(470,0,830,540),(600,900),bright=1.15); c=shade(c,"top",120,0.3)
place(c,LOGO_TXT,(30,40,540,190)); c.convert("RGB").save(O+"library_capsule_600x900.jpg",quality=93)
if LANG != "fr":
    lg=Image.new("RGBA",(1280,720),(0,0,0,0)); place(lg,LOGO,(50,100,1180,520)); lg.save(O+"library_logo_1280x720.png")
    print("ok", LANG); sys.exit(0)
# Héros de bibliothèque 3840x1240 (sans texte)
hero=load("boss_chevalier_1",(0,190,960,500),(3840,1240),bright=1.1)
hero.convert("RGB").save(O+"library_hero_3840x1240.png")
# Logo de bibliothèque 1280x720 (fond transparent)
lg=Image.new("RGBA",(1280,720),(0,0,0,0)); place(lg,LOGO,(50,100,1180,520)); lg.save(O+"library_logo_1280x720.png")
# Fond de page 1438x810 (facultatif) : mine de cristal assombrie et floue
bg=load("biome_cristal",(0,0,960,540),(1438,810)); bg=ImageEnhance.Brightness(bg.filter(ImageFilter.GaussianBlur(6))).enhance(0.45)
bg.convert("RGB").save(O+"page_background_1438x810.jpg",quality=90)
# Icône 184x184
ic=Image.new("RGBA",(184,184),(14,12,20,255)); lan=Image.open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "art", "lantern_logo.png")).convert("RGBA")
halo=Image.new("RGBA",(184,184),(0,0,0,0)); ImageDraw.Draw(halo).ellipse([22,22,162,162],fill=(255,160,60,110)); ic=Image.alpha_composite(ic,halo.filter(ImageFilter.GaussianBlur(22)))
place(ic,lan,(17,12,150,160)); ic.convert("RGB").save(O+"app_icon_184x184.jpg",quality=95)
# Captures 1920x1080
shots=["boss_oeil_1","boss_chevalier_1","biome_forge","boss_reine_3","biome_cristal","boss_gardien_0","biome_bibliotheque","boss_cerbere_0","biome_glace","biome_citadelle","biome_jardins","title_1"]
for i,n in enumerate(shots):
    im=Image.open(K+n+".png").convert("RGB").resize((1920,1080),Image.LANCZOS)
    im=ImageEnhance.Brightness(im).enhance(1.08)
    im.save(O+"screenshots/%02d_%s.jpg"%(i+1,n),quality=92)
print("ok")

# --- itch.io : couverture 630x500 et bannière 960x300 (python3 compose.py itch)
def itch():
    out="out/itch/"; os.makedirs(out, exist_ok=True)
    L=make_logo(TITLES["fr"], stacked=True)
    cv=load("boss_oeil_1",(140,0,790,516),(630,500),bright=1.08); cv=shade(cv,"right",200,0.55)
    place(cv,L,(330,60,290,300)); cv.convert("RGB").save(out+"cover_630x500.jpg",quality=93)
    bn=load("boss_chevalier_1",(0,240,960,540),(960,300),bright=1.1); bn=shade(bn,"right",210,0.5)
    place(bn,make_logo(TITLES["fr"]),(560,40,380,220)); bn.convert("RGB").save(out+"banner_960x300.jpg",quality=93)
    print("ok itch")

if ITCH:
    itch()
