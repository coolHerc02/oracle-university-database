set define off
set long 1000000
set longchunksize 32767
set pagesize 0
set linesize 32767
set feedback off
set heading off
set trimspool on
set serveroutput on
alter session set nls_numeric_characters='.,';
select 'SUMMARY|'||'TABLES|'||count(*) from user_tables;
select 'SUMMARY|'||object_type||'|'||count(*) from user_objects
where object_type in ('PROCEDURE','TRIGGER','PACKAGE','PACKAGE BODY','VIEW','SEQUENCE')
group by object_type order by object_type;
select 'STUDENT|'||faculty_number||'|'||student_name||'|'||specialty_name||'|'||year_label||'|'||student_email
from v_academic_report where faculty_number='00010001' and rownum=1;
select 'ACADEMIC|'||discipline_name||'|'||semester_no||'|'||teacher_name||'|'||academic_title||'|'||
grade_value||'|'||to_char(grade_date,'YYYY-MM-DD')
from v_academic_report where faculty_number='00010001' order by semester_no,discipline_name,discipline_id;
select 'AVERAGE|'||faculty_number||'|'||student_name||'|'||to_char(average_grade,'FM0D00')
from v_student_averages where specialty_id=1 and study_year_no=1
order by average_grade desc,student_name,faculty_number;
select 'FAILED|'||faculty_number||'|'||student_name||'|'||grade_value||'|'||to_char(grade_date,'YYYY-MM-DD')
from v_failed_exams where discipline_id=1 order by student_name,faculty_number;
select 'RANKING|'||rank_position||'|'||faculty_number||'|'||student_name||'|'||to_char(average_grade,'FM0D00')
from v_specialty_ranking where specialty_id=1 order by rank_position,student_name,faculty_number;
select 'TEACHER|'||rank_position||'|'||teacher_name||'|'||title_name||'|'||discipline_count
from v_teacher_ranking order by rank_position,teacher_name,teacher_id;
select 'DATA_COUNT|'||'STUDENTS|'||count(*) from students
union all select 'DATA_COUNT|'||'TEACHERS|'||count(*) from teachers
union all select 'DATA_COUNT|'||'DISCIPLINES|'||count(*) from disciplines
union all select 'DATA_COUNT|'||'GRADES|'||count(*) from grades
union all select 'DATA_COUNT|'||'SPECIALTIES|'||count(*) from specialties
union all select 'DATA_COUNT|'||'ACADEMIC_TITLES|'||count(*) from academic_titles
union all select 'DATA_COUNT|'||'STUDY_YEARS|'||count(*) from study_years
union all select 'DATA_COUNT|'||'SEMESTERS|'||count(*) from semesters
union all select 'DATA_COUNT|'||'GRADE_SCALE|'||count(*) from grade_scale
union all select 'DATA_COUNT|'||'DISCIPLINE_TEACHERS|'||count(*) from discipline_teachers;
select 'INVALID|'||count(*) from user_objects where status<>'VALID';
select 'ERRORS|'||count(*) from user_errors;

select 'ASSIGNMENT|'||d.discipline_name||'|'||s.specialty_name||'|'||c.semester_no||'|'||t.first_name||' '||t.last_name
from discipline_teachers dt join curriculum c on c.curriculum_id=dt.curriculum_id
join disciplines d on d.discipline_id=c.discipline_id join specialties s on s.specialty_id=c.specialty_id
join teachers t on t.teacher_id=dt.teacher_id
order by c.specialty_id,d.discipline_name,t.teacher_id;
select 'DATA_COUNT|CURRICULUM|'||count(*) from curriculum;
