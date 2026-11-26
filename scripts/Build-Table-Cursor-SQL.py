"""One query definition per base table generates standalone SQL and cursor procedures."""
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[1]
CATALOG=[]
def add(table,name,params,columns,source,filters,order,examples=()):
    CATALOG.append(dict(table=table,name=name,params=params,columns=columns,source=source,
                        filters=filters,order=order,examples=examples))
def text(name):return (name,'varchar2')
def number(name):return (name,'number')
def like(field,param):return f"(l_{param[2:]} is null or upper({field}) like l_{param[2:]} escape '\\')"
def eq(field,param):return f'({param} is null or {field}={param})'
person=lambda alias: f"{alias}.first_name||' '||case when {alias}.middle_name is not null then {alias}.middle_name||' ' end||{alias}.last_name"
add('SPECIALTIES','list_specialties',[text('p_keyword')],
 [('s.specialty_name','specialty_name','text')], 'specialties s',[like('s.specialty_name','p_keyword')],'s.specialty_name', ["'комп'"])
add('ACADEMIC_TITLES','list_academic_titles',[text('p_keyword')],
 [('a.title_name','title_name','text')], 'academic_titles a',[like('a.title_name','p_keyword')],'a.title_name',["'проф'"])
add('STUDY_YEARS','list_study_years',[text('p_keyword')],
 [('y.study_year_no','study_year_no','number'),('y.year_label','year_label','text')],
 'study_years y',[like('y.year_label','p_keyword')],'y.study_year_no')
add('SEMESTERS','list_semesters',[text('p_year_keyword'),number('p_term_no')],
 [('s.semester_no','semester_no','number'),('y.year_label','year_label','text'),('s.study_year_no','study_year_no','number'),('s.term_no','term_no','number')],
 'semesters s join study_years y on y.study_year_no=s.study_year_no',
 [like('y.year_label','p_year_keyword'),eq('s.term_no','p_term_no')],'s.semester_no',["p_term_no=>1"])
add('GRADE_SCALE','list_grade_scale',[number('p_min_grade'),number('p_is_passing')],
 [('g.grade_value','grade_value','number'),('g.grade_label','grade_label','text'),('g.is_passing','is_passing','number'),("case g.is_passing when 1 then 'PASS' else 'FAIL' end",'passing_status','text')],
 'grade_scale g',["(p_min_grade is null or g.grade_value>=p_min_grade)",eq('g.is_passing','p_is_passing')],
 'g.grade_value',["p_is_passing=>0"])
add('STUDENTS','list_students',[text('p_keyword'),text('p_specialty_keyword'),text('p_year_keyword')],
 [('s.faculty_number','faculty_number','text'),('s.first_name','first_name','text'),('s.middle_name','middle_name','text'),('s.last_name','last_name','text'),('sp.specialty_name','specialty_name','text'),('y.year_label','year_label','text'),('s.study_year_no','study_year_no','number'),('s.email','email','text')],
 'students s join specialties sp on sp.specialty_id=s.specialty_id\njoin study_years y on y.study_year_no=s.study_year_no',
 [like(person('s'),'p_keyword'),like('sp.specialty_name','p_specialty_keyword'),like('y.year_label','p_year_keyword')],
 's.last_name,s.first_name,s.middle_name,s.faculty_number',["p_specialty_keyword=>'комп'"])
add('TEACHERS','list_teachers',[text('p_keyword'),text('p_title_keyword')],
 [('t.first_name','first_name','text'),('t.middle_name','middle_name','text'),('t.last_name','last_name','text'),('a.title_name','title_name','text'),('t.phone','phone','text'),('t.email','email','text')],
 'teachers t join academic_titles a on a.title_id=t.title_id',
 [like(person('t'),'p_keyword'),like('a.title_name','p_title_keyword')],
 't.last_name,t.first_name,t.middle_name,t.email,t.teacher_id',["p_title_keyword=>'професор'"])
add('DISCIPLINES','list_disciplines',[text('p_keyword')],
 [('d.discipline_name','discipline_name','text')],'disciplines d',
 [like('d.discipline_name','p_keyword')],'d.discipline_name,d.discipline_id',["'бази'"])
add('CURRICULUM','list_curriculum',[text('p_discipline_keyword'),text('p_specialty_keyword'),number('p_semester_no')],
 [('sp.specialty_name','specialty_name','text'),('d.discipline_name','discipline_name','text'),('c.semester_no','semester_no','number'),('y.year_label','year_label','text'),('se.term_no','term_no','number')],
 'curriculum c join specialties sp on sp.specialty_id=c.specialty_id\njoin disciplines d on d.discipline_id=c.discipline_id\njoin semesters se on se.semester_no=c.semester_no join study_years y on y.study_year_no=se.study_year_no',
 [like('d.discipline_name','p_discipline_keyword'),like('sp.specialty_name','p_specialty_keyword'),eq('c.semester_no','p_semester_no')],
 'sp.specialty_name,c.semester_no,d.discipline_name,c.curriculum_id',["p_discipline_keyword=>'СА'"])
add('DISCIPLINE_TEACHERS','list_teaching_assignments',[text('p_discipline_keyword'),text('p_teacher_keyword'),text('p_specialty_keyword'),number('p_academic_year')],
 [('d.discipline_name','discipline_name','text'),('sp.specialty_name','specialty_name','text'),('c.semester_no','semester_no','number'),(person('t'),'teacher_name','text'),('a.title_name','title_name','text'),('t.phone','phone','text'),('t.email','email','text'),('dt.academic_year','academic_year','number'),("to_char(dt.academic_year,'FM0000')||'/'||to_char(dt.academic_year+1,'FM0000')",'academic_year_label','text')],
 'discipline_teachers dt join curriculum c on c.curriculum_id=dt.curriculum_id\njoin disciplines d on d.discipline_id=c.discipline_id join specialties sp on sp.specialty_id=c.specialty_id\njoin teachers t on t.teacher_id=dt.teacher_id join academic_titles a on a.title_id=t.title_id',
 [like('d.discipline_name','p_discipline_keyword'),like(person('t'),'p_teacher_keyword'),like('sp.specialty_name','p_specialty_keyword'),eq('dt.academic_year','p_academic_year')],
 'dt.academic_year,sp.specialty_name,c.semester_no,d.discipline_name,t.last_name,t.first_name,dt.curriculum_id,dt.teacher_id',
 ["p_academic_year=>2026"])
add('GRADES','list_grades',[text('p_faculty_number'),text('p_discipline_keyword'),text('p_specialty_keyword'),number('p_academic_year'),number('p_min_grade')],
 [('g.faculty_number','faculty_number','text'),(person('s'),'student_name','text'),('s.email','student_email','text'),('sp.specialty_name','specialty_name','text'),('y.year_label','year_label','text'),('d.discipline_name','discipline_name','text'),('c.semester_no','semester_no','number'),('g.grade_value','grade_value','number'),('gs.grade_label','grade_label','text'),('gs.is_passing','is_passing','number'),('g.grade_date','grade_date','date'),(person('t'),'teacher_name','text'),('a.title_name','title_name','text'),('t.phone','teacher_phone','text'),('t.email','teacher_email','text'),('g.academic_year','academic_year','number'),("to_char(g.academic_year,'FM0000')||'/'||to_char(g.academic_year+1,'FM0000')",'academic_year_label','text')],
 'grades g join students s on s.faculty_number=g.faculty_number\njoin curriculum c on c.curriculum_id=g.curriculum_id join disciplines d on d.discipline_id=c.discipline_id\njoin specialties sp on sp.specialty_id=c.specialty_id join study_years y on y.study_year_no=s.study_year_no\njoin grade_scale gs on gs.grade_value=g.grade_value\njoin teachers t on t.teacher_id=g.teacher_id join academic_titles a on a.title_id=t.title_id',
 ["(trim(p_faculty_number) is null or g.faculty_number=trim(p_faculty_number))",like('d.discipline_name','p_discipline_keyword'),like('sp.specialty_name','p_specialty_keyword'),eq('g.academic_year','p_academic_year'),"(p_min_grade is null or g.grade_value>=p_min_grade)"],
 's.last_name,s.first_name,g.faculty_number,c.semester_no,d.discipline_name,g.academic_year,g.curriculum_id',
 ["p_faculty_number=>'00010001',p_academic_year=>2025"])

PATTERN="'%'||replace(replace(replace(upper(trim(VALUE)),'\\','\\\\'),'%','\\%'),'_','\\_')||'%'"
def query(spec,bind=False):
    q='select '+',\n       '.join(f'{expr} as {alias}' for expr,alias,_ in spec['columns'])
    q+='\nfrom '+spec['source']+'\nwhere '+'\n  and '.join(spec['filters'])+'\norder by '+spec['order']
    if bind:
        for name,_ in spec['params']:
            q=re.sub(r'\b'+name+r'\b',':'+name,q)
            q=re.sub(r'\bl_'+name[2:]+r'\b',':l_'+name[2:],q)
    return q

def parameter_checks(spec):
    checks=[]
    for name,kind in spec['params']:
        if kind=='varchar2':
            checks.append(f" if length({name})>1000 then raise_application_error(-20200,'{name}: maximum 1000 characters.');end if;")
        elif name=='p_term_no':checks.append(f" if {name} is not null and {name} not in(1,2) then raise_application_error(-20201,'Term must be 1 or 2.');end if;")
        elif name=='p_is_passing':checks.append(f" if {name} is not null and {name} not in(0,1) then raise_application_error(-20201,'Passing flag must be 0 or 1.');end if;")
        else:
            low,high=(1900,9998) if name=='p_academic_year' else (2,6) if name=='p_min_grade' else (1,None)
            invalid=f'{name}<{low} or {name}<>trunc({name})'+(f' or {name}>{high}' if high else '')
            checks.append(f" if {name} is not null and ({invalid}) then raise_application_error(-20201,'Invalid {name}.');end if;")
    return '\n'.join(checks)

PREAMBLE='set define off\nset serveroutput on size unlimited\nset linesize 420\nwhenever sqlerror exit sql.sqlcode rollback\n'
GUARD="begin\n if user<>'UNIVERSITY_PROJECT' then raise_application_error(-20000,'Use UNIVERSITY_PROJECT.');end if;\nend;\n/\n"
plain=['-- Eleven base-table lists. F5 as UNIVERSITY_PROJECT. Read-only.\n'+PREAMBLE+GUARD+
       "set pagesize 100\nset null '<NULL>'\nalter session set nls_date_format='YYYY-MM-DD HH24:MI:SS';\n-- Each section resets its optional inputs to NULL (all records).\n-- Edit a parameter assignment in the selected section to apply a filter.\n"]
widths={'faculty_number':12,'specialty_name':28,'title_name':20,'year_label':10,'discipline_name':30,
        'first_name':14,'middle_name':14,'last_name':14,'email':32,'student_name':32,'teacher_name':32,
        'student_email':32,'phone':18,'teacher_phone':18,'teacher_email':32,'academic_year_label':12,
        'grade_label':14,'passing_status':7,'grade_date':19}
for alias,width in widths.items():plain.append(f'column {alias} format a{width} word_wrapped\n')
for alias in ['study_year_no','semester_no','term_no','grade_value','is_passing','academic_year']:
    plain.append(f'column {alias} format 9999\n')
procedures=['-- Eleven read-only cursor procedures; no grants to teacher logins.\n'+PREAMBLE+GUARD]
demo=['-- All eleven lists, followed by filtered examples. F5 as UNIVERSITY_PROJECT.\n'+PREAMBLE+GUARD]
for spec in CATALOG:
    table,name=spec['table'],spec['name']
    plain.append(f'\nprompt TABLE_{table}\n-- Corresponding procedure: {name}.\n')
    for param,kind in spec['params']:
        plain.append(f'variable {param} '+('varchar2(4000)' if kind=='varchar2' else 'number')+f'\nexec :{param}:=null;\n')
    for param,kind in spec['params']:
        if kind=='varchar2' and param!='p_faculty_number':
            pat=PATTERN.replace('VALUE',':'+param)
            plain.append(f'variable l_{param[2:]} varchar2(4000)\nbegin\n :l_{param[2:]}:=case when trim(:{param}) is null then null else {pat} end;\nend;\n/\n')
    plain.append(query(spec,True)+';\n')
    sig=',\n '.join(p+' '+kind+' default null' for p,kind in spec['params'])
    code=f'\n-- {table}: same projection, joins, filters and ordering as file 33.\ncreate or replace procedure {name}(\n {sig}\n) authid definer as\n'
    for p,kind in spec['params']:
        if kind=='varchar2' and p!='p_faculty_number':code+=f' l_{p[2:]} varchar2(4000);\n'
    code+=' l_count pls_integer:=0;\n cursor c_rows is\n '+query(spec).replace('\n','\n ')+';\n'
    code+=" function cell(p_value varchar2) return varchar2 is\n begin\n  if p_value is null then return '<NULL>';end if;\n  return replace(replace(replace(replace(p_value,'\\','\\\\'),'|','\\|'),chr(13),'\\r'),chr(10),'\\n');\n end;\nbegin\n"
    code+=parameter_checks(spec)+'\n'
    for p,kind in spec['params']:
        if kind=='varchar2' and p!='p_faculty_number':
            code+=f" if trim({p}) is not null then\n  if lengthb({PATTERN.replace('VALUE',p)})>4000 then raise_application_error(-20200,'Search pattern exceeds SQL byte limit.');end if;\n  l_{p[2:]}:={PATTERN.replace('VALUE',p)};\n end if;\n"
    expressions=[]
    for _,alias,kind in spec['columns']:
        expr=f'r.{alias}'
        if kind=='number':expr=f"to_char({expr},'TM9','NLS_NUMERIC_CHARACTERS=''.,''')"
        elif kind=='date':expr=f"to_char({expr},'YYYY-MM-DD HH24:MI:SS')"
        expressions.append(f"'{alias}='||cell({expr})")
    code+=f" dbms_output.put_line('LIST|{table}');\n for r in c_rows loop\n  dbms_output.put_line('ROW|'||"+"||' | '||\n   ".join(expressions)+");\n  l_count:=l_count+1;\n end loop;\n"
    code+=f" dbms_output.put_line('ROWS|{table}|'||to_char(l_count,'TM9'));\nend;\n/\n"
    procedures.append(code)
    demo.append(f'\nprompt ALL_{table}\nexec {name};\n')
for spec in CATALOG:
    for args in spec['examples']:demo.append(f"\nprompt FILTERED_{spec['table']}\nexec {spec['name']}({args});\n")
procedures.append("\ndeclare n number;\nbegin\n select count(*) into n from user_objects where object_type='PROCEDURE' and status='VALID' and object_name in("+
                  ','.join("'"+s['name'].upper()+"'" for s in CATALOG)+");\n if n<>11 then raise_application_error(-20209,'Not all eleven list procedures compiled.');end if;\n dbms_output.put_line('TABLE_CURSOR_PROCEDURES_COMPILED: 11 procedures');\nend;\n/\n")
plain.append('\nprompt TABLE_SELECTS_COMPLETED: 11 lists\n')
demo.append('\nprompt TABLE_CURSOR_DEMO_COMPLETED\n')
for filename,parts in [('33_select_each_table.sql',plain),('34_cursor_procedures_each_table.sql',procedures),('35_cursor_procedures_demo.sql',demo)]:
    (ROOT/'sql'/filename).write_text(''.join(parts),encoding='utf-8',newline='\n')

# Oracle checks independently verify base-row cardinality, filters and preservation.
# A separate source audit proves canonical SELECT/cursor query equivalence.
validation=[PREAMBLE+GUARD+'''declare
 checks pls_integer:=0;
 lines dbms_output.chararr;nlines integer;output_text clob;row_count number;n number;
 log_text clob;new_id number;
 type t_snapshots is table of clob index by pls_integer;before_rows t_snapshots;
 procedure ok(b boolean,message varchar2) is
 begin
  if b is null or not b then raise_application_error(-20290,message);end if;
  checks:=checks+1;log_text:=log_text||'PASS: '||message||chr(10);
 end;
 procedure capture(p_call varchar2) is
 begin
  nlines:=10000;dbms_output.get_lines(lines,nlines);
  execute immediate 'begin '||p_call||';end;';
  nlines:=10000;dbms_output.get_lines(lines,nlines);output_text:=null;row_count:=0;
  for i in 1..nlines loop
   if substr(lines(i),1,4)='ROW|' then row_count:=row_count+1;end if;
   output_text:=output_text||lines(i)||chr(10);
  end loop;
 end;
 procedure rejects(p_call varchar2,wanted number,message varchar2) is actual number:=0;
 begin
  begin execute immediate 'begin '||p_call||';end;';exception when others then actual:=sqlcode;end;
  ok(actual=wanted,message);
 end;
begin
 savepoint table_cursor_validation;
''']
keys={'SPECIALTIES':'specialty_id','ACADEMIC_TITLES':'title_id','STUDY_YEARS':'study_year_no',
      'SEMESTERS':'semester_no','GRADE_SCALE':'grade_value','STUDENTS':'faculty_number','TEACHERS':'teacher_id',
      'DISCIPLINES':'discipline_id','CURRICULUM':'curriculum_id','DISCIPLINE_TEACHERS':'curriculum_id,teacher_id,academic_year',
      'GRADES':'faculty_number,curriculum_id'}
for i,s in enumerate(CATALOG,1):
    validation.append(f" before_rows({i}):=dbms_xmlgen.getxml('select * from {s['table']} order by {keys[s['table']]}');\n")
for s in CATALOG:
    validation.append(f" select count(*) into n from {s['table']};\n capture('{s['name']}');\n ok(row_count=n,'{s['table']}: one result per base row');\n ok(instr(output_text,'ROWS|{s['table']}|'||to_char(n,'TM9'))>0,'{s['table']}: correct empty/nonempty summary');\n")
    text_params=[p for p,k in s['params'] if k=='varchar2' and p!='p_faculty_number']
    for p in text_params:
        validation.append(f" capture('{s['name']}({p}=>''   '')');ok(row_count=n,'{s['name']}: blank {p} lists all rows');\n")
        validation.append(f" rejects('{s['name']}({p}=>rpad(''x'',1001,''x''))',-20200,'{s['name']}: oversized {p} rejected');\n")
validation.append('''
 insert into specialties(specialty_name) values('LIST 100%_\\') returning specialty_id into new_id;
 capture('list_specialties(''100%'')');ok(row_count=1,'Literal percent does not become a wildcard');
 capture('list_specialties(''_'')');ok(row_count=1,'Literal underscore does not become a wildcard');
 capture('list_specialties(''\\'')');ok(row_count=1,'Literal backslash is escaped');
 capture('list_specialties(''list 100'')');ok(row_count=1,'Case-insensitive keyword search');
 capture('list_specialties(''LIST-MISSING-983144'')');ok(row_count=0 and instr(output_text,'ROWS|SPECIALTIES|0')>0,'Empty search reports zero rows');
 capture('list_specialties(chr(39)||'' or 1=1 --'')');ok(row_count=0,'Apostrophe input remains literal data');
 capture('list_students(p_specialty_keyword=>unistr(''\\041a\\043e\\043c\\043f''))');
 select count(*) into n from students s join specialties sp on sp.specialty_id=s.specialty_id where sp.specialty_name like unistr('%\\041a\\043e\\043c\\043f%');
 ok(row_count=n and n>0,'Student specialty filter uses the related name');
 capture('list_teachers(p_title_keyword=>unistr(''\\043f\\0440\\043e\\0444''))');
 select count(*) into n from teachers t join academic_titles a on a.title_id=t.title_id where a.title_name like unistr('%\\043f\\0440\\043e\\0444%');
 ok(row_count=n and n>0,'Teacher title filter uses the related name');
 capture('list_semesters(p_term_no=>1)');select count(*) into n from semesters where term_no=1;ok(row_count=n,'Semester term filter');
 capture('list_grade_scale(p_is_passing=>0)');ok(row_count=1 and instr(output_text,'grade_value=2')>0,'Failed grade-scale filter');
 capture('list_curriculum(p_semester_no=>6)');select count(*) into n from curriculum where semester_no=6;ok(row_count=n,'Curriculum semester filter');
 capture('list_teaching_assignments(p_academic_year=>2026)');select count(*) into n from discipline_teachers where academic_year=2026;ok(row_count=n,'Assignment year filter');
 capture('list_grades(p_faculty_number=>''00010001'',p_academic_year=>2025)');
 select count(*) into n from grades where faculty_number='00010001' and academic_year=2025;
 ok(row_count=n and n>0,'Grade faculty number and historical year filter');
 ok(instr(output_text,'teacher_email=teacher1@university.example')>0 and instr(output_text,'academic_year_label=2025/2026')>0,'Grade output identifies historical grader and year');
 capture('list_grades(p_faculty_number=>''00010001'',p_academic_year=>2026)');ok(row_count=0,'Different academic year does not leak historical grades');
 capture('list_grades(p_min_grade=>6)');select count(*) into n from grades where grade_value=6;ok(row_count=n,'Grade minimum filter');
 rejects('list_semesters(p_term_no=>3)',-20201,'Invalid term rejected');
 rejects('list_grade_scale(p_is_passing=>2)',-20201,'Invalid passing flag rejected');
 rejects('list_grades(p_academic_year=>2026.5)',-20201,'Fractional academic year rejected');
 rejects('list_grades(p_academic_year=>1899)',-20201,'Out-of-range academic year rejected');
 rejects('list_grades(p_min_grade=>7)',-20201,'Invalid minimum grade rejected');
 rejects('list_curriculum(p_semester_no=>1.5)',-20201,'Fractional semester rejected');
 rollback to table_cursor_validation;
''')
for i,s in enumerate(CATALOG,1):
    validation.append(f" ok(dbms_lob.compare(before_rows({i}),dbms_xmlgen.getxml('select * from {s['table']} order by {keys[s['table']]}'))=0,'{s['table']}: all rows and fields preserved');\n")
validation.append('''
 select count(*) into n from specialties where specialty_id=new_id;ok(n=0,'Temporary literal-keyword fixture rolled back');
 select count(*) into n from user_objects where status<>'VALID';ok(n=0,'All database objects remain VALID');
 for i in 0..trunc((dbms_lob.getlength(log_text)-1)/8000) loop dbms_output.put_line(dbms_lob.substr(log_text,8000,1+i*8000));end loop;
 dbms_output.put_line('TABLE_CURSOR_VALIDATION_PASSED: '||checks||' checks');
exception when others then rollback to table_cursor_validation;raise;
end;
/
''')
(ROOT/'sql/36_cursor_procedures_validation.sql').write_text(''.join(validation),encoding='utf-8',newline='\n')
print('TABLE_CURSOR_SQL_GENERATED: 11 queries; 11 procedures; demo and validation')

if __name__=='__main__':pass
