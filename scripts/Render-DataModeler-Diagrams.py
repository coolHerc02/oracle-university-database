"""Render static diagrams from the actual saved native Data Modeler objects."""
from pathlib import Path
import xml.etree.ElementTree as ET
from xml.sax.saxutils import escape
import math
from PIL import Image, ImageDraw, ImageFont
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

ROOT = Path(__file__).resolve().parents[1]
MODEL = ROOT / "models/university"
OUT = ROOT / "docs/diagrams"
OUT.mkdir(exist_ok=True)
W, H, SCALE = 1550, 1120, 2
REG = Path("C:/Windows/Fonts/segoeui.ttf")
BOLD = Path("C:/Windows/Fonts/segoeuib.ttf")
MONO = Path("C:/Windows/Fonts/consola.ttf")
pdfmetrics.registerFont(TTFont("DiagramRegular", str(REG)))
pdfmetrics.registerFont(TTFont("DiagramBold", str(BOLD)))
pdfmetrics.registerFont(TTFont("DiagramMono", str(MONO)))
layout = {}

domains = {}
for path in MODEL.glob("domains/*.xml"):
    for d in ET.parse(path).getroot().findall("./domains/Domain"):
        domains[d.get("id")] = d
tables = {}
table_ids = {}
column_ids = {}
for path in MODEL.glob("rel/*/table/*/*.xml"):
    t = ET.parse(path).getroot()
    name = t.get("name").upper()
    tables[name] = t
    table_ids[t.get("id")] = name
    for c in t.findall("./columns/Column"):
        column_ids[c.get("id")] = c.get("name").upper()

foreign = {}
for path in MODEL.glob("rel/*/foreignkey/*/*.xml"):
    f = ET.parse(path).getroot()
    foreign[f.get("name").upper()] = (table_ids[f.findtext("referredTableID")], table_ids[f.get("containerWithKeyObject")])
assert len(tables) == 11 and len(foreign) == 12
logical_names = {table_ids[e.findtext("generatorID")]: e.get("name")
                 for e in [ET.parse(p).getroot() for p in MODEL.glob("logical/entity/*/*.xml")]}
view = ET.parse(next(MODEL.glob("rel/*/subviews/*.xml"))).getroot()
view_names = {}
for v in view.findall("./objectViews/OView"):
    name = table_ids[v.get("oid")]
    b = v.find("bounds")
    layout[name] = tuple(int(b.get(k)) for k in ("x", "y", "width"))
    required_height = 46 + 24 * len(tables[name].findall("./columns/Column")) + 14
    if int(b.get("height")) < required_height:
        raise RuntimeError("Render the prepared submission copy; native box height is too small: " + name)
    view_names[v.get("vid")] = name
native_paths = {}
for c in view.findall("./connectors/Connector"):
    ends = (view_names[c.get("vid_source")], view_names[c.get("vid_target")])
    fk = next(n for n, pair in foreign.items() if pair == ends or pair[::-1] == ends)
    points = [(int(p.get("x")), int(p.get("y"))) for p in c.findall("./points/point")]
    native_paths[fk] = points if foreign[fk] == ends else list(reversed(points))


class Renderer:
    def __init__(self, name):
        self.name = name
        self.img = Image.new("RGB", (W*SCALE, H*SCALE), "white")
        self.draw = ImageDraw.Draw(self.img)
        self.svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
                    '<rect width="100%" height="100%" fill="white"/>']
        self.pdf = canvas.Canvas(str(OUT / (name+".pdf")), pagesize=(W,H))
        self.pdf.setTitle("University database: " + name)
        self.pdf.setAuthor("University project")
    def rect(self, x, y, w, h, fill="#ffffff", stroke="#cbd5e1", width=1):
        self.draw.rectangle([round(x*SCALE), round(y*SCALE), round((x+w)*SCALE), round((y+h)*SCALE)],
                            fill=fill, outline=stroke, width=round(width*SCALE))
        self.svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>')
        self.pdf.setFillColor(fill); self.pdf.setStrokeColor(stroke); self.pdf.setLineWidth(width)
        self.pdf.rect(x,H-y-h,w,h,fill=1,stroke=1)
    def line(self, points, color="#475569", width=1.5):
        self.draw.line([(round(x*SCALE), round(y*SCALE)) for x,y in points],fill=color,width=round(width*SCALE),joint="curve")
        self.svg.append(f'<polyline points="{" ".join(str(x)+","+str(y) for x,y in points)}" fill="none" stroke="{color}" stroke-width="{width}"/>')
        self.pdf.setStrokeColor(color);self.pdf.setLineWidth(width)
        path=self.pdf.beginPath();path.moveTo(points[0][0],H-points[0][1])
        for x,y in points[1:]: path.lineTo(x,H-y)
        self.pdf.drawPath(path)
    def text(self, x, y, text, size=14, bold=False, mono=False, color="#0f172a", center=False):
        font_path = MONO if mono else BOLD if bold else REG
        font = ImageFont.truetype(str(font_path),round(size*SCALE))
        width = self.draw.textlength(text,font=font)/SCALE
        if center: x -= width/2
        self.draw.text((round(x*SCALE),round(y*SCALE)),text,font=font,fill=color,anchor="lt")
        family = "Consolas" if mono else "Segoe UI"
        self.svg.append(f'<text x="{x}" y="{y+size}" font-family="{family},sans-serif" font-size="{size}" font-weight="{"bold" if bold else "normal"}" fill="{color}">{escape(text)}</text>')
        self.pdf.setFillColor(color)
        self.pdf.setFont("DiagramMono" if mono else "DiagramBold" if bold else "DiagramRegular",size)
        self.pdf.drawString(x,H-y-size,text)
    def save(self):
        self.svg.append("</svg>")
        (OUT/(self.name+".svg")).write_text("\n".join(self.svg),encoding="utf-8")
        self.img.save(OUT/(self.name+".png"))
        self.pdf.showPage();self.pdf.save()

def endpoint_label(r, end, toward, label, distance=30):
    dx,dy=toward[0]-end[0],toward[1]-end[1]
    length=math.hypot(dx,dy);dx/=length;dy/=length
    x=end[0]+dx*distance; y=end[1]+dy*distance
    if abs(dx)>abs(dy): y-=21
    else: x+=24;y-=8
    r.rect(x-19,y-2,38,21,fill="white",stroke="white")
    r.text(x,y,label,size=12,center=True,color="#334155")

def many(r, end, toward):
    dx,dy=toward[0]-end[0],toward[1]-end[1]
    length=math.hypot(dx,dy);dx/=length;dy/=length
    bx,by=end[0]+dx*14,end[1]+dy*14
    for offset in (-7,0,7):
        r.line([(bx,by),(end[0]-dy*offset,end[1]+dx*offset)],width=1.4)

def one(r, start, toward):
    dx,dy=toward[0]-start[0],toward[1]-start[1]
    length=math.hypot(dx,dy);dx/=length;dy/=length
    for distance in (10,16):
        x,y=start[0]+dx*distance,start[1]+dy*distance
        r.line([(x-dy*6,y+dx*6),(x+dy*6,y-dx*6)],width=1.4)

for logical in (False,True):
    name="logical" if logical else "relational"
    if logical:
        lv=ET.parse(next(MODEL.glob('logical/subviews/*.xml'))).getroot()
        entity_tables={e.get('id'):table_ids[e.findtext('generatorID')] for e in
                       [ET.parse(p).getroot() for p in MODEL.glob('logical/entity/*/*.xml')]}
        relations={e.get('id'):e.get('name').upper() for e in
                   [ET.parse(p).getroot() for p in MODEL.glob('logical/relation/*/*.xml')]}
        names={v.get('vid'):entity_tables[v.get('oid')] for v in lv.findall('./objectViews/OView')}
        assert set(names.values())==set(tables),'Logical diagram omits an entity'
        assert {relations[c.get('oid')] for c in lv.findall('./connectors/Connector')}==set(foreign),'Logical diagram omits a relation'
        layout={entity_tables[v.get('oid')]:tuple(int(v.find('bounds').get(k)) for k in ['x','y','width']) for v in lv.findall('./objectViews/OView')}
        native_paths={}
        for c in lv.findall('./connectors/Connector'):
            fk=relations[c.get('oid')];ends=(names[c.get('vid_source')],names[c.get('vid_target')])
            pts=[(int(p.get('x')),int(p.get('y'))) for p in c.findall('./points/point')]
            assert set(ends)==set(foreign[fk]),'Logical connector has wrong endpoints'
            native_paths[fk]=pts if foreign[fk]==ends else list(reversed(pts))
    r=Renderer(name)
    r.text(40,20,"Логически модел" if logical else "Релационен модел · Oracle 11g XE",26,bold=True)
    r.text(40,57,"Визуализация на обектите и подредбата в native university.dmd: 11 обекта, 39 полета, 12 връзки.",14,color="#475569")
    boxes={}
    for n,t in tables.items():
        x,y,w=layout[n]
        cols=t.findall("./columns/Column");h=46+24*len(cols)+14
        boxes[n]=(x,y,w,h)

    paths=native_paths
    targets={"SEMESTERS_YEAR_FK":"0..2","DT_TEACHER_FK":"2..N","DT_CURRICULUM_FK":"1..N","GRADES_STUDENT_FK":"2..N"}
    for fk,points in paths.items():
        assert fk in foreign
        color="#0f766e" if fk in ("DT_TEACHER_FK","GRADES_STUDENT_FK","DT_CURRICULUM_FK") else "#64748b"
        r.line(points,color,2 if color=="#0f766e" else 1.5)
        one(r,points[0],points[1]);many(r,points[-1],points[-2])
        endpoint_label(r,points[0],points[1],"1")
        endpoint_label(r,points[-1],points[-2],targets.get(fk,"0..N"))

    for n,t in tables.items():
        x,y,w,h=boxes[n]
        r.rect(x+4,y+4,w,h,fill="#e2e8f0",stroke="#e2e8f0")
        r.rect(x,y,w,h,fill="#f8fafc",stroke="#94a3b8")
        r.rect(x,y,w,40,fill="#e0f2fe" if n in ("STUDENTS","TEACHERS","DISCIPLINES","GRADES") else "#e2e8f0",stroke="#94a3b8")
        r.text(x+14,y+10,logical_names[n] if logical else n,18,bold=True)
        pk=set();fk_cols=set();unique_cols=set()
        for i in t.findall("./indexes/ind_PK_UK"):
            refs={column_ids[c.get("columnID")] for c in i.findall("./indexColumnUsage/colUsage")}
            if i.findtext("indexState")=="Primary Constraint":pk |= refs
            if i.findtext("indexState")=="Foreign Key":fk_cols |= refs
            if i.findtext("indexState")=="Unique Constraint":unique_cols |= refs
        for j,c in enumerate(t.findall("./columns/Column")):
            cn=c.get("name").upper()
            flags="P/F" if cn in pk and cn in fk_cols else "PK" if cn in pk else "FK" if cn in fk_cols else "NN" if c.findtext("nullsAllowed","false")!="true" else "  "
            if logical:
                flags = "#" if cn in pk else "U*" if cn in unique_cols else "*" if c.findtext("nullsAllowed", "false") != "true" else "o"
            domain=domains[c.findtext("domain")]
            dt=domain.findtext("logicalDatatype")
            size=domain.findtext("dataTypeSize","")
            if logical:
                typ={"LOGDT019":"Число","LOGDT024":"Текст","LOGDT007":"Дата"}[dt]
                if size:typ+="("+size.split()[0]+")"
                text=flags.ljust(4)+c.get("name").replace("_"," ")+" : "+typ
            else:
                typ={"LOGDT019":"NUMBER","LOGDT024":"VARCHAR2","LOGDT007":"DATE"}[dt]
                if size:typ+="("+size.upper()+")"
                text=flags.ljust(4)+c.get("name")+" : "+typ
            size=14 if logical else 13
            font_path=REG if logical else MONO
            while ImageFont.truetype(str(font_path),round(size*SCALE)).getlength(text)/SCALE>w-26:
                size-=0.25
            r.text(x+13,y+50+j*24,text,size,mono=not logical)
    r.text(40,1028,"# - основен UID     U* - допълнителен UID     * - задължителен атрибут     o - незадължителен атрибут" if logical else
           "PK - първичен ключ     FK - външен ключ     P/F - част от PK и FK     NN - задължително поле",15,color="#334155")
    r.text(40,1055,"Преподавател: поне 2 различни дисциплини. Учебен план: 1..N преподаватели. Студент: 2..N оценки.",16,bold=True,color="#0f766e")
    r.text(40,1080,"CURRICULUM определя специалност и семестър. GRADES сочи конкретно преподавателско назначение.",14,color="#475569")
    r.save()
print("DIAGRAMS_RENDERED_FROM_NATIVE_MODEL: logical and relational, SVG/PNG/PDF")
