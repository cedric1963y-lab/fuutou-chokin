"""App icon for 封筒貯金: two kraft envelopes on a deep green ground, the front
one with its flap open and a gold ¥ coin rising out of it."""
import math, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont

S = 4096
k = S / 1024
def r(v): return int(round(v * k))
SHIFT = 56  # content is drawn low; crop shifts it up to optical centre
H = S + r(SHIFT)

img = Image.new("RGB", (S, H))
d = ImageDraw.Draw(img)
top, bot = (52, 104, 88), (30, 70, 60)
for y in range(H):
    t = y / (H - 1)
    d.line([(0, y), (S, y)], fill=tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)))

def kraft_layer(poly, base, seed):
    """Fill a polygon with kraft color + fibers, return (layer, mask)."""
    layer = Image.new("RGB", (S, H), base)
    rnd = random.Random(seed)
    ld = ImageDraw.Draw(layer)
    for _ in range(5000):
        x, y = rnd.uniform(0, S), rnd.uniform(0, H)
        a = rnd.uniform(0, math.pi); L = rnd.uniform(r(5), r(22))
        c = tuple(max(0, min(255, base[i] + rnd.randint(-26, 22))) for i in range(3))
        ld.line([(x, y), (x + math.cos(a) * L, y + math.sin(a) * L)], fill=c, width=rnd.randint(2, 4))
    mask = Image.new("L", (S, H), 0)
    ImageDraw.Draw(mask).polygon(poly, fill=255)
    return layer, mask

def shadow(poly, off=(14, 26), blur=30, alpha=120):
    sh = Image.new("L", (S, H), 0)
    ImageDraw.Draw(sh).polygon([(x + r(off[0]), y + r(off[1])) for x, y in poly], fill=alpha)
    return sh.filter(ImageFilter.GaussianBlur(r(blur)))

def rot(points, cx, cy, deg):
    a = math.radians(deg)
    return [(cx + (x - cx) * math.cos(a) - (y - cy) * math.sin(a),
             cy + (x - cx) * math.sin(a) + (y - cy) * math.cos(a)) for x, y in points]

# back envelope (tilted, darker kraft)
bx0, by0, bx1, by1 = r(150), r(330), r(700), r(700)
back = rot([(bx0, by0), (bx1, by0), (bx1, by1), (bx0, by1)], r(425), r(515), -12)
img = Image.composite(Image.new("RGB", (S, H), (10, 30, 25)), img, shadow(back))
layer, mask = kraft_layer(back, (176, 128, 80), 3)
img = Image.composite(layer, img, mask)
d = ImageDraw.Draw(img)
bflap = rot([(bx0, by0), (bx1, by0), (r(425), r(530))], r(425), r(515), -12)
d.line(bflap + [bflap[0]], fill=(132, 92, 54), width=r(7))

# front envelope body
fx0, fy0, fx1, fy1 = r(250), r(470), r(880), r(890)
cx = (fx0 + fx1) / 2
body = [(fx0, fy0), (fx1, fy0), (fx1, fy1), (fx0, fy1)]
img = Image.composite(Image.new("RGB", (S, H), (10, 30, 25)), img, shadow(body, (10, 30), 36, 140))

# open flap (behind the coin, pointing up)
flap = [(fx0, fy0), (fx1, fy0), (cx, r(250))]
layer, mask = kraft_layer(flap, (214, 170, 116), 7)
img = Image.composite(layer, img, mask)
d = ImageDraw.Draw(img)
d.line([(fx0, fy0), (cx, r(250)), (fx1, fy0)], fill=(160, 116, 70), width=r(6))

# coin rising out of the envelope
ccx, ccy, cr = cx, r(470), r(190)
coin = Image.new("RGB", (S, H))
cd = ImageDraw.Draw(coin)
for i in range(cr, 0, -4):
    t = i / cr
    col = (int(250 - 40 * t), int(214 - 60 * t), int(110 - 70 * t))
    cd.ellipse([ccx - i - r(30) * (1 - t), ccy - i - r(40) * (1 - t), ccx + i - r(30) * (1 - t), ccy + i - r(40) * (1 - t)], fill=col)
cmask = Image.new("L", (S, H), 0)
ImageDraw.Draw(cmask).ellipse([ccx - cr, ccy - cr, ccx + cr, ccy + cr], fill=255)
img = Image.composite(Image.new("RGB", (S, H), (20, 45, 38)), img, shadow([(ccx - cr, ccy), (ccx, ccy - cr), (ccx + cr, ccy), (ccx, ccy + cr)], (6, 14), 40, 90))
img = Image.composite(coin, img, cmask)
d = ImageDraw.Draw(img)
d.ellipse([ccx - cr, ccy - cr, ccx + cr, ccy + cr], outline=(170, 118, 30), width=r(12))
d.ellipse([ccx - cr * 0.78, ccy - cr * 0.78, ccx + cr * 0.78, ccy + cr * 0.78], outline=(250, 226, 150), width=r(8))
font = ImageFont.truetype("assets/fonts/KiwiMaru-Medium.ttf", r(240))
d.text((ccx + r(3), ccy + r(14)), "¥", font=font, fill=(236, 190, 90), anchor="mm")
d.text((ccx, ccy + r(8)), "¥", font=font, fill=(128, 82, 12), anchor="mm")

# front pocket (covers the lower half of the coin)
pocket = [(fx0, fy0), (cx, r(660)), (fx1, fy0), (fx1, fy1), (fx0, fy1)]
layer, mask = kraft_layer(pocket, (205, 158, 102), 11)
img = Image.composite(layer, img, mask)
d = ImageDraw.Draw(img)
d.line([(fx0, fy0), (cx, r(660)), (fx1, fy0)], fill=(150, 104, 60), width=r(7))
d.line([(fx0, fy1), (cx, r(700))], fill=(175, 128, 78), width=r(5))
d.line([(fx1, fy1), (cx, r(700))], fill=(175, 128, 78), width=r(5))
d.line([(fx0, fy0), (fx0, fy1), (fx1, fy1), (fx1, fy0)], fill=(150, 104, 60), width=r(6), joint="curve")

# little label tag on the pocket
tx0, ty0, tx1, ty1 = r(330), r(760), r(560), r(840)
d.rounded_rectangle([tx0, ty0, tx1, ty1], radius=r(10), fill=(252, 247, 236))
for i in range(3):
    y = ty0 + r(22) + i * r(19)
    d.line([(tx0 + r(24), y), (tx1 - r(24) - i * r(40), y)], fill=(176, 150, 120), width=r(8))
# red seal
d.ellipse([r(730), r(760), r(810), r(840)], fill=(180, 68, 46))

img = img.crop((0, r(SHIFT), S, r(SHIFT) + S)).resize((1024, 1024), Image.LANCZOS)
img.save("assets/icon/app_icon.png", optimize=True)
print("ok")
