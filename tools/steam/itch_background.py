from PIL import Image, ImageDraw, ImageEnhance
import sys
W,H,COL=2560,1440,960
BG=(14,12,20)
K="/tmp/keyart/"
def side(name,x0):
    im=Image.open(K+name).convert("RGB").crop((x0,0,x0+1200,2160)).resize((800,1440),Image.LANCZOS)
    return ImageEnhance.Brightness(im).enhance(1.05)
out=Image.new("RGB",(W,H),BG)
L=side("biome_cristal.png",1100); R=side("biome_forge.png",1160)
side_w=(W-COL)//2
def mask(inner_left):
    m=Image.new("L",(800,1440),255); d=ImageDraw.Draw(m)
    for i in range(800):
        # distance au bord intérieur (côté colonne) : fondu sur 320 px ; bord extérieur : fondu léger 120 px
        di=(799-i) if inner_left==False else i
        do=i if inner_left==False else 799-i
        a=min(1.0,di/320.0)*min(1.0,0.35+do/185.0)
        d.line([(i,0),(i,1439)],fill=int(255*a))
    # fondu vers le bas
    v=Image.new("L",(800,1440),255); dv=ImageDraw.Draw(v)
    for y in range(1440):
        dv.line([(0,y),(799,y)],fill=int(255*min(1.0,(1439-y)/420.0)))
    from PIL import ImageChops
    return ImageChops.multiply(m,v)
out.paste(L,(0,0),mask(False))
out.paste(R,(W-800,0),mask(True))
out.save(sys.argv[1],quality=90)
