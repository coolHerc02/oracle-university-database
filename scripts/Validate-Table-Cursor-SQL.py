"""Audit correspondence of the eleven standalone queries and cursor procedures."""
from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
plain=(root/'sql/33_select_each_table.sql').read_text(encoding='utf-8')
code=(root/'sql/34_cursor_procedures_each_table.sql').read_text(encoding='utf-8')
queries=re.findall(r'^select .*?;',plain,re.S|re.M)
cursors=re.findall(r' cursor c_rows is\n (select .*?);',code,re.S)
names=re.findall(r'create or replace procedure (\w+)\(',code,re.I)
checks=[]
def ok(test,message):
    if not test:raise RuntimeError(message)
    checks.append('PASS: '+message)
def normalize(sql):return re.sub(r'\s+',' ',re.sub(r':(?=[pl]_)','',sql).strip().rstrip(';')).lower()
ok(len(queries)==len(cursors)==len(names)==11,'Eleven SELECTs correspond to eleven declared cursor procedures')
ok(len(set(names))==11,'Procedure names are unique')
for name,query,cursor in zip(names,queries,cursors):
    ok(normalize(query)==normalize(cursor),name+': identical projection joins predicates and order')
    projection=re.split(r'\bfrom\b',cursor,flags=re.I)[0]
    predicate=re.split(r'\bwhere\b',cursor,flags=re.I)[1].split('order by')[0]
    ok(not re.search(r'\b\w*_id\b',projection,re.I),name+': no surrogate ID output')
    ok(not re.search(r'\b\w*_id\b',predicate,re.I),name+': meaningful filters')
    ok('order by' in cursor.lower(),name+': explicit order')
    ok(not re.search(r'\bselect\s+\*',cursor,re.I),name+': explicit characteristics')
marker=f'TABLE_CURSOR_SOURCE_AUDIT_PASSED: {len(checks)} checks; 11 query-procedure pairs'
(root/'results/table-cursor-source-audit.txt').write_text('\n'.join(checks+[marker])+'\n',encoding='utf-8',newline='\n')
print(marker)
