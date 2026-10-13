set define off
set serveroutput on
set long 1000000
set longchunksize 32767
set linesize 260
set pagesize 100
whenever sqlerror exit sql.sqlcode rollback
column discipline_name format a30
column teacher_name format a70
column average_grade format 990.00
prompt COMMITTED_SHARED_DISCIPLINES
select d.discipline_name,dt.teacher_count,dt.teacher_name
from disciplines d join v_discipline_teachers dt on dt.discipline_id=d.discipline_id
where dt.teacher_count>1 order by d.discipline_name;
prompt ASSIGN_AND_REMOVE_A_CO_TEACHER_THEN_ROLLBACK
declare d number;t number;
begin
 select min(discipline_id) into d from disciplines where discipline_name=unistr('\041c\0430\0442\0435\043c\0430\0442\0438\043a\0430');
 select teacher_id into t from teachers where email='teacher6@university.example';
 discipline_teacher_ins(d,t);
end;
/
select discipline_name,teacher_count,teacher_name,grade_value,average_grade
from v_academic_report where faculty_number='00010001' order by semester_no,discipline_name;
declare d number;t number;
begin
 select min(discipline_id) into d from disciplines where discipline_name=unistr('\041c\0430\0442\0435\043c\0430\0442\0438\043a\0430');
 select teacher_id into t from teachers where email='teacher6@university.example';
 discipline_teacher_del(d,t);
end;
/
rollback;
prompt MANY_TEACHERS_DEMO_ROLLED_BACK
