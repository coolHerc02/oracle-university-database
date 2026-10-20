set define off
set serveroutput on size unlimited
whenever sqlerror exit sql.sqlcode rollback

declare
 n number; v number; math_id number; alg_id number; os_id number;
 teacher1 number; teacher2 number; teacher3 number; teacher6 number; new_teacher number;
 passed pls_integer:=0;
 procedure ok(test boolean,label varchar2) is
 begin
  if test is null or not test then raise_application_error(-20997,'FAIL: '||label); end if;
  passed:=passed+1;dbms_output.put_line('PASS '||passed||': '||label);
 end;
 procedure err(statement varchar2,wanted number,label varchar2) is actual number:=0;
 begin
  begin execute immediate statement; exception when others then actual:=sqlcode; end;
  ok(actual=wanted,label||' (expected '||wanted||', actual '||actual||')');
 end;
begin
 if user<>'UNIVERSITY_PROJECT' then raise_application_error(-20000,'Use UNIVERSITY_PROJECT.'); end if;
 select count(*) into n from discipline_teachers;ok(n=53,'Fifty-three specialty-scoped teaching assignments');
 select count(*) into n from user_tab_columns where table_name='DISCIPLINES' and column_name='TEACHER_ID';
 ok(n=0,'Discipline no longer contains a single-teacher column');
 select count(*) into n from user_cons_columns
 where constraint_name='DISCIPLINE_TEACHERS_PK' and ((column_name='CURRICULUM_ID' and position=1) or (column_name='TEACHER_ID' and position=2));
 ok(n=2,'Composite assignment PK has ordered curriculum and teacher columns');
 select count(*) into n from (select curriculum_id from discipline_teachers group by curriculum_id having count(*)>1);
 ok(n=7,'Seven curriculum entries have multiple teachers');
 select count(*) into n from curriculum d where not exists(select 1 from discipline_teachers dt where dt.curriculum_id=d.curriculum_id);
 ok(n=0,'Every curriculum entry has at least one teacher');
 select count(*) into n from teachers t where (select count(distinct c.discipline_id) from discipline_teachers dt join curriculum c on c.curriculum_id=dt.curriculum_id where dt.teacher_id=t.teacher_id)<2;
 ok(n=0,'Every teacher leads at least two distinct disciplines');
 select min(discipline_id) into math_id from disciplines where discipline_name=unistr('\041c\0430\0442\0435\043c\0430\0442\0438\043a\0430');
 select min(discipline_id) into alg_id from disciplines where discipline_name=unistr('\0410\043b\0433\043e\0440\0438\0442\043c\0438');
 select min(discipline_id) into os_id from disciplines where discipline_name=unistr('\041e\043f\0435\0440\0430\0446\0438\043e\043d\043d\0438 \0441\0438\0441\0442\0435\043c\0438');
 select teacher_id into teacher1 from teachers where email='teacher1@university.example';
 select teacher_id into teacher2 from teachers where email='teacher2@university.example';
 select teacher_id into teacher3 from teachers where email='teacher3@university.example';
 select teacher_id into teacher6 from teachers where email='teacher6@university.example';
 select average_grade into v from v_student_averages where faculty_number='00010001';ok(v=6,'Student average remains six');
 select count(*) into n from v_academic_report where faculty_number='00010001';ok(n=4,'Academic report has one row per grade');
 select count(*) into n from v_academic_report where faculty_number='00010001' and discipline_id=math_id
 and teacher_count=2 and dbms_lob.instr(teacher_name,unistr('\041f\0435\0442\044a\0440'))>0
 and dbms_lob.instr(teacher_name,unistr('\041c\0430\0440\0438\044f'))>0;
 ok(n=1,'Academic row lists both teachers without repeating the grade');
 select count(*) into n from v_failed_exams where discipline_id=math_id;ok(n=2,'Failed students are not duplicated by teachers');
 select sum(discipline_count) into v from v_teacher_ranking;ok(v=18,'Teacher ranking counts distinct catalogue courses per teacher');
 err('begin university_api.assign_teacher('||math_id||','||teacher1||'); end;',-1,'Duplicate assignment is rejected');
 select count(*) into n from discipline_teachers;ok(n=53,'Duplicate refusal preserves all assignments');
 err('insert into discipline_teachers values('||math_id||','||teacher6||')',-20020,'Direct assignment INSERT guarded');
 err('update discipline_teachers set teacher_id=teacher_id where curriculum_id='||math_id,-20020,'Direct assignment UPDATE guarded');
 err('delete from discipline_teachers where curriculum_id='||math_id,-20020,'Direct assignment DELETE guarded');
 err('begin university_api.assign_teacher('||math_id||',999999); end;',-2291,'Missing teacher rejected');
 err('begin university_api.assign_teacher(999999,'||teacher1||'); end;',-2291,'Missing discipline rejected');
 err('begin university_api.unassign_teacher(999999,'||teacher1||'); end;',-20072,'Missing assignment reported');
 university_api.unassign_teacher(math_id,teacher2);
 select count(*) into n from discipline_teachers where curriculum_id=(select min(curriculum_id) from curriculum where discipline_id=math_id);ok(n=1,'Second teacher can be removed while minima hold');
 select count(*) into n from v_academic_report where faculty_number='00010001' and average_grade=6;ok(n=4,'Changing teacher list preserves transcript grain and average');
 err('begin university_api.unassign_teacher('||math_id||','||teacher1||'); end;',-2292,'Assignment referenced by grades cannot be removed');
 select count(*) into n from discipline_teachers where curriculum_id=(select min(curriculum_id) from curriculum where discipline_id=math_id) and teacher_id=teacher1;ok(n=1,'Last-teacher rejection restores assignment');
 err('begin university_api.unassign_teacher('||os_id||','||teacher3||'); end;',-2292,'Grading teacher assignment is protected by FK');
 err('begin university_api.replace_teacher('||os_id||','||teacher3||','||teacher1||'); end;',-2292,'Referenced replacement rolls back atomically');
 select count(*) into n from discipline_teachers where curriculum_id=(select min(curriculum_id) from curriculum where discipline_id=os_id) and teacher_id=teacher3;ok(n=1,'Rejected replacement preserves original teacher');
 discipline_teacher_ins(math_id,teacher6);
 select count(*) into n from discipline_teachers where curriculum_id=(select min(curriculum_id) from curriculum where discipline_id=math_id) and teacher_id=teacher6;ok(n=1,'Standalone assignment INSERT succeeds');
 discipline_teacher_del(math_id,teacher6);
 select count(*) into n from discipline_teachers where curriculum_id=(select min(curriculum_id) from curriculum where discipline_id=math_id) and teacher_id=teacher6;ok(n=0,'Standalone assignment DELETE succeeds');
 university_api.create_teacher_for_disciplines('MANY &',null,'Teacher',1,'+359000000077',
 'many.teacher@university.example',sys.odcinumberlist(math_id,alg_id),new_teacher);
 select count(*) into n from discipline_teachers where teacher_id=new_teacher;ok(n=2,'New teacher can join two existing disciplines');
 select count(*) into n from disciplines;ok(n=15,'Joining existing disciplines creates no duplicate disciplines');
 select count(*) into n from v_academic_report where faculty_number='00010001' and discipline_id=math_id
 and dbms_lob.instr(teacher_name,'MANY & Teacher')>0;
 ok(n=1,'CLOB teacher aggregation preserves ampersand text');
 err('declare t number; begin university_api.create_teacher_for_disciplines(''Dup'',null,''Teacher'',1,''+3590'',''dup@university.example'',sys.odcinumberlist('||math_id||','||math_id||'),t); end;',-1,'Repeated discipline in new teacher bundle rejected');
 select count(*) into n from teachers where email='dup@university.example';ok(n=0,'Failed bundle leaves no partial teacher');
 err('declare t number; begin university_api.create_teacher_for_disciplines(''One'',null,''Teacher'',1,''+3590'',''one@university.example'',sys.odcinumberlist('||math_id||'),t); end;',-20030,'Existing-discipline bundle needs at least two');
 err('declare t number; ids sys.odcinumberlist; begin university_api.create_teacher_for_disciplines(''Null'',null,''Teacher'',1,''+3590'',''null@university.example'',ids,t); end;',-20030,'NULL discipline list rejected');
 err('declare t number; begin university_api.create_teacher_for_disciplines(''Missing'',null,''Teacher'',1,''+3590'',''missing@university.example'',sys.odcinumberlist('||math_id||',999999),t); end;',-2291,'Missing discipline rolls back teacher bundle');
 err('begin university_api.unassign_teacher('||math_id||','||new_teacher||'); end;',-20041,'New teacher minimum remains enforced');
 university_api.update_discipline(math_id,'MANY renamed mathematics');
 select count(*) into n from discipline_teachers where curriculum_id=(select min(curriculum_id) from curriculum where discipline_id=math_id);ok(n=2,'Discipline metadata update preserves all its teachers');
 -- More than 4000 characters verifies genuine CLOB aggregation rather than LISTAGG truncation.
 for i in 1..40 loop
  university_api.create_teacher_for_disciplines(rpad('Stress'||i,60,'X'),null,rpad('Teacher',60,'Y'),1,
   '+359000000088','stress'||i||'@university.example',sys.odcinumberlist(math_id,alg_id),new_teacher);
 end loop;
 select count(*) into n from v_discipline_teachers where curriculum_id=(select min(curriculum_id) from curriculum where discipline_id=math_id) and dbms_lob.getlength(teacher_name)>4000;
 ok(n=1,'Teacher list safely exceeds VARCHAR2/LISTAGG limit');
 select count(*) into n from v_academic_report where faculty_number='00010001' and average_grade=6;
 ok(n=4,'Many teachers still leave four academic rows and average six');
 university_api.validate_rules;ok(not university_api.write_allowed,'Write guard reset after successes and failures');
 rollback;
 select count(*) into n from discipline_teachers;ok(n=53,'Rollback restores fifty-three assignments');
 select count(*) into n from teachers;ok(n=6,'Rollback restores six teachers');
 select count(*) into n from disciplines;ok(n=15,'Rollback restores fifteen disciplines');
 select count(*) into n from grades;ok(n=64,'Rollback preserves sixty-four grades');
 select count(*) into n from students;ok(n=20,'Rollback preserves twenty students');
 select count(*) into n from user_errors;ok(n=0,'No compilation errors');
 dbms_output.put_line('MANY_TEACHERS_VALIDATION_PASSED: '||passed||' checks');
exception when others then rollback;raise;
end;
/
