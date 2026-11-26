-- Eleven base-table lists. F5 as UNIVERSITY_PROJECT. Read-only.
set define off
set serveroutput on size unlimited
set linesize 420
whenever sqlerror exit sql.sqlcode rollback
begin
 if user<>'UNIVERSITY_PROJECT' then raise_application_error(-20000,'Use UNIVERSITY_PROJECT.');end if;
end;
/
set pagesize 100
set null '<NULL>'
alter session set nls_date_format='YYYY-MM-DD HH24:MI:SS';
-- Each section resets its optional inputs to NULL (all records).
-- Edit a parameter assignment in the selected section to apply a filter.
column faculty_number format a12 word_wrapped
column specialty_name format a28 word_wrapped
column title_name format a20 word_wrapped
column year_label format a10 word_wrapped
column discipline_name format a30 word_wrapped
column first_name format a14 word_wrapped
column middle_name format a14 word_wrapped
column last_name format a14 word_wrapped
column email format a32 word_wrapped
column student_name format a32 word_wrapped
column teacher_name format a32 word_wrapped
column student_email format a32 word_wrapped
column phone format a18 word_wrapped
column teacher_phone format a18 word_wrapped
column teacher_email format a32 word_wrapped
column academic_year_label format a12 word_wrapped
column grade_label format a14 word_wrapped
column passing_status format a7 word_wrapped
column grade_date format a19 word_wrapped
column study_year_no format 9999
column semester_no format 9999
column term_no format 9999
column grade_value format 9999
column is_passing format 9999
column academic_year format 9999

prompt TABLE_SPECIALTIES
-- Corresponding procedure: list_specialties.
variable p_keyword varchar2(4000)
exec :p_keyword:=null;
variable l_keyword varchar2(4000)
begin
 :l_keyword:=case when trim(:p_keyword) is null then null else '%'||replace(replace(replace(upper(trim(:p_keyword)),'\','\\'),'%','\%'),'_','\_')||'%' end;
end;
/
select s.specialty_name as specialty_name
from specialties s
where (:l_keyword is null or upper(s.specialty_name) like :l_keyword escape '\')
order by s.specialty_name;

prompt TABLE_ACADEMIC_TITLES
-- Corresponding procedure: list_academic_titles.
variable p_keyword varchar2(4000)
exec :p_keyword:=null;
variable l_keyword varchar2(4000)
begin
 :l_keyword:=case when trim(:p_keyword) is null then null else '%'||replace(replace(replace(upper(trim(:p_keyword)),'\','\\'),'%','\%'),'_','\_')||'%' end;
end;
/
select a.title_name as title_name
from academic_titles a
where (:l_keyword is null or upper(a.title_name) like :l_keyword escape '\')
order by a.title_name;

prompt TABLE_STUDY_YEARS
-- Corresponding procedure: list_study_years.
variable p_keyword varchar2(4000)
exec :p_keyword:=null;
variable l_keyword varchar2(4000)
begin
 :l_keyword:=case when trim(:p_keyword) is null then null else '%'||replace(replace(replace(upper(trim(:p_keyword)),'\','\\'),'%','\%'),'_','\_')||'%' end;
end;
/
select y.study_year_no as study_year_no,
       y.year_label as year_label
from study_years y
where (:l_keyword is null or upper(y.year_label) like :l_keyword escape '\')
order by y.study_year_no;

prompt TABLE_SEMESTERS
-- Corresponding procedure: list_semesters.
variable p_year_keyword varchar2(4000)
exec :p_year_keyword:=null;
variable p_term_no number
exec :p_term_no:=null;
variable l_year_keyword varchar2(4000)
begin
 :l_year_keyword:=case when trim(:p_year_keyword) is null then null else '%'||replace(replace(replace(upper(trim(:p_year_keyword)),'\','\\'),'%','\%'),'_','\_')||'%' end;
end;
/
select s.semester_no as semester_no,
       y.year_label as year_label,
       s.study_year_no as study_year_no,
       s.term_no as term_no
from semesters s join study_years y on y.study_year_no=s.study_year_no
where (:l_year_keyword is null or upper(y.year_label) like :l_year_keyword escape '\')
  and (:p_term_no is null or s.term_no=:p_term_no)
order by s.semester_no;

prompt TABLE_GRADE_SCALE
-- Corresponding procedure: list_grade_scale.
variable p_min_grade number
exec :p_min_grade:=null;
variable p_is_passing number
exec :p_is_passing:=null;
select g.grade_value as grade_value,
       g.grade_label as grade_label,
       g.is_passing as is_passing,
       case g.is_passing when 1 then 'PASS' else 'FAIL' end as passing_status
from grade_scale g
where (:p_min_grade is null or g.grade_value>=:p_min_grade)
  and (:p_is_passing is null or g.is_passing=:p_is_passing)
order by g.grade_value;

prompt TABLE_STUDENTS
-- Corresponding procedure: list_students.
variable p_keyword varchar2(4000)
exec :p_keyword:=null;
variable p_specialty_keyword varchar2(4000)
exec :p_specialty_keyword:=null;
variable p_year_keyword varchar2(4000)
exec :p_year_keyword:=null;
variable l_keyword varchar2(4000)
begin
 :l_keyword:=case when trim(:p_keyword) is null then null else '%'||replace(replace(replace(upper(trim(:p_keyword)),'\','\\'),'%','\%'),'_','\_')||'%' end;
end;
/
variable l_specialty_keyword varchar2(4000)
begin
 :l_specialty_keyword:=case when trim(:p_specialty_keyword) is null then null else '%'||replace(replace(replace(upper(trim(:p_specialty_keyword)),'\','\\'),'%','\%'),'_','\_')||'%' end;
end;
/
variable l_year_keyword varchar2(4000)
begin
 :l_year_keyword:=case when trim(:p_year_keyword) is null then null else '%'||replace(replace(replace(upper(trim(:p_year_keyword)),'\','\\'),'%','\%'),'_','\_')||'%' end;
end;
/
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
where (:l_keyword is null or upper(s.first_name||' '||case when s.middle_name is not null then s.middle_name||' ' end||s.last_name) like :l_keyword escape '\')
  and (:l_specialty_keyword is null or upper(sp.specialty_name) like :l_specialty_keyword escape '\')
  and (:l_year_keyword is null or upper(y.year_label) like :l_year_keyword escape '\')
order by s.last_name,s.first_name,s.middle_name,s.faculty_number;

prompt TABLE_TEACHERS
-- Corresponding procedure: list_teachers.
variable p_keyword varchar2(4000)
exec :p_keyword:=null;
variable p_title_keyword varchar2(4000)
exec :p_title_keyword:=null;
variable l_keyword varchar2(4000)
begin
 :l_keyword:=case when trim(:p_keyword) is null then null else '%'||replace(replace(replace(upper(trim(:p_keyword)),'\','\\'),'%','\%'),'_','\_')||'%' end;
end;
/
variable l_title_keyword varchar2(4000)
begin
 :l_title_keyword:=case when trim(:p_title_keyword) is null then null else '%'||replace(replace(replace(upper(trim(:p_title_keyword)),'\','\\'),'%','\%'),'_','\_')||'%' end;
end;
/
select t.first_name as first_name,
       t.middle_name as middle_name,
       t.last_name as last_name,
       a.title_name as title_name,
       t.phone as phone,
       t.email as email
from teachers t join academic_titles a on a.title_id=t.title_id
where (:l_keyword is null or upper(t.first_name||' '||case when t.middle_name is not null then t.middle_name||' ' end||t.last_name) like :l_keyword escape '\')
  and (:l_title_keyword is null or upper(a.title_name) like :l_title_keyword escape '\')
order by t.last_name,t.first_name,t.middle_name,t.email,t.teacher_id;

prompt TABLE_DISCIPLINES
-- Corresponding procedure: list_disciplines.
variable p_keyword varchar2(4000)
exec :p_keyword:=null;
variable l_keyword varchar2(4000)
begin
 :l_keyword:=case when trim(:p_keyword) is null then null else '%'||replace(replace(replace(upper(trim(:p_keyword)),'\','\\'),'%','\%'),'_','\_')||'%' end;
end;
/
select d.discipline_name as discipline_name
from disciplines d
where (:l_keyword is null or upper(d.discipline_name) like :l_keyword escape '\')
order by d.discipline_name,d.discipline_id;

prompt TABLE_CURRICULUM
-- Corresponding procedure: list_curriculum.
variable p_discipline_keyword varchar2(4000)
exec :p_discipline_keyword:=null;
variable p_specialty_keyword varchar2(4000)
exec :p_specialty_keyword:=null;
variable p_semester_no number
exec :p_semester_no:=null;
variable l_discipline_keyword varchar2(4000)
begin
 :l_discipline_keyword:=case when trim(:p_discipline_keyword) is null then null else '%'||replace(replace(replace(upper(trim(:p_discipline_keyword)),'\','\\'),'%','\%'),'_','\_')||'%' end;
end;
/
variable l_specialty_keyword varchar2(4000)
begin
 :l_specialty_keyword:=case when trim(:p_specialty_keyword) is null then null else '%'||replace(replace(replace(upper(trim(:p_specialty_keyword)),'\','\\'),'%','\%'),'_','\_')||'%' end;
end;
/
select sp.specialty_name as specialty_name,
       d.discipline_name as discipline_name,
       c.semester_no as semester_no,
       y.year_label as year_label,
       se.term_no as term_no
from curriculum c join specialties sp on sp.specialty_id=c.specialty_id
join disciplines d on d.discipline_id=c.discipline_id
join semesters se on se.semester_no=c.semester_no join study_years y on y.study_year_no=se.study_year_no
where (:l_discipline_keyword is null or upper(d.discipline_name) like :l_discipline_keyword escape '\')
  and (:l_specialty_keyword is null or upper(sp.specialty_name) like :l_specialty_keyword escape '\')
  and (:p_semester_no is null or c.semester_no=:p_semester_no)
order by sp.specialty_name,c.semester_no,d.discipline_name,c.curriculum_id;

prompt TABLE_DISCIPLINE_TEACHERS
-- Corresponding procedure: list_teaching_assignments.
variable p_discipline_keyword varchar2(4000)
exec :p_discipline_keyword:=null;
variable p_teacher_keyword varchar2(4000)
exec :p_teacher_keyword:=null;
variable p_specialty_keyword varchar2(4000)
exec :p_specialty_keyword:=null;
variable p_academic_year number
exec :p_academic_year:=null;
variable l_discipline_keyword varchar2(4000)
begin
 :l_discipline_keyword:=case when trim(:p_discipline_keyword) is null then null else '%'||replace(replace(replace(upper(trim(:p_discipline_keyword)),'\','\\'),'%','\%'),'_','\_')||'%' end;
end;
/
variable l_teacher_keyword varchar2(4000)
begin
 :l_teacher_keyword:=case when trim(:p_teacher_keyword) is null then null else '%'||replace(replace(replace(upper(trim(:p_teacher_keyword)),'\','\\'),'%','\%'),'_','\_')||'%' end;
end;
/
variable l_specialty_keyword varchar2(4000)
begin
 :l_specialty_keyword:=case when trim(:p_specialty_keyword) is null then null else '%'||replace(replace(replace(upper(trim(:p_specialty_keyword)),'\','\\'),'%','\%'),'_','\_')||'%' end;
end;
/
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
where (:l_discipline_keyword is null or upper(d.discipline_name) like :l_discipline_keyword escape '\')
  and (:l_teacher_keyword is null or upper(t.first_name||' '||case when t.middle_name is not null then t.middle_name||' ' end||t.last_name) like :l_teacher_keyword escape '\')
  and (:l_specialty_keyword is null or upper(sp.specialty_name) like :l_specialty_keyword escape '\')
  and (:p_academic_year is null or dt.academic_year=:p_academic_year)
order by dt.academic_year,sp.specialty_name,c.semester_no,d.discipline_name,t.last_name,t.first_name,dt.curriculum_id,dt.teacher_id;

prompt TABLE_GRADES
-- Corresponding procedure: list_grades.
variable p_faculty_number varchar2(4000)
exec :p_faculty_number:=null;
variable p_discipline_keyword varchar2(4000)
exec :p_discipline_keyword:=null;
variable p_specialty_keyword varchar2(4000)
exec :p_specialty_keyword:=null;
variable p_academic_year number
exec :p_academic_year:=null;
variable p_min_grade number
exec :p_min_grade:=null;
variable l_discipline_keyword varchar2(4000)
begin
 :l_discipline_keyword:=case when trim(:p_discipline_keyword) is null then null else '%'||replace(replace(replace(upper(trim(:p_discipline_keyword)),'\','\\'),'%','\%'),'_','\_')||'%' end;
end;
/
variable l_specialty_keyword varchar2(4000)
begin
 :l_specialty_keyword:=case when trim(:p_specialty_keyword) is null then null else '%'||replace(replace(replace(upper(trim(:p_specialty_keyword)),'\','\\'),'%','\%'),'_','\_')||'%' end;
end;
/
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
where (trim(:p_faculty_number) is null or g.faculty_number=trim(:p_faculty_number))
  and (:l_discipline_keyword is null or upper(d.discipline_name) like :l_discipline_keyword escape '\')
  and (:l_specialty_keyword is null or upper(sp.specialty_name) like :l_specialty_keyword escape '\')
  and (:p_academic_year is null or g.academic_year=:p_academic_year)
  and (:p_min_grade is null or g.grade_value>=:p_min_grade)
order by s.last_name,s.first_name,g.faculty_number,c.semester_no,d.discipline_name,g.academic_year,g.curriculum_id;

prompt TABLE_SELECTS_COMPLETED: 11 lists
