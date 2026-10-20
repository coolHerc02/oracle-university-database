set define off
set long 1000000
set longchunksize 32767
set serveroutput on
set linesize 420
set pagesize 100
set trimout on
set trimspool on
alter session set nls_date_format='YYYY-MM-DD';
column student_name format a35
column specialty_name format a32
column year_label format a10
column discipline_name format a30
column teacher_name format a65
column grading_teacher_name format a35
column academic_title format a35
column title_name format a18
column student_email format a30
column teacher_email format a30
column teacher_phone format a18
column faculty_number format a12
column grade_label format a14
column average_grade format 990.00
column rank_position format 999

variable p_faculty_number varchar2(20)
variable p_specialty_id number
variable p_study_year_no number
variable p_discipline_id number
begin
 :p_faculty_number := '00010001'; :p_specialty_id := 1; :p_study_year_no := 1;
 select min(discipline_id) into :p_discipline_id from disciplines
 where discipline_name = unistr('\041c\0430\0442\0435\043c\0430\0442\0438\043a\0430');
end;
/
prompt REPORT_1_ACADEMIC_TRANSCRIPT_ALL_SOURCE_FIELDS
select faculty_number,student_name,student_email,specialty_name,year_label,
       discipline_name,semester_no,teacher_name,academic_title,teacher_phone,
       teacher_email,grading_teacher_id,grading_teacher_name,
       grade_value,grade_label,grade_date,round(average_grade,2) average_grade
from v_academic_report where faculty_number=:p_faculty_number
order by semester_no,discipline_name,discipline_id;

prompt REPORT_2_STUDENT_AVERAGES_FILTERED_BY_SPECIALTY_AND_YEAR
select faculty_number,student_name,specialty_name,year_label,discipline_count,
       round(average_grade,2) average_grade
from v_student_averages
where specialty_id=:p_specialty_id and study_year_no=:p_study_year_no
order by v_student_averages.average_grade desc,student_name,faculty_number;

prompt REPORT_3_FAILED_STUDENTS_BY_DISCIPLINE
select discipline_name,faculty_number,student_name,specialty_name,
       study_year_no,grade_value,grade_date
from v_failed_exams where discipline_id=:p_discipline_id
order by student_name,faculty_number;

prompt REPORT_4_RANKING_WITHIN_SPECIALTY
select rank_position,faculty_number,student_name,year_label,
       discipline_count,round(average_grade,2) average_grade
from v_specialty_ranking where specialty_id=:p_specialty_id
order by rank_position,student_name,faculty_number;

prompt REPORT_5_TEACHER_RANKING_BY_DISCIPLINE_COUNT
select rank_position,teacher_id,teacher_name,title_name,discipline_count
from v_teacher_ranking
order by rank_position,teacher_name,teacher_id;

prompt PLSQL_EXPLICIT_CURSOR_ACADEMIC_REPORT
exec university_api.print_academic_report(:p_faculty_number);
prompt PLSQL_REF_CURSOR_ACADEMIC_REPORT
variable academic_result refcursor
exec university_api.get_academic_report(:p_faculty_number,:academic_result);
print academic_result
