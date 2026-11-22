from PIL import Image, ImageDraw, ImageFont, ImageFilter
FT="/usr/share/fonts/truetype/google-fonts/ofl/cardo/Cardo-Bold.ttf"
GOLD=(255,220,150)
import os
LAN=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "art", "lantern_logo.png")
def make_logo(lines=("Lanterne des","Profondeurs"), size=200, lantern=True, stacked=False):
    """Logo détouré (RGBA), à grande taille."""
    W,H=4000,1600
    f=ImageFont.truetype(FT,size)
    d0=ImageDraw.Draw(Image.new("RGBA",(10,10)))
    bbs=[d0.textbbox((0,0),t,font=f) for t in lines]
    gap=int(size*0.08)
    tw=max(b[2]-b[0] for b in bbs); th=sum(b[3]-b[1] for b in bbs)+gap*(len(lines)-1)
    lan=None
    if lantern:
        lan=Image.open(LAN).convert("RGBA")
        lsz=int(th*1.1) if not stacked else int(size*1.6)
        lan=lan.resize((lsz,lsz),Image.LANCZOS)
    if stacked or not lan:
        total_w=tw; tx=(W-tw)//2; ty=(H-th)//2 + (lan.height//2 if lan else 0)
        lx=(W-lan.width)//2 if lan else 0; ly=ty-lan.height-int(size*0.1) if lan else 0
    else:
        sep=int(size*0.3); total_w=tw+lan.width+sep
        x0=(W-total_w)//2; tx=x0+lan.width+sep; ty=(H-th)//2; lx=x0; ly=ty+(th-lan.height)//2
    im=Image.new("RGBA",(W,H),(0,0,0,0))
    sh=Image.new("RGBA",(W,H),(0,0,0,0)); s=ImageDraw.Draw(sh)
    gl=Image.new("RGBA",(W,H),(0,0,0,0)); g=ImageDraw.Draw(gl)
    pos=[]; y=ty
    for t,b in zip(lines,bbs):
        px=tx+(tw-(b[2]-b[0]))//2-b[0]; py=y-b[1]; pos.append((px,py,t)); y+=b[3]-b[1]+gap
        s.text((px,py+int(size*0.05)),t,font=f,fill=(0,0,0,235),stroke_width=size//30,stroke_fill=(0,0,0,235))
        g.text((px,py),t,font=f,fill=(255,150,50,170))
    if lan:
        hl=Image.new("RGBA",(W,H),(0,0,0,0)); cx,cy=lx+lan.width/2,ly+lan.height*0.55; r=lan.width*0.75
        ImageDraw.Draw(hl).ellipse([cx-r,cy-r,cx+r,cy+r],fill=(255,160,60,110))
        im=Image.alpha_composite(im,hl.filter(ImageFilter.GaussianBlur(lan.width*0.3)))
    im=Image.alpha_composite(im,sh.filter(ImageFilter.GaussianBlur(size*0.07)))
    im=Image.alpha_composite(im,gl.filter(ImageFilter.GaussianBlur(size*0.18)))
    d=ImageDraw.Draw(im)
    for px,py,t in pos:
        d.text((px,py),t,font=f,fill=GOLD,stroke_width=max(2,size//45),stroke_fill=(60,35,12))
    if lan: im.alpha_composite(lan,(int(lx),int(ly)))
    a=im.getchannel("A").point(lambda v:255 if v>8 else 0)
    return im.crop(a.getbbox())
def fit(logo, box_w, box_h):
    r=min(box_w/logo.width, box_h/logo.height)
    return logo.resize((int(logo.width*r),int(logo.height*r)),Image.LANCZOS)
