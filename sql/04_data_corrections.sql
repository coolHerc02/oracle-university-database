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
column faculty_number format a22
column email format a40
column grade_label format a14
column average_grade format 990.00
column rank_position format 999

-- Demonstrates input/correction. The examples are rolled back deliberately.
-- Remove the final rollback and COMMIT explicitly to retain your own corrections.
savepoint demonstration_start;
declare
 l_id number;
 l_grades university_api.t_grade_list;
begin
 select min(discipline_id) into l_id from disciplines where discipline_name=unistr('\041c\0430\0442\0435\043c\0430\0442\0438\043a\0430');
 university_api.set_grade('00010001',l_id,5,date '2026-06-15');
 university_api.update_student('00010001',unistr('\0410\043b\0435\043a\0441\0430\043d\0434\044a\0440'),unistr('\0418\0432\0430\043d\043e\0432'),unistr('\041f\0435\0442\0440\043e\0432'),
                               1,1,'alexander.petrov@university.example');
 university_api.rename_student_number('00010001','DEMO-00010001');
 university_api.print_academic_report('DEMO-00010001');

 l_grades(1).discipline_id := l_id; l_grades(1).grade_value := 4;
 l_grades(1).grade_date := date '2026-06-15';
 select min(discipline_id) into l_grades(2).discipline_id from disciplines
 where discipline_name=unistr('\0410\043b\0433\043e\0440\0438\0442\043c\0438');
 l_grades(2).grade_value := 5; l_grades(2).grade_date := date '2026-06-16';
 university_api.create_student('DEMO-NEW',unistr('\0414\0435\043c\043e'),null,unistr('\0421\0442\0443\0434\0435\043d\0442'),1,1,
                               'demo@university.example',l_grades);
end;
/
select faculty_number,student_name,email from (
 select faculty_number,student_name,student_email email from v_academic_report
) where faculty_number in ('DEMO-00010001','DEMO-NEW')
group by faculty_number,student_name,email
order by faculty_number;
rollback to demonstration_start;
exec university_api.validate_rules;
prompt CORRECTION_DEMONSTRATION_ROLLED_BACK_OK
