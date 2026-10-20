"""Read-only native diagram geometry validation; no model file is rewritten."""
from pathlib import Path
import xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1];M=R/'models/university';checks=[]
for pattern in ['rel/*/subviews/*.xml','logical/subviews/*.xml']:
 for p in M.glob(pattern):
  root=ET.parse(p).getroot();boxes={};view_ids={}
  for v in root.findall('./objectViews/OView'):
   b=v.find('bounds');boxes[v.get('vid')]=tuple(int(b.get(k)) for k in ['x','y','width','height']);view_ids[v.get('vid')]=v.get('oid')
  assert len(boxes)==11
  for a,(x,y,w,h) in boxes.items():
   for b,(xx,yy,ww,hh) in boxes.items():
    if a<b:assert not(max(x,xx)<min(x+w,xx+ww) and max(y,yy)<min(y+h,yy+hh))
  checks.append('PASS: '+pattern+' eleven boxes do not overlap')
  connectors=root.findall('./connectors/Connector');assert len(connectors)==12
  if pattern.startswith('logical'):
   objects={ET.parse(q).getroot().get('id') for q in M.glob('logical/entity/*/*.xml')}
   links={x.get('id'):{x.findtext('sourceEntity'),x.findtext('targetEntity')} for x in [ET.parse(q).getroot() for q in M.glob('logical/relation/*/*.xml')]}
  else:
   objects={ET.parse(q).getroot().get('id') for q in M.glob('rel/*/table/*/*.xml')}
   links={x.get('id'):{x.get('containerWithKeyObject'),x.findtext('referredTableID')} for x in [ET.parse(q).getroot() for q in M.glob('rel/*/foreignkey/*/*.xml')]}
  assert set(view_ids.values())==objects
  assert {c.get('oid') for c in connectors}==set(links)
  for c in connectors:
   assert {view_ids[c.get('vid_source')],view_ids[c.get('vid_target')]}==links[c.get('oid')]
   pts=[(int(t.get('x')),int(t.get('y'))) for t in c.findall('./points/point')]
   for (px,py),key in [(pts[0],c.get('vid_source')),(pts[-1],c.get('vid_target'))]:
    x,y,w,h=boxes[key];assert (px in [x,x+w] and y<=py<=y+h) or (py in [y,y+h] and x<=px<=x+w)
   for (ax,ay),(bx,by) in zip(pts,pts[1:]):
    assert ax==bx or ay==by
    for x,y,w,h in boxes.values():
     if ax==bx:assert not(x<ax<x+w and max(min(ay,by),y)<min(max(ay,by),y+h))
     else:assert not(y<ay<y+h and max(min(ax,bx),x)<min(max(ax,bx),x+w))
  checks.append('PASS: '+pattern+' twelve connectors meet borders and avoid box interiors')
relations=[ET.parse(p).getroot() for p in M.glob('logical/relation/*/*.xml')]
assert len(relations)==12 and all(x.findtext('nameOnSource') and x.findtext('nameOnTarget') for x in relations)
checks+=['PASS: all twelve logical relations have directional names','NATIVE_LAYOUT_VALIDATION_PASSED']
(R/'results/native-layout-validation.txt').write_text('\n'.join(checks)+'\n',encoding='utf-8');print('\n'.join(checks))
