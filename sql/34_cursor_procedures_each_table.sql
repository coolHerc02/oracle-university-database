-- Eleven read-only cursor procedures; no grants to teacher logins.
set define off
set serveroutput on size unlimited
set linesize 420
whenever sqlerror exit sql.sqlcode rollback
begin
 if user<>'UNIVERSITY_PROJECT' then raise_application_error(-20000,'Use UNIVERSITY_PROJECT.');end if;
end;
/

-- SPECIALTIES: same projection, joins, filters and ordering as file 33.
create or replace procedure list_specialties(
 p_keyword varchar2 default null
) authid definer as
 l_keyword varchar2(4000);
 l_count pls_integer:=0;
 cursor c_rows is
 select s.specialty_name as specialty_name
 from specialties s
 where (l_keyword is null or upper(s.specialty_name) like l_keyword escape '\')
 order by s.specialty_name;
 function cell(p_value varchar2) return varchar2 is
 begin
  if p_value is null then return '<NULL>';end if;
  return replace(replace(replace(replace(p_value,'\','\\'),'|','\|'),chr(13),'\r'),chr(10),'\n');
 end;
begin
 if length(p_keyword)>1000 then raise_application_error(-20200,'p_keyword: maximum 1000 characters.');end if;
 if trim(p_keyword) is not null then
  if lengthb('%'||replace(replace(replace(upper(trim(p_keyword)),'\','\\'),'%','\%'),'_','\_')||'%')>4000 then raise_application_error(-20200,'Search pattern exceeds SQL byte limit.');end if;
  l_keyword:='%'||replace(replace(replace(upper(trim(p_keyword)),'\','\\'),'%','\%'),'_','\_')||'%';
 end if;
 dbms_output.put_line('LIST|SPECIALTIES');
 for r in c_rows loop
  dbms_output.put_line('ROW|'||'specialty_name='||cell(r.specialty_name));
  l_count:=l_count+1;
 end loop;
 dbms_output.put_line('ROWS|SPECIALTIES|'||to_char(l_count,'TM9'));
end;
/

-- ACADEMIC_TITLES: same projection, joins, filters and ordering as file 33.
create or replace procedure list_academic_titles(
 p_keyword varchar2 default null
) authid definer as
 l_keyword varchar2(4000);
 l_count pls_integer:=0;
 cursor c_rows is
 select a.title_name as title_name
 from academic_titles a
 where (l_keyword is null or upper(a.title_name) like l_keyword escape '\')
 order by a.title_name;
 function cell(p_value varchar2) return varchar2 is
 begin
  if p_value is null then return '<NULL>';end if;
  return replace(replace(replace(replace(p_value,'\','\\'),'|','\|'),chr(13),'\r'),chr(10),'\n');
 end;
begin
 if length(p_keyword)>1000 then raise_application_error(-20200,'p_keyword: maximum 1000 characters.');end if;
 if trim(p_keyword) is not null then
  if lengthb('%'||replace(replace(replace(upper(trim(p_keyword)),'\','\\'),'%','\%'),'_','\_')||'%')>4000 then raise_application_error(-20200,'Search pattern exceeds SQL byte limit.');end if;
  l_keyword:='%'||replace(replace(replace(upper(trim(p_keyword)),'\','\\'),'%','\%'),'_','\_')||'%';
 end if;
 dbms_output.put_line('LIST|ACADEMIC_TITLES');
 for r in c_rows loop
  dbms_output.put_line('ROW|'||'title_name='||cell(r.title_name));
  l_count:=l_count+1;
 end loop;
 dbms_output.put_line('ROWS|ACADEMIC_TITLES|'||to_char(l_count,'TM9'));
end;
/

-- STUDY_YEARS: same projection, joins, filters and ordering as file 33.
create or replace procedure list_study_years(
 p_keyword varchar2 default null
) authid definer as
 l_keyword varchar2(4000);
 l_count pls_integer:=0;
 cursor c_rows is
 select y.study_year_no as study_year_no,
        y.year_label as year_label
 from study_years y
 where (l_keyword is null or upper(y.year_label) like l_keyword escape '\')
 order by y.study_year_no;
 function cell(p_value varchar2) return varchar2 is
 begin
  if p_value is null then return '<NULL>';end if;
  return replace(replace(replace(replace(p_value,'\','\\'),'|','\|'),chr(13),'\r'),chr(10),'\n');
 end;
begin
 if length(p_keyword)>1000 then raise_application_error(-20200,'p_keyword: maximum 1000 characters.');end if;
 if trim(p_keyword) is not null then
  if lengthb('%'||replace(replace(replace(upper(trim(p_keyword)),'\','\\'),'%','\%'),'_','\_')||'%')>4000 then raise_application_error(-20200,'Search pattern exceeds SQL byte limit.');end if;
  l_keyword:='%'||replace(replace(replace(upper(trim(p_keyword)),'\','\\'),'%','\%'),'_','\_')||'%';
 end if;
 dbms_output.put_line('LIST|STUDY_YEARS');
 for r in c_rows loop
  dbms_output.put_line('ROW|'||'study_year_no='||cell(to_char(r.study_year_no,'TM9','NLS_NUMERIC_CHARACTERS=''.,'''))||' | '||
   'year_label='||cell(r.year_label));
  l_count:=l_count+1;
 end loop;
 dbms_output.put_line('ROWS|STUDY_YEARS|'||to_char(l_count,'TM9'));
end;
/

-- SEMESTERS: same projection, joins, filters and ordering as file 33.
create or replace procedure list_semesters(
 p_year_keyword varchar2 default null,
 p_term_no number default null
) authid definer as
 l_year_keyword varchar2(4000);
 l_count pls_integer:=0;
 cursor c_rows is
 select s.semester_no as semester_no,
        y.year_label as year_label,
        s.study_year_no as study_year_no,
        s.term_no as term_no
 from semesters s join study_years y on y.study_year_no=s.study_year_no
 where (l_year_keyword is null or upper(y.year_label) like l_year_keyword escape '\')
   and (p_term_no is null or s.term_no=p_term_no)
 order by s.semester_no;
 function cell(p_value varchar2) return varchar2 is
 begin
  if p_value is null then return '<NULL>';end if;
  return replace(replace(replace(replace(p_value,'\','\\'),'|','\|'),chr(13),'\r'),chr(10),'\n');
 end;
begin
 if length(p_year_keyword)>1000 then raise_application_error(-20200,'p_year_keyword: maximum 1000 characters.');end if;
 if p_term_no is not null and p_term_no not in(1,2) then raise_application_error(-20201,'Term must be 1 or 2.');end if;
 if trim(p_year_keyword) is not null then
  if lengthb('%'||replace(replace(replace(upper(trim(p_year_keyword)),'\','\\'),'%','\%'),'_','\_')||'%')>4000 then raise_application_error(-20200,'Search pattern exceeds SQL byte limit.');end if;
  l_year_keyword:='%'||replace(replace(replace(upper(trim(p_year_keyword)),'\','\\'),'%','\%'),'_','\_')||'%';
 end if;
 dbms_output.put_line('LIST|SEMESTERS');
 for r in c_rows loop
  dbms_output.put_line('ROW|'||'semester_no='||cell(to_char(r.semester_no,'TM9','NLS_NUMERIC_CHARACTERS=''.,'''))||' | '||
   'year_label='||cell(r.year_label)||' | '||
   'study_year_no='||cell(to_char(r.study_year_no,'TM9','NLS_NUMERIC_CHARACTERS=''.,'''))||' | '||
   'term_no='||cell(to_char(r.term_no,'TM9','NLS_NUMERIC_CHARACTERS=''.,''')));
  l_count:=l_count+1;
 end loop;
 dbms_output.put_line('ROWS|SEMESTERS|'||to_char(l_count,'TM9'));
end;
/

-- GRADE_SCALE: same projection, joins, filters and ordering as file 33.
create or replace procedure list_grade_scale(
 p_min_grade number default null,
 p_is_passing number default null
) authid definer as
 l_count pls_integer:=0;
 cursor c_rows is
 select g.grade_value as grade_value,
        g.grade_label as grade_label,
        g.is_passing as is_passing,
        case g.is_passing when 1 then 'PASS' else 'FAIL' end as passing_status
 from grade_scale g
 where (p_min_grade is null or g.grade_value>=p_min_grade)
   and (p_is_passing is null or g.is_passing=p_is_passing)
 order by g.grade_value;
 function cell(p_value varchar2) return varchar2 is
 begin
  if p_value is null then return '<NULL>';end if;
  return replace(replace(replace(replace(p_value,'\','\\'),'|','\|'),chr(13),'\r'),chr(10),'\n');
 end;
begin
 if p_min_grade is not null and (p_min_grade<2 or p_min_grade<>trunc(p_min_grade) or p_min_grade>6) then raise_application_error(-20201,'Invalid p_min_grade.');end if;
 if p_is_passing is not null and p_is_passing not in(0,1) then raise_application_error(-20201,'Passing flag must be 0 or 1.');end if;
 dbms_output.put_line('LIST|GRADE_SCALE');
 for r in c_rows loop
  dbms_output.put_line('ROW|'||'grade_value='||cell(to_char(r.grade_value,'TM9','NLS_NUMERIC_CHARACTERS=''.,'''))||' | '||
   'grade_label='||cell(r.grade_label)||' | '||
   'is_passing='||cell(to_char(r.is_passing,'TM9','NLS_NUMERIC_CHARACTERS=''.,'''))||' | '||
   'passing_status='||cell(r.passing_status));
  l_count:=l_count+1;
 end loop;
 dbms_output.put_line('ROWS|GRADE_SCALE|'||to_char(l_count,'TM9'));
end;
/

-- STUDENTS: same projection, joins, filters and ordering as file 33.
create or replace procedure list_students(
 p_keyword varchar2 default null,
 p_specialty_keyword varchar2 default null,
 p_year_keyword varchar2 default null
) authid definer as
 l_keyword varchar2(4000);
 l_specialty_keyword varchar2(4000);
 l_year_keyword varchar2(4000);
 l_count pls_integer:=0;
 cursor c_rows is
 select s.faculty_number as faculty_number,
        s.first_name as first_name,
        s.middle_name as middle_name,
        s.last_name as last_name,
        sp.specialty_name as specialty_name,
        y.year_label as year_label,
        s.study_year_no as study_year_no,
        s.email as email
 from students s join specialties sp on sp.specialty_id=s.specialty_id
 join study_years y on y.study_year_no=s.study_year_no
 where (l_keyword is null or upper(s.first_name||' '||case when s.middle_name is not null then s.middle_name||' ' end||s.last_name) like l_keyword escape '\')
   and (l_specialty_keyword is null or upper(sp.specialty_name) like l_specialty_keyword escape '\')
   and (l_year_keyword is null or upper(y.year_label) like l_year_keyword escape '\')
 order by s.last_name,s.first_name,s.middle_name,s.faculty_number;
 function cell(p_value varchar2) return varchar2 is
 begin
  if p_value is null then return '<NULL>';end if;
  return replace(replace(replace(replace(p_value,'\','\\'),'|','\|'),chr(13),'\r'),chr(10),'\n');
 end;
begin
 if length(p_keyword)>1000 then raise_application_error(-20200,'p_keyword: maximum 1000 characters.');end if;
 if length(p_specialty_keyword)>1000 then raise_application_error(-20200,'p_specialty_keyword: maximum 1000 characters.');end if;
 if length(p_year_keyword)>1000 then raise_application_error(-20200,'p_year_keyword: maximum 1000 characters.');end if;
 if trim(p_keyword) is not null then
  if lengthb('%'||replace(replace(replace(upper(trim(p_keyword)),'\','\\'),'%','\%'),'_','\_')||'%')>4000 then raise_application_error(-20200,'Search pattern exceeds SQL byte limit.');end if;
  l_keyword:='%'||replace(replace(replace(upper(trim(p_keyword)),'\','\\'),'%','\%'),'_','\_')||'%';
 end if;
 if trim(p_specialty_keyword) is not null then
  if lengthb('%'||replace(replace(replace(upper(trim(p_specialty_keyword)),'\','\\'),'%','\%'),'_','\_')||'%')>4000 then raise_application_error(-20200,'Search pattern exceeds SQL byte limit.');end if;
  l_specialty_keyword:='%'||replace(replace(replace(upper(trim(p_specialty_keyword)),'\','\\'),'%','\%'),'_','\_')||'%';
 end if;
 if trim(p_year_keyword) is not null then
  if lengthb('%'||replace(replace(replace(upper(trim(p_year_keyword)),'\','\\'),'%','\%'),'_','\_')||'%')>4000 then raise_application_error(-20200,'Search pattern exceeds SQL byte limit.');end if;
  l_year_keyword:='%'||replace(replace(replace(upper(trim(p_year_keyword)),'\','\\'),'%','\%'),'_','\_')||'%';
 end if;
 dbms_output.put_line('LIST|STUDENTS');
 for r in c_rows loop
  dbms_output.put_line('ROW|'||'faculty_number='||cell(r.faculty_number)||' | '||
   'first_name='||cell(r.first_name)||' | '||
   'middle_name='||cell(r.middle_name)||' | '||
   'last_name='||cell(r.last_name)||' | '||
   'specialty_name='||cell(r.specialty_name)||' | '||
   'year_label='||cell(r.year_label)||' | '||
   'study_year_no='||cell(to_char(r.study_year_no,'TM9','NLS_NUMERIC_CHARACTERS=''.,'''))||' | '||
   'email='||cell(r.email));
  l_count:=l_count+1;
 end loop;
 dbms_output.put_line('ROWS|STUDENTS|'||to_char(l_count,'TM9'));
end;
/

-- TEACHERS: same projection, joins, filters and ordering as file 33.
create or replace procedure list_teachers(
 p_keyword varchar2 default null,
 p_title_keyword varchar2 default null
) authid definer as
 l_keyword varchar2(4000);
 l_title_keyword varchar2(4000);
 l_count pls_integer:=0;
 cursor c_rows is
 select t.first_name as first_name,
        t.middle_name as middle_name,
        t.last_name as last_name,
        a.title_name as title_name,
        t.phone as phone,
        t.email as email
 from teachers t join academic_titles a on a.title_id=t.title_id
 where (l_keyword is null or upper(t.first_name||' '||case when t.middle_name is not null then t.middle_name||' ' end||t.last_name) like l_keyword escape '\')
   and (l_title_keyword is null or upper(a.title_name) like l_title_keyword escape '\')
 order by t.last_name,t.first_name,t.middle_name,t.email,t.teacher_id;
 function cell(p_value varchar2) return varchar2 is
 begin
  if p_value is null then return '<NULL>';end if;
  return replace(replace(replace(replace(p_value,'\','\\'),'|','\|'),chr(13),'\r'),chr(10),'\n');
 end;
begin
 if length(p_keyword)>1000 then raise_application_error(-20200,'p_keyword: maximum 1000 characters.');end if;
 if length(p_title_keyword)>1000 then raise_application_error(-20200,'p_title_keyword: maximum 1000 characters.');end if;
 if trim(p_keyword) is not null then
  if lengthb('%'||replace(replace(replace(upper(trim(p_keyword)),'\','\\'),'%','\%'),'_','\_')||'%')>4000 then raise_application_error(-20200,'Search pattern exceeds SQL byte limit.');end if;
  l_keyword:='%'||replace(replace(replace(upper(trim(p_keyword)),'\','\\'),'%','\%'),'_','\_')||'%';
 end if;
 if trim(p_title_keyword) is not null then
  if lengthb('%'||replace(replace(replace(upper(trim(p_title_keyword)),'\','\\'),'%','\%'),'_','\_')||'%')>4000 then raise_application_error(-20200,'Search pattern exceeds SQL byte limit.');end if;
  l_title_keyword:='%'||replace(replace(replace(upper(trim(p_title_keyword)),'\','\\'),'%','\%'),'_','\_')||'%';
 end if;
 dbms_output.put_line('LIST|TEACHERS');
 for r in c_rows loop
  dbms_output.put_line('ROW|'||'first_name='||cell(r.first_name)||' | '||
   'middle_name='||cell(r.middle_name)||' | '||
   'last_name='||cell(r.last_name)||' | '||
   'title_name='||cell(r.title_name)||' | '||
   'phone='||cell(r.phone)||' | '||
   'email='||cell(r.email));
  l_count:=l_count+1;
 end loop;
 dbms_output.put_line('ROWS|TEACHERS|'||to_char(l_count,'TM9'));
end;
/

-- DISCIPLINES: same projection, joins, filters and ordering as file 33.
create or replace procedure list_disciplines(
 p_keyword varchar2 default null
) authid definer as
 l_keyword varchar2(4000);
 l_count pls_integer:=0;
 cursor c_rows is
 select d.discipline_name as discipline_name
 from disciplines d
 where (l_keyword is null or upper(d.discipline_name) like l_keyword escape '\')
 order by d.discipline_name,d.discipline_id;
 function cell(p_value varchar2) return varchar2 is
 begin
  if p_value is null then return '<NULL>';end if;
  return replace(replace(replace(replace(p_value,'\','\\'),'|','\|'),chr(13),'\r'),chr(10),'\n');
 end;
begin
 if length(p_keyword)>1000 then raise_application_error(-20200,'p_keyword: maximum 1000 characters.');end if;
 if trim(p_keyword) is not null then
  if lengthb('%'||replace(replace(replace(upper(trim(p_keyword)),'\','\\'),'%','\%'),'_','\_')||'%')>4000 then raise_application_error(-20200,'Search pattern exceeds SQL byte limit.');end if;
  l_keyword:='%'||replace(replace(replace(upper(trim(p_keyword)),'\','\\'),'%','\%'),'_','\_')||'%';
 end if;
 dbms_output.put_line('LIST|DISCIPLINES');
 for r in c_rows loop
  dbms_output.put_line('ROW|'||'discipline_name='||cell(r.discipline_name));
  l_count:=l_count+1;
 end loop;
 dbms_output.put_line('ROWS|DISCIPLINES|'||to_char(l_count,'TM9'));
end;
/

-- CURRICULUM: same projection, joins, filters and ordering as file 33.
create or replace procedure list_curriculum(
 p_discipline_keyword varchar2 default null,
 p_specialty_keyword varchar2 default null,
 p_semester_no number default null
) authid definer as
 l_discipline_keyword varchar2(4000);
 l_specialty_keyword varchar2(4000);
 l_count pls_integer:=0;
 cursor c_rows is
 select sp.specialty_name as specialty_name,
        d.discipline_name as discipline_name,
        c.semester_no as semester_no,
        y.year_label as year_label,
        se.term_no as term_no
 from curriculum c join specialties sp on sp.specialty_id=c.specialty_id
 join disciplines d on d.discipline_id=c.discipline_id
 join semesters se on se.semester_no=c.semester_no join study_years y on y.study_year_no=se.study_year_no
 where (l_discipline_keyword is null or upper(d.discipline_name) like l_discipline_keyword escape '\')
   and (l_specialty_keyword is null or upper(sp.specialty_name) like l_specialty_keyword escape '\')
   and (p_semester_no is null or c.semester_no=p_semester_no)
 order by sp.specialty_name,c.semester_no,d.discipline_name,c.curriculum_id;
 function cell(p_value varchar2) return varchar2 is
 begin
  if p_value is null then return '<NULL>';end if;
  return replace(replace(replace(replace(p_value,'\','\\'),'|','\|'),chr(13),'\r'),chr(10),'\n');
 end;
begin
 if length(p_discipline_keyword)>1000 then raise_application_error(-20200,'p_discipline_keyword: maximum 1000 characters.');end if;
 if length(p_specialty_keyword)>1000 then raise_application_error(-20200,'p_specialty_keyword: maximum 1000 characters.');end if;
 if p_semester_no is not null and (p_semester_no<1 or p_semester_no<>trunc(p_semester_no)) then raise_application_error(-20201,'Invalid p_semester_no.');end if;
 if trim(p_discipline_keyword) is not null then
  if lengthb('%'||replace(replace(replace(upper(trim(p_discipline_keyword)),'\','\\'),'%','\%'),'_','\_')||'%')>4000 then raise_application_error(-20200,'Search pattern exceeds SQL byte limit.');end if;
  l_discipline_keyword:='%'||replace(replace(replace(upper(trim(p_discipline_keyword)),'\','\\'),'%','\%'),'_','\_')||'%';
 end if;
 if trim(p_specialty_keyword) is not null then
  if lengthb('%'||replace(replace(replace(upper(trim(p_specialty_keyword)),'\','\\'),'%','\%'),'_','\_')||'%')>4000 then raise_application_error(-20200,'Search pattern exceeds SQL byte limit.');end if;
  l_specialty_keyword:='%'||replace(replace(replace(upper(trim(p_specialty_keyword)),'\','\\'),'%','\%'),'_','\_')||'%';
 end if;
 dbms_output.put_line('LIST|CURRICULUM');
 for r in c_rows loop
  dbms_output.put_line('ROW|'||'specialty_name='||cell(r.specialty_name)||' | '||
   'discipline_name='||cell(r.discipline_name)||' | '||
   'semester_no='||cell(to_char(r.semester_no,'TM9','NLS_NUMERIC_CHARACTERS=''.,'''))||' | '||
   'year_label='||cell(r.year_label)||' | '||
   'term_no='||cell(to_char(r.term_no,'TM9','NLS_NUMERIC_CHARACTERS=''.,''')));
  l_count:=l_count+1;
 end loop;
 dbms_output.put_line('ROWS|CURRICULUM|'||to_char(l_count,'TM9'));
end;
/

-- DISCIPLINE_TEACHERS: same projection, joins, filters and ordering as file 33.
create or replace procedure list_teaching_assignments(
 p_discipline_keyword varchar2 default null,
 p_teacher_keyword varchar2 default null,
 p_specialty_keyword varchar2 default null,
 p_academic_year number default null
) authid definer as
 l_discipline_keyword varchar2(4000);
 l_teacher_keyword varchar2(4000);
 l_specialty_keyword varchar2(4000);
 l_count pls_integer:=0;
 cursor c_rows is
 select d.discipline_name as discipline_name,
        sp.specialty_name as specialty_name,
        c.semester_no as semester_no,
        t.first_name||' '||case when t.middle_name is not null then t.middle_name||' ' end||t.last_name as teacher_name,
        a.title_name as title_name,
        t.phone as phone,
        t.email as email,
        dt.academic_year as academic_year,
        to_char(dt.academic_year,'FM0000')||'/'||to_char(dt.academic_year+1,'FM0000') as academic_year_label
 from discipline_teachers dt join curriculum c on c.curriculum_id=dt.curriculum_id
 join disciplines d on d.discipline_id=c.discipline_id join specialties sp on sp.specialty_id=c.specialty_id
 join teachers t on t.teacher_id=dt.teacher_id join academic_titles a on a.title_id=t.title_id
 where (l_discipline_keyword is null or upper(d.discipline_name) like l_discipline_keyword escape '\')
   and (l_teacher_keyword is null or upper(t.first_name||' '||case when t.middle_name is not null then t.middle_name||' ' end||t.last_name) like l_teacher_keyword escape '\')
   and (l_specialty_keyword is null or upper(sp.specialty_name) like l_specialty_keyword escape '\')
   and (p_academic_year is null or dt.academic_year=p_academic_year)
 order by dt.academic_year,sp.specialty_name,c.semester_no,d.discipline_name,t.last_name,t.first_name,dt.curriculum_id,dt.teacher_id;
 function cell(p_value varchar2) return varchar2 is
 begin
  if p_value is null then return '<NULL>';end if;
  return replace(replace(replace(replace(p_value,'\','\\'),'|','\|'),chr(13),'\r'),chr(10),'\n');
 end;
begin
 if length(p_discipline_keyword)>1000 then raise_application_error(-20200,'p_discipline_keyword: maximum 1000 characters.');end if;
 if length(p_teacher_keyword)>1000 then raise_application_error(-20200,'p_teacher_keyword: maximum 1000 characters.');end if;
 if length(p_specialty_keyword)>1000 then raise_application_error(-20200,'p_specialty_keyword: maximum 1000 characters.');end if;
 if p_academic_year is not null and (p_academic_year<1900 or p_academic_year<>trunc(p_academic_year) or p_academic_year>9998) then raise_application_error(-20201,'Invalid p_academic_year.');end if;
 if trim(p_discipline_keyword) is not null then
  if lengthb('%'||replace(replace(replace(upper(trim(p_discipline_keyword)),'\','\\'),'%','\%'),'_','\_')||'%')>4000 then raise_application_error(-20200,'Search pattern exceeds SQL byte limit.');end if;
  l_discipline_keyword:='%'||replace(replace(replace(upper(trim(p_discipline_keyword)),'\','\\'),'%','\%'),'_','\_')||'%';
 end if;
 if trim(p_teacher_keyword) is not null then
  if lengthb('%'||replace(replace(replace(upper(trim(p_teacher_keyword)),'\','\\'),'%','\%'),'_','\_')||'%')>4000 then raise_application_error(-20200,'Search pattern exceeds SQL byte limit.');end if;
  l_teacher_keyword:='%'||replace(replace(replace(upper(trim(p_teacher_keyword)),'\','\\'),'%','\%'),'_','\_')||'%';
 end if;
 if trim(p_specialty_keyword) is not null then
  if lengthb('%'||replace(replace(replace(upper(trim(p_specialty_keyword)),'\','\\'),'%','\%'),'_','\_')||'%')>4000 then raise_application_error(-20200,'Search pattern exceeds SQL byte limit.');end if;
  l_specialty_keyword:='%'||replace(replace(replace(upper(trim(p_specialty_keyword)),'\','\\'),'%','\%'),'_','\_')||'%';
 end if;
 dbms_output.put_line('LIST|DISCIPLINE_TEACHERS');
 for r in c_rows loop
  dbms_output.put_line('ROW|'||'discipline_name='||cell(r.discipline_name)||' | '||
   'specialty_name='||cell(r.specialty_name)||' | '||
   'semester_no='||cell(to_char(r.semester_no,'TM9','NLS_NUMERIC_CHARACTERS=''.,'''))||' | '||
   'teacher_name='||cell(r.teacher_name)||' | '||
   'title_name='||cell(r.title_name)||' | '||
   'phone='||cell(r.phone)||' | '||
   'email='||cell(r.email)||' | '||
   'academic_year='||cell(to_char(r.academic_year,'TM9','NLS_NUMERIC_CHARACTERS=''.,'''))||' | '||
   'academic_year_label='||cell(r.academic_year_label));
  l_count:=l_count+1;
 end loop;
 dbms_output.put_line('ROWS|DISCIPLINE_TEACHERS|'||to_char(l_count,'TM9'));
end;
/

-- GRADES: same projection, joins, filters and ordering as file 33.
create or replace procedure list_grades(
 p_faculty_number varchar2 default null,
 p_discipline_keyword varchar2 default null,
 p_specialty_keyword varchar2 default null,
 p_academic_year number default null,
 p_min_grade number default null
) authid definer as
 l_discipline_keyword varchar2(4000);
 l_specialty_keyword varchar2(4000);
 l_count pls_integer:=0;
 cursor c_rows is
 select g.faculty_number as faculty_number,
        s.first_name||' '||case when s.middle_name is not null then s.middle_name||' ' end||s.last_name as student_name,
        s.email as student_email,
        sp.specialty_name as specialty_name,
        y.year_label as year_label,
        d.discipline_name as discipline_name,
        c.semester_no as semester_no,
        g.grade_value as grade_value,
        gs.grade_label as grade_label,
        gs.is_passing as is_passing,
        g.grade_date as grade_date,
        t.first_name||' '||case when t.middle_name is not null then t.middle_name||' ' end||t.last_name as teacher_name,
        a.title_name as title_name,
        t.phone as teacher_phone,
        t.email as teacher_email,
        g.academic_year as academic_year,
        to_char(g.academic_year,'FM0000')||'/'||to_char(g.academic_year+1,'FM0000') as academic_year_label
 from grades g join students s on s.faculty_number=g.faculty_number
 join curriculum c on c.curriculum_id=g.curriculum_id join disciplines d on d.discipline_id=c.discipline_id
 join specialties sp on sp.specialty_id=c.specialty_id join study_years y on y.study_year_no=s.study_year_no
 join grade_scale gs on gs.grade_value=g.grade_value
 join teachers t on t.teacher_id=g.teacher_id join academic_titles a on a.title_id=t.title_id
 where (trim(p_faculty_number) is null or g.faculty_number=trim(p_faculty_number))
   and (l_discipline_keyword is null or upper(d.discipline_name) like l_discipline_keyword escape '\')
   and (l_specialty_keyword is null or upper(sp.specialty_name) like l_specialty_keyword escape '\')
   and (p_academic_year is null or g.academic_year=p_academic_year)
   and (p_min_grade is null or g.grade_value>=p_min_grade)
 order by s.last_name,s.first_name,g.faculty_number,c.semester_no,d.discipline_name,g.academic_year,g.curriculum_id;
 function cell(p_value varchar2) return varchar2 is
 begin
  if p_value is null then return '<NULL>';end if;
  return replace(replace(replace(replace(p_value,'\','\\'),'|','\|'),chr(13),'\r'),chr(10),'\n');
 end;
begin
 if length(p_faculty_number)>1000 then raise_application_error(-20200,'p_faculty_number: maximum 1000 characters.');end if;
 if length(p_discipline_keyword)>1000 then raise_application_error(-20200,'p_discipline_keyword: maximum 1000 characters.');end if;
 if length(p_specialty_keyword)>1000 then raise_application_error(-20200,'p_specialty_keyword: maximum 1000 characters.');end if;
 if p_academic_year is not null and (p_academic_year<1900 or p_academic_year<>trunc(p_academic_year) or p_academic_year>9998) then raise_application_error(-20201,'Invalid p_academic_year.');end if;
 if p_min_grade is not null and (p_min_grade<2 or p_min_grade<>trunc(p_min_grade) or p_min_grade>6) then raise_application_error(-20201,'Invalid p_min_grade.');end if;
 if trim(p_discipline_keyword) is not null then
  if lengthb('%'||replace(replace(replace(upper(trim(p_discipline_keyword)),'\','\\'),'%','\%'),'_','\_')||'%')>4000 then raise_application_error(-20200,'Search pattern exceeds SQL byte limit.');end if;
  l_discipline_keyword:='%'||replace(replace(replace(upper(trim(p_discipline_keyword)),'\','\\'),'%','\%'),'_','\_')||'%';
 end if;
 if trim(p_specialty_keyword) is not null then
  if lengthb('%'||replace(replace(replace(upper(trim(p_specialty_keyword)),'\','\\'),'%','\%'),'_','\_')||'%')>4000 then raise_application_error(-20200,'Search pattern exceeds SQL byte limit.');end if;
  l_specialty_keyword:='%'||replace(replace(replace(upper(trim(p_specialty_keyword)),'\','\\'),'%','\%'),'_','\_')||'%';
 end if;
 dbms_output.put_line('LIST|GRADES');
 for r in c_rows loop
  dbms_output.put_line('ROW|'||'faculty_number='||cell(r.faculty_number)||' | '||
   'student_name='||cell(r.student_name)||' | '||
   'student_email='||cell(r.student_email)||' | '||
   'specialty_name='||cell(r.specialty_name)||' | '||
   'year_label='||cell(r.year_label)||' | '||
   'discipline_name='||cell(r.discipline_name)||' | '||
   'semester_no='||cell(to_char(r.semester_no,'TM9','NLS_NUMERIC_CHARACTERS=''.,'''))||' | '||
   'grade_value='||cell(to_char(r.grade_value,'TM9','NLS_NUMERIC_CHARACTERS=''.,'''))||' | '||
   'grade_label='||cell(r.grade_label)||' | '||
   'is_passing='||cell(to_char(r.is_passing,'TM9','NLS_NUMERIC_CHARACTERS=''.,'''))||' | '||
   'grade_date='||cell(to_char(r.grade_date,'YYYY-MM-DD HH24:MI:SS'))||' | '||
   'teacher_name='||cell(r.teacher_name)||' | '||
   'title_name='||cell(r.title_name)||' | '||
   'teacher_phone='||cell(r.teacher_phone)||' | '||
   'teacher_email='||cell(r.teacher_email)||' | '||
   'academic_year='||cell(to_char(r.academic_year,'TM9','NLS_NUMERIC_CHARACTERS=''.,'''))||' | '||
   'academic_year_label='||cell(r.academic_year_label));
  l_count:=l_count+1;
 end loop;
 dbms_output.put_line('ROWS|GRADES|'||to_char(l_count,'TM9'));
end;
/

declare n number;
begin
 select count(*) into n from user_objects where object_type='PROCEDURE' and status='VALID' and object_name in('LIST_SPECIALTIES','LIST_ACADEMIC_TITLES','LIST_STUDY_YEARS','LIST_SEMESTERS','LIST_GRADE_SCALE','LIST_STUDENTS','LIST_TEACHERS','LIST_DISCIPLINES','LIST_CURRICULUM','LIST_TEACHING_ASSIGNMENTS','LIST_GRADES');
 if n<>11 then raise_application_error(-20209,'Not all eleven list procedures compiled.');end if;
 dbms_output.put_line('TABLE_CURSOR_PROCEDURES_COMPILED: 11 procedures');
end;
/
