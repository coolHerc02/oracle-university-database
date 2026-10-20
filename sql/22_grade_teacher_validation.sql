-- Structural and data-integrity checks complementing real-login JDBC tests.
set define off
set serveroutput on size unlimited
whenever sqlerror exit sql.sqlcode rollback
declare
 n number; passed number:=0; before_xml clob; after_xml clob; code number;
 procedure ok(test boolean,message varchar2) is
 begin
  if test is null or not test then raise_application_error(-20120,message);end if;
  passed:=passed+1;dbms_output.put_line('PASS: '||message);
 end;
begin
 savepoint grade_teacher_validation;
 select count(*) into n from user_tab_columns where table_name='GRADES' and column_name='TEACHER_ID' and nullable='N';
 ok(n=1,'GRADES.teacher_id is mandatory');
 select count(*) into n from user_constraints where table_name='GRADES' and constraint_name='GRADES_ASSIGNMENT_FK' and status='ENABLED' and validated='VALIDATED';
 ok(n=1,'Composite assignment FK is enabled and validated');
 select count(*) into n from user_cons_columns where constraint_name='GRADES_ASSIGNMENT_FK'
 and ((column_name='CURRICULUM_ID' and position=1) or (column_name='TEACHER_ID' and position=2));
 ok(n=2,'Composite FK column order is discipline then teacher');
 select count(*) into n from user_constraints fk join user_constraints pk on pk.constraint_name=fk.r_constraint_name
 where fk.constraint_name='GRADES_ASSIGNMENT_FK' and pk.table_name='DISCIPLINE_TEACHERS';
 ok(n=1,'FK points to DISCIPLINE_TEACHERS, not just TEACHERS');
 select count(*) into n from user_cons_columns where constraint_name='GRADES_PK'
 and ((column_name='FACULTY_NUMBER' and position=1) or(column_name='CURRICULUM_ID' and position=2));
 ok(n=2,'One grade per student-course remains the primary key');
 select count(*) into n from user_cons_columns where constraint_name='GRADES_PK' and column_name='TEACHER_ID';
 ok(n=0,'Teacher is not added to the grade primary key');
 select count(*) into n from grades g where not exists(select 1 from discipline_teachers dt where dt.curriculum_id=g.curriculum_id and dt.teacher_id=g.teacher_id);
 ok(n=0,'Every grade belongs to a valid teaching assignment');
 select count(*) into n from grades;
 ok(n=64,'All sixty-four sample grades retained');
 select count(*) into n from v_academic_report;
 ok(n=64,'Academic report still has one row per grade');
 select count(*) into n from v_academic_report where grading_teacher_id is null or grading_teacher_name is null;
 ok(n=0,'Academic report identifies the grading teacher');
 select count(*) into n from user_objects where status<>'VALID';
 ok(n=0,'All schema objects are valid');
 select count(*) into n from user_errors;
 ok(n=0,'No compilation errors');
 before_xml:=dbms_xmlgen.getxml('select * from grades order by faculty_number,curriculum_id');
 code:=0;
 begin university_api.set_grade('00010001',1,4,date '2026-10-20',3);exception when others then code:=sqlcode;end;
 ok(code=-2291,'Even the owner cannot store an unassigned teacher in a grade');
 code:=0;
 begin university_api.unassign_teacher(1,1);exception when others then code:=sqlcode;end;
 ok(code=-2292,'Assignment referenced by grades cannot be removed');
 after_xml:=dbms_xmlgen.getxml('select * from grades order by faculty_number,curriculum_id');
 ok(dbms_lob.compare(before_xml,after_xml)=0,'Rejected operations preserve all grade values, dates and authors');
 ok(not university_api.write_allowed,'Write guard is closed after rejected operations');
 rollback to grade_teacher_validation;
 dbms_output.put_line('GRADE_TEACHER_VALIDATION_PASSED: '||passed||' checks');
exception when others then rollback to grade_teacher_validation;raise;
end;
/
