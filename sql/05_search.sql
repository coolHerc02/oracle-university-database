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
column teacher_name format a35
column academic_title format a18
column title_name format a18
column student_email format a30
column teacher_email format a30
column teacher_phone format a18
column faculty_number format a12
column grade_label format a14
column average_grade format 990.00
column rank_position format 999

-- Change the bound parameter to search for another student.
variable p_faculty_number varchar2(20)
exec :p_faculty_number := '00010001';
prompt SEARCH_1_GRADES_BY_STUDENT
select faculty_number, student_name, discipline_id, discipline_name, semester_no,
       grade_value, grade_label, grade_date
from v_academic_report where faculty_number = :p_faculty_number
order by semester_no, discipline_name, discipline_id;

-- Name resolves the ID so this example also works after sequence gaps.
variable p_discipline_id number
begin
 select min(discipline_id) into :p_discipline_id from disciplines
 where discipline_name = unistr('\0411\0430\0437\0438 \043e\0442 \0434\0430\043d\043d\0438');
end;
/
prompt SEARCH_2_GRADES_BY_DISCIPLINE
select discipline_id, discipline_name, faculty_number, student_name,
       specialty_name,year_label,grade_value,grade_date
from v_academic_report where discipline_id = :p_discipline_id
order by student_name, faculty_number;
