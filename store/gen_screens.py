#!/usr/bin/env python3
# Generates faithful SVG renders of the Understated dial, matching the geometry
# in source/understatedView.mc (drawBackground/drawHands/drawDate/drawSecondHand).
# AMOLED full-color representation at S px. Pen widths scaled proportionally to
# the fr55-tuned design (sf = S/208) so proportions match the device look.
import math, os

S = 454                      # render size (square), AMOLED-class resolution
sf = S / 208.0               # scale vs the fr55 design the geometry was tuned on
cx = cy = S / 2.0
HOUR, MINUTE, SEC = 10, 10, 37
BATT = 0.65                  # battery fraction (0..1); discharged part is accented
DATE = "12"
NUMERALS = ["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII"]

def hx(v): return "#%06X" % v

# theme: (name, background, numerals, date, hands, battery_accent)  [AMOLED true hex]
THEMES = [
    ("1-blue",          0x0000FF, 0x00FFFF, 0xFFFFFF, 0xFFFFFF, 0xFF5500),
    ("2-green",         0x00FF00, 0xFFFF00, 0xFFFFFF, 0xFFFFFF, 0x0000AA),
    ("3-purple",        0xFF00FF, 0x00FFFF, 0xFFFFFF, 0xFFFFFF, 0x00AAFF),
    ("4-red",           0xFF0000, 0xFFFF00, 0xFFFFFF, 0xFFFFFF, 0x00FF00),
    ("5-yellow",        0xFFFF00, 0x000000, 0x000000, 0x000000, 0xFF0000),
    ("6-black_gold",    0x000000, 0xFFFF00, 0xFFFFFF, 0xFFFFFF, 0xFFAAFF),
    ("7-black_silver",  0x000000, 0x00FFFF, 0xFFFFFF, 0xFFFFFF, 0xFF5500),
]

def line(x1,y1,x2,y2,color,w):
    return ('<line x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f" stroke="%s" '
            'stroke-width="%.2f" stroke-linecap="round"/>') % (x1,y1,x2,y2,hx(color),w)

def svg_for(bg,num,date,hands,batt,second=True):
    el = []
    el.append('<rect x="0" y="0" width="%d" height="%d" fill="%s"/>' % (S,S,hx(bg)))

    # 12 Roman numerals around the dial (radius 0.40), centered
    r = S*0.40
    fs = S*0.085
    for i in range(12):
        ang = math.radians((i+1)*30)
        x = cx + r*math.sin(ang)
        y = cy - r*math.cos(ang)
        el.append('<text x="%.2f" y="%.2f" font-family="Helvetica,Arial,sans-serif" '
                  'font-size="%.2f" fill="%s" text-anchor="middle">%s</text>'
                  % (x, y + fs*0.35, fs, hx(num), NUMERALS[i]))

    # hands geometry (mirrors drawHands)
    offset = S/25.0
    minTheta = math.radians((15-MINUTE)*6)
    adj = HOUR + MINUTE/60.0
    hourTheta = math.radians((3-adj)*30)
    minLen = S*0.38; maxHourLen = S*0.23
    totalHour = maxHourLen + offset
    unch = totalHour*(1-BATT)

    minSx = cx - math.cos(minTheta)*offset; minSy = cy + math.sin(minTheta)*offset
    minEx = cx + math.cos(minTheta)*minLen;  minEy = cy - math.sin(minTheta)*minLen
    hSx = cx - math.cos(hourTheta)*offset;   hSy = cy + math.sin(hourTheta)*offset
    hMaxEx = cx + math.cos(hourTheta)*maxHourLen; hMaxEy = cy - math.sin(hourTheta)*maxHourLen
    hUnEx = hSx + math.cos(hourTheta)*unch;  hUnEy = hSy - math.sin(hourTheta)*unch

    # battery (discharged) part of hour hand, then charged part
    el.append(line(hSx,hSy,hUnEx,hUnEy, batt, 3*sf))
    el.append(line(hUnEx,hUnEy,hMaxEx,hMaxEy, hands, 3*sf))
    # minute hand
    el.append(line(minSx,minSy,minEx,minEy, hands, 2*sf))
    # second hand (capable-device default)
    if second:
        secTheta = math.radians((15-SEC)*6)
        secLen = S*0.42
        el.append(line(cx,cy, cx+math.cos(secTheta)*secLen, cy-math.sin(secTheta)*secLen, batt, 1*sf))

    # date
    dfs = S*0.105
    el.append('<text x="%.2f" y="%.2f" font-family="Helvetica,Arial,sans-serif" '
              'font-size="%.2f" fill="%s" text-anchor="middle">%s</text>'
              % (S*0.81, S*0.43 + dfs*0.35, dfs, hx(date), DATE))

    return ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" '
            'viewBox="0 0 %d %d">%s</svg>') % (S,S,S,S, "".join(el))

outdir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "screenshots")
os.makedirs(outdir, exist_ok=True)
for name,bg,num,date,hands,batt in THEMES:
    open(os.path.join(outdir, name+".svg"), "w").write(svg_for(bg,num,date,hands,batt))
print("wrote", len(THEMES), "SVGs to", outdir)
