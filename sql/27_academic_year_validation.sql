-- Year-aware appointment and grade integrity; all fixtures roll back.
set define off
set serveroutput on size unlimited
whenever sqlerror exit sql.sqlcode rollback
declare
 n number;checks number:=0;c number;d number;v number;before_g clob;before_dt clob;after_xml clob;
 procedure ok(b boolean,msg varchar2) is begin
  if b is null or not b then raise_application_error(-20190,msg);end if;
  checks:=checks+1;dbms_output.put_line('PASS: '||msg);
 end;
 procedure rejects(s varchar2,wanted number,msg varchar2) is actual number:=0;
 begin begin execute immediate s;exception when others then actual:=sqlcode;end;
  ok(actual=wanted,msg||' (expected '||wanted||', actual '||actual||')');
 end;
begin
 savepoint academic_year_test;
 before_g:=dbms_xmlgen.getxml('select * from grades order by faculty_number,curriculum_id');
 before_dt:=dbms_xmlgen.getxml('select * from discipline_teachers order by curriculum_id,teacher_id,academic_year');
 select count(*) into n from user_tab_columns where table_name in('GRADES','DISCIPLINE_TEACHERS') and column_name='ACADEMIC_YEAR' and nullable='N';ok(n=2,'Academic year is mandatory in both tables');
 select count(*) into n from user_cons_columns where constraint_name='DISCIPLINE_TEACHERS_PK' and ((column_name='CURRICULUM_ID' and position=1) or(column_name='TEACHER_ID' and position=2) or(column_name='ACADEMIC_YEAR' and position=3));ok(n=3,'Appointment primary key includes academic year');
 select count(*) into n from user_cons_columns where constraint_name='GRADES_ASSIGNMENT_FK' and column_name='ACADEMIC_YEAR' and position=3;ok(n=1,'Grade FK includes the appointment year');
 select count(*) into n from user_cons_columns where constraint_name='GRADES_PK';ok(n=2,'One current student-course grade remains the primary key');
 select count(*) into n from grades where academic_year=2025;ok(n=60,'Sixty original grades belong to 2025/2026');
 select count(*) into n from grades where academic_year=2026;ok(n=4,'Four SIT/KST example grades belong to 2026/2027');
 select count(*) into n from discipline_teachers where academic_year=2025;ok(n=48,'Original specialty appointments retained in 2025/2026');
 select count(*) into n from discipline_teachers where academic_year=2026;ok(n=5,'Five SIT/KST appointments retained in 2026/2027');
 select discipline_id into d from disciplines where discipline_name=unistr('\041c\0430\0442\0435\043c\0430\0442\0438\043a\0430');
 c:=university_api.curriculum_for('00010001',d);
 select discipline_count into v from v_teacher_ranking where teacher_id=1;
 university_api.assign_curriculum_teacher(c,1,2027);
 select count(*) into n from discipline_teachers where curriculum_id=c and teacher_id=1 and academic_year in(2025,2027);ok(n=2,'Same teacher and course may have different academic years');
 select discipline_count into n from v_teacher_ranking where teacher_id=1;ok(n=v,'Teaching the same course in another year does not inflate distinct-course ranking');
 rejects('begin university_api.assign_curriculum_teacher('||c||',1,2025);end;',-1,'Duplicate teacher-course-year rejected');
 rejects('begin university_api.assign_curriculum_teacher('||c||',1,2026.5);end;',-2290,'Fractional academic year rejected without rounding');
 rejects('begin university_api.assign_curriculum_teacher('||c||',1,1899);end;',-2290,'Out-of-range academic year rejected');
 rejects('begin university_api.assign_curriculum_teacher('||c||',6);end;',-20171,'Ambiguous year must be specified explicitly');
 university_api.replace_curriculum_teacher(c,1,2,2027);
 select count(*) into n from discipline_teachers where curriculum_id=c and teacher_id=2 and academic_year=2027;ok(n=1,'Future-year teacher replacement succeeds');
 select count(*) into n from discipline_teachers where curriculum_id=c and teacher_id=1 and academic_year=2025;ok(n=1,'Replacement preserves historical teacher appointment');
 select count(*) into n from grades where faculty_number='00010001' and curriculum_id=c and academic_year=2025 and teacher_id=1;ok(n=1,'Historical grade retains its year and teacher');
 select teacher_count into n from v_academic_report where faculty_number='00010001' and curriculum_id=c;ok(n=2,'Historical report excludes teachers from other academic years');
 select count(*) into n from v_academic_report;ok(n=64,'Multiple appointment years never duplicate academic rows');
 university_api.unassign_curriculum_teacher(c,2,2027);
 select count(*) into n from discipline_teachers where curriculum_id=c and academic_year=2027;ok(n=0,'Delete removes only the selected year appointment');
 university_api.assign_curriculum_teacher(c,2,2026);
 rejects('begin university_api.set_grade(''00010001'','||d||',4,date ''2026-11-03'',2,2026);end;',-20172,'Existing grade cannot silently move into another academic year');
 rejects('begin university_api.set_grade(''00010007'','||d||',4,date ''2026-11-03'',1,2026);end;',-2291,'Owner cannot use a teacher appointed only in another year');
 university_api.set_grade('00010007',d,4,date '2026-11-03',2,2026);
 select count(*) into n from grades where faculty_number='00010007' and curriculum_id=c and academic_year=2026 and teacher_id=2;ok(n=1,'New-year grade references the new-year teacher');
 select teacher_count into n from v_academic_report where faculty_number='00010007' and curriculum_id=c;ok(n=1,'New-year report lists only new-year teachers');
 rejects('begin university_api.unassign_curriculum_teacher('||c||',2,2026);end;',-2292,'Appointment referenced by a grade is protected');
 rejects('begin university_api.delete_grade(''00010007'','||d||',2025);end;',-20172,'DELETE refuses a different academic year');
 university_api.delete_grade('00010007',d,2026);
 select count(*) into n from grades where faculty_number='00010007' and curriculum_id=c;ok(n=0,'Year-specific grade DELETE succeeds');
 rollback to academic_year_test;
 after_xml:=dbms_xmlgen.getxml('select * from grades order by faculty_number,curriculum_id');ok(dbms_lob.compare(before_g,after_xml)=0,'All grade rows and fields restored');
 after_xml:=dbms_xmlgen.getxml('select * from discipline_teachers order by curriculum_id,teacher_id,academic_year');ok(dbms_lob.compare(before_dt,after_xml)=0,'All appointment rows and fields restored');
 ok(not university_api.write_allowed,'Write guard closed after successful and rejected operations');
 dbms_output.put_line('ACADEMIC_YEAR_VALIDATION_PASSED: '||checks||' checks');
exception when others then rollback to academic_year_test;raise;
end;
/
