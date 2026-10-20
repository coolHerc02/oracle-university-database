set define off
set heading on
set feedback on
set linesize 320
set pagesize 100
set trimout on
alter session set nls_date_format='YYYY-MM-DD';
column specialty_name format a32
column title_name format a18
column year_label format a10
column grade_label format a14
column faculty_number format a12
column first_name format a16
column middle_name format a16
column last_name format a16
column email format a32
column phone format a18
column discipline_name format a32
prompt REFERENCE_SPECIALTIES
select * from specialties order by specialty_id;
prompt REFERENCE_ACADEMIC_TITLES
select * from academic_titles order by title_id;
prompt REFERENCE_STUDY_YEARS
select * from study_years order by study_year_no;
prompt REFERENCE_SEMESTERS
select * from semesters order by semester_no;
prompt REFERENCE_GRADE_SCALE
select * from grade_scale order by grade_value;
prompt FICTIONAL_STUDENTS
select * from students order by faculty_number;
prompt FICTIONAL_TEACHERS
select * from teachers order by teacher_id;
prompt DISCIPLINES
select * from disciplines order by discipline_id;
prompt STUDENT_DISCIPLINE_GRADES
select * from grades order by faculty_number,curriculum_id;

prompt DISCIPLINE_TEACHER_ASSIGNMENTS
select * from discipline_teachers order by curriculum_id,teacher_id;

prompt CURRICULUM
select * from curriculum order by specialty_id,discipline_id;
