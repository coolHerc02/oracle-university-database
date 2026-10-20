"""Compare every Oracle storage proxy with the already validated relational model."""
from pathlib import Path
import xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1];M=R/'models/university';lines=[];failed=[]
physical={p.stem:ET.parse(p).getroot() for p in M.glob('rel/*/phys/*/Table/seg_0/*.xml')}
for p in sorted(M.glob('rel/*/table/seg_0/*.xml')):
 t=ET.parse(p).getroot();s=physical[t.get('id')];name=t.get('name').upper()
 def pairs(nodes):return {(n.get('id'),n.get('name')) for n in nodes}
 def check(ok,label):
  lines.append(('PASS: ' if ok else 'FAIL: ')+name+' '+label)
  if not ok:failed.append(name+' '+label)
 check(pairs(t.findall('./columns/Column'))==pairs(s.findall('./columnProxies/ColumnProxy')),'column proxy identities')
 for state,path in [('Primary Constraint','primaryKeys/PrimaryKey'),('Unique Constraint','uniqueKeys/UniqueKey'),('Foreign Key','foreignKeys/ForeignKey')]:
  expected=pairs(i for i in t.findall('./indexes/ind_PK_UK') if i.findtext('indexState')==state)
  check(expected==pairs(s.findall('./'+path)),state+' proxies')
 expected=pairs(i for i in t.findall('./indexes/ind_PK_UK') if i.findtext('indexState') not in {'Primary Constraint','Unique Constraint','Foreign Key'})
 check(expected==pairs(s.findall('./indexProxies/IndexProxy')),'secondary index proxies')
 check(pairs(t.findall('./tableCheckConstraints/tableCheckConstraint'))==pairs(s.findall('./tableCheckConstraints/TableCheckConstraint')),'CHECK constraint proxies')
lines+=['PHYSICAL_MODEL_VALIDATION_'+('FAILED' if failed else 'PASSED')+': '+str(sum(x.startswith('PASS:') for x in lines))+' checks']
(R/'results/physical-model-validation.txt').write_text('\n'.join(lines)+'\n',encoding='utf-8',newline='\n')
print('\n'.join(x for x in lines if x.startswith('FAIL') or x.startswith('PHYSICAL_')))
if failed:raise SystemExit(1)
