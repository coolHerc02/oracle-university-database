set define off
set serveroutput on size unlimited
whenever sqlerror exit sql.sqlcode rollback
declare
 n number; checks number:=0; a number;b number;d number;t number;sit number;kst number;code number;
 procedure ok(test boolean,msg varchar2) is
 begin
  if test is null or not test then raise_application_error(-20160,msg);end if;
  checks:=checks+1;dbms_output.put_line('PASS: '||msg);
 end;
begin
 savepoint curriculum_validation;
 select count(*) into n from user_tables;ok(n=11,'Eleven normalized tables');
 select count(*) into n from user_tab_columns where table_name in(select table_name from user_tables);ok(n=39,'Thirty-nine physical columns');
 select count(*) into n from user_constraints where constraint_type='R';ok(n=12,'Twelve foreign keys');
 select count(*) into n from user_tab_columns where table_name='DISCIPLINES' and column_name='SEMESTER_NO';ok(n=0,'Semester removed from catalogue');
 select count(*) into n from user_tab_columns where table_name in('GRADES','DISCIPLINE_TEACHERS') and column_name='DISCIPLINE_ID';ok(n=0,'No redundant catalogue discipline column in grades or assignments');
 select count(*) into n from user_objects where status<>'VALID';ok(n=0,'All objects valid');
 select count(*) into n from user_errors;ok(n=0,'No compilation errors');
 select count(*) into n from grades;ok(n=64,'Original 60 grades plus four fictional example grades');
 select count(*) into n from students;ok(n=20,'Original 18 students plus SIT/KST examples');
 select count(*) into n from v_academic_report;ok(n=64,'Exactly one report row per grade');
 select min(discipline_id) into d from disciplines where discipline_name=unistr('\0421\0410');
 select min(specialty_id) into sit from specialties where specialty_name=unistr('\0421\0418\0422');
 select min(specialty_id) into kst from specialties where specialty_name=unistr('\041a\0421\0422');
 select curriculum_id into a from curriculum where specialty_id=sit and discipline_id=d and semester_no=6;
 select curriculum_id into b from curriculum where specialty_id=kst and discipline_id=d and semester_no=4;
 ok(a<>b,'One SA catalogue course has distinct SIT/6 and KST/4 curricula');
 select count(*) into n from discipline_teachers where teacher_id=1 and curriculum_id in(a,b);ok(n=2,'Same teacher teaches SA in both specialty semesters');
 select count(*) into n from discipline_teachers where teacher_id=2 and curriculum_id=a;ok(n=0,'KST co-teacher has no SIT authorization');
 select count(*) into n from grades g join curriculum c on c.curriculum_id=g.curriculum_id join students s on s.faculty_number=g.faculty_number where c.specialty_id<>s.specialty_id;
 ok(n=0,'Every grade curriculum matches the student specialty');
 select count(*) into n from grades g where not exists(select 1 from discipline_teachers dt where dt.curriculum_id=g.curriculum_id and dt.teacher_id=g.teacher_id);
 ok(n=0,'Every grade points to its authorized teaching assignment');
 code:=0;begin university_api.set_curriculum_grade('SIT-DEMO',b,4,date '2026-10-20',1);exception when others then code:=sqlcode;end;
 ok(code=-20140,'Owner API also rejects a curriculum from another specialty');
 code:=0;begin university_api.add_curriculum(sit,d,4,1,t);exception when others then code:=sqlcode;end;
 ok(code=-1,'One catalogue discipline occurs once per specialty curriculum');
 code:=0;begin university_api.update_student('SIT-DEMO','Demo',null,'SIT',kst,3,'sit.demo@university.example');exception when others then code:=sqlcode;end;
 ok(code=-20140,'Specialty change cannot leave grades in the previous specialty');
 select semester_no into n from curriculum where curriculum_id=a;ok(n=6,'Failed changes retain SIT semester six');
 university_api.update_curriculum(a,5);select semester_no into n from curriculum where curriculum_id=b;ok(n=4,'Changing SIT semester never changes KST');
 rollback to curriculum_validation;
 select semester_no into n from curriculum where curriculum_id=a;ok(n=6,'Caller rollback restores the SIT semester');
 select count(*) into n from teachers t where (select count(distinct c.discipline_id) from discipline_teachers dt join curriculum c on c.curriculum_id=dt.curriculum_id where dt.teacher_id=t.teacher_id)<2;
 ok(n=0,'Teacher minimum counts distinct courses, not specialty assignments');
 select count(*) into n from curriculum c where not exists(select 1 from discipline_teachers dt where dt.curriculum_id=c.curriculum_id);
 ok(n=0,'Every curriculum entry has a teacher');
 select count(*) into n from students s where(select count(*) from grades g where g.faculty_number=s.faculty_number)<2;
 ok(n=0,'Every student retains two or more grades');
 ok(not university_api.write_allowed,'Write guard closed after failures');
 dbms_output.put_line('CURRICULUM_VALIDATION_PASSED: '||checks||' checks');
exception when others then rollback to curriculum_validation;raise;
end;
/
