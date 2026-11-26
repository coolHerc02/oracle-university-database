"""Audit the final seven user-facing SELECTs, not internal keys or administrative SQL."""
from pathlib import Path
import re

root=Path(__file__).resolve().parents[1]
checks=[]
def check(condition,label):
    if not condition:raise RuntimeError(label)
    checks.append('PASS: '+label)

for filename,expected in [('05_search.sql',2),('06_reports.sql',5)]:
    source=(root/'sql'/filename).read_text(encoding='utf-8')
    source=re.sub(r'--[^\n]*','',source)
    statements=re.findall(r'^\s*select\s+(.*?)\s+from\s+(.*?);',source,re.I|re.M|re.S)
    check(len(statements)==expected,filename+' exposes '+str(expected)+' final queries')
    for i,(projection,body) in enumerate(statements,1):
        label=f'{filename} report {i}'
        check(not re.search(r'\b\w*_id\b',projection,re.I),label+' hides surrogate IDs')
        predicate=re.search(r'\bwhere\b(.*?)(?:\border\s+by\b|$)',body,re.I|re.S)
        check(predicate is None or not re.search(r'\b\w*_id\b',predicate[1],re.I),label+' filters by meaningful values')
        check(bool(re.search(r'\border\s+by\b',body,re.I)),label+' has explicit ordering')
        check('email' in projection.lower(),label+' includes entity contact data')

source=(root/'sql/02_programs.sql').read_text(encoding='utf-8')
groups=re.findall(r'\bgroup\s+by\s+([^;)]+)',source.split('create or replace package')[0],re.I)
normalized=[re.sub(r'\s+','',g).lower() for g in groups]
check(normalized==['g.faculty_number','dt.curriculum_id,dt.academic_year','dt.teacher_id'],
      'Aggregate subqueries group by entity keys and the academic-year dimension')
checks.append('TEACHER_SELECT_SOURCE_AUDIT_PASSED: '+str(len(checks))+' checks; 7 final queries')
(root/'results/teacher-select-source-audit.txt').write_text('\n'.join(checks)+'\n',encoding='utf-8',newline='\n')
print(checks[-1])
