set define off
set serveroutput on
whenever sqlerror exit sql.sqlcode rollback
declare
 l_passed number:=0; l_count number; l_value number; l_math number; l_algorithm number;
 l_os number; l_os_teacher number; l_target_teacher number; l_ids sys.odcinumberlist;
 l_teacher number; l_grades university_api.t_grade_list; l_disc university_api.t_discipline_list;
 procedure assert_true(p_value boolean,p_name varchar2) is
 begin
   if p_value is null or not p_value then raise_application_error(-20999,'FAIL: '||p_name); end if;
   l_passed:=l_passed+1; dbms_output.put_line('PASS '||to_char(l_passed,'FM00')||': '||p_name);
 end;
 procedure expect_error(p_sql varchar2,p_expected number,p_name varchar2) is
   l_error number:=0;
 begin
   begin execute immediate p_sql; exception when others then l_error:=sqlcode; end;
   assert_true(l_error=p_expected,p_name||' (expected '||p_expected||', actual '||l_error||')');
 end;
begin
 if user <> 'UNIVERSITY_PROJECT' then raise_application_error(-20000,'Use UNIVERSITY_PROJECT.'); end if;
 select count(*) into l_count from user_tables; assert_true(l_count=11,'Eleven project tables');
 select count(*) into l_count from user_constraints where constraint_type='R'; assert_true(l_count=12,'Twelve foreign keys');
 select count(*) into l_count from user_objects where status<>'VALID'; assert_true(l_count=0,'All schema objects VALID');
 select count(*) into l_count from user_errors; assert_true(l_count=0,'No compilation errors');
 select count(*) into l_count from students; assert_true(l_count=20,'Twenty seeded students');
 select count(*) into l_count from teachers; assert_true(l_count=6,'Six seeded teachers');
 select count(*) into l_count from disciplines; assert_true(l_count=15,'Fifteen seeded disciplines');
 select count(*) into l_count from grades; assert_true(l_count=64,'Sixty-four seeded grades');
 select count(*) into l_count from students s where (select count(*) from grades g where g.faculty_number=s.faculty_number)<2;
 assert_true(l_count=0,'Every student has at least two distinct disciplines');
 select count(*) into l_count from teachers t where (select count(distinct c.discipline_id) from discipline_teachers d join curriculum c on c.curriculum_id=d.curriculum_id where d.teacher_id=t.teacher_id)<2;
 assert_true(l_count=0,'Every teacher leads at least two disciplines');
 select count(*) into l_count from students where faculty_number='00010001' and first_name=unistr('\0410\043b\0435\043a\0441\0430\043d\0434\044a\0440');
 assert_true(l_count=1,'Leading zeroes and Cyrillic retained');

 select min(discipline_id) into l_math from disciplines where discipline_name=unistr('\041c\0430\0442\0435\043c\0430\0442\0438\043a\0430');
 select min(discipline_id) into l_algorithm from disciplines where discipline_name=unistr('\0410\043b\0433\043e\0440\0438\0442\043c\0438');
 select d.discipline_id,dt.teacher_id into l_os,l_os_teacher from disciplines d join curriculum c on c.discipline_id=d.discipline_id and c.specialty_id=1 join discipline_teachers dt on dt.curriculum_id=c.curriculum_id where d.discipline_name=unistr('\041e\043f\0435\0440\0430\0446\0438\043e\043d\043d\0438 \0441\0438\0441\0442\0435\043c\0438');
 select min(teacher_id) into l_target_teacher from discipline_teachers where curriculum_id=(select min(curriculum_id) from curriculum where discipline_id=l_math);

 expect_error(q'~declare d university_api.t_discipline_list; t number; ids sys.odcinumberlist;
 begin d(1).discipline_name:='Test'; d(1).semester_no:=1;
 university_api.create_teacher('Test',null,'Teacher',1,'+359000000000','test@university.example',d,t,ids); end;~',
 -20030,'Reject teacher with one discipline');
 expect_error(q'~declare g university_api.t_grade_list; begin
 g(1).discipline_id:=1; g(1).grade_value:=4; g(1).grade_date:=date '2026-06-10';
 university_api.create_student('TEST-ONE','Test',null,'Student',1,1,'test@university.example',g); end;~',
 -20031,'Reject student with one discipline');
 expect_error(q'~declare g university_api.t_grade_list; begin
 select min(discipline_id) into g(1).discipline_id from disciplines where discipline_name=unistr('\041c\0430\0442\0435\043c\0430\0442\0438\043a\0430');
 select min(discipline_id) into g(2).discipline_id from disciplines where discipline_name=unistr('\0410\043b\0433\043e\0440\0438\0442\043c\0438');
 g(1).grade_value:=4; g(1).grade_date:=date '2026-06-10';
 g(2).grade_value:=5; g(2).grade_date:=date '2026-06-11';
 g(2).discipline_id:=g(1).discipline_id;
 university_api.create_student('TEST-DUP','Test',null,'Student',1,1,'test@university.example',g); end;~',
 -1,'Reject duplicate student-discipline pair');
 select count(*) into l_count from students where faculty_number='TEST-DUP';
 assert_true(l_count=0,'Failed create_student rolled back all its rows');
 expect_error(q'~declare g university_api.t_grade_list; begin
 select min(discipline_id) into g(1).discipline_id from disciplines where discipline_name=unistr('\041c\0430\0442\0435\043c\0430\0442\0438\043a\0430');
 select min(discipline_id) into g(2).discipline_id from disciplines where discipline_name=unistr('\0410\043b\0433\043e\0440\0438\0442\043c\0438');
 g(1).grade_value:=4; g(1).grade_date:=date '2026-06-10';
 g(2).grade_value:=5; g(2).grade_date:=date '2026-06-11';
 university_api.create_student('00010001','Test',null,'Student',1,1,'test@university.example',g); end;~',
 -1,'Reject duplicate faculty number');
 expect_error(q'~declare g university_api.t_grade_list; begin
 select min(discipline_id) into g(1).discipline_id from disciplines where discipline_name=unistr('\041c\0430\0442\0435\043c\0430\0442\0438\043a\0430');
 select min(discipline_id) into g(2).discipline_id from disciplines where discipline_name=unistr('\0410\043b\0433\043e\0440\0438\0442\043c\0438');
 g(1).grade_value:=4; g(1).grade_date:=date '2026-06-10';
 g(2).grade_value:=5; g(2).grade_date:=date '2026-06-11';
 university_api.create_student('TEST-FK','Test',null,'Student',999999,1,'test@university.example',g); end;~',
 -2291,'Reject missing specialty');
 expect_error('begin university_api.set_grade(''00010001'','||l_math||',2.5,date ''2026-06-10''); end;',
 -2291,'Reject fractional grade without rounding');
 expect_error('begin university_api.set_grade(''00010001'','||l_math||',7,date ''2026-06-10''); end;',
 -2291,'Reject grade outside scale');
 expect_error('begin university_api.set_grade(''00010001'','||l_math||',5,null); end;',
 -1407,'Reject null grade date');
 expect_error(q'~insert into grade_scale values(7,'Invalid',1)~',-2290,'CHECK rejects invalid scale value');
 expect_error(q'~insert into semesters values(100,1,0)~',-2290,'CHECK rejects invalid semester mapping');
 expect_error(q'~declare g university_api.t_grade_list; begin
 select min(discipline_id) into g(1).discipline_id from disciplines where discipline_name=unistr('\041c\0430\0442\0435\043c\0430\0442\0438\043a\0430');
 select min(discipline_id) into g(2).discipline_id from disciplines where discipline_name=unistr('\0410\043b\0433\043e\0440\0438\0442\043c\0438');
 g(1).grade_value:=4; g(1).grade_date:=date '2026-06-10';
 g(2).grade_value:=5; g(2).grade_date:=date '2026-06-11';
 university_api.create_student('TEST-EMAIL','Test',null,'Student',1,1,'invalid',g); end;~',
 -2290,'Reject invalid email form');
 expect_error(q'~update students set email='direct@university.example' where faculty_number='00010001'~',
 -20020,'Direct core DML is guarded');
 expect_error('begin university_api.replace_teacher('||l_os||','||l_os_teacher||','||l_target_teacher||'); end;',
 -2292,'Referenced grading assignment cannot be replaced');
 select teacher_id into l_value from discipline_teachers where curriculum_id=(select min(curriculum_id) from curriculum where discipline_id=l_os);
 assert_true(l_value=l_os_teacher,'Rejected reassignment restored original teacher');

 expect_error('begin university_api.set_grade(''MISSING-STUDENT'','||l_math||',4,date ''2026-06-10''); end;',
 -20141,'Reject grade for missing student');
 expect_error('begin university_api.set_grade(''00010001'',999999,4,date ''2026-06-10''); end;',
 -20141,'Reject grade for missing discipline');
 expect_error('begin university_api.assign_teacher('||l_os||',999999); end;',
 -2291,'Reject discipline with missing teacher');
 expect_error('begin university_api.update_curriculum('||university_api.curriculum_for('00010001',l_os)||',999999); end;',
 -2291,'Reject discipline with missing semester');
 expect_error(q'~begin university_api.update_teacher(~'||l_os_teacher||q'~,'Test',null,'Teacher',999999,'+359000000000','test@university.example'); end;~',
 -2291,'Reject teacher with missing academic title');

 assert_true(not university_api.write_allowed,'Write guard reset after failures');

 select average_grade into l_value from v_student_averages where faculty_number='00010001';
 assert_true(l_value=6,'Academic average matches hand calculation');
 select count(*) into l_count from v_specialty_ranking where faculty_number in('00010001','00010004') and rank_position=1 and average_grade=6;
 assert_true(l_count=2,'Equal averages share DENSE_RANK position');
 select rank_position into l_value from v_specialty_ranking where faculty_number='00010016';
 assert_true(l_value=2,'Next distinct average has dense rank two');
 select count(*) into l_count from v_failed_exams where discipline_id=l_math and faculty_number in('00010003','00010006');
 assert_true(l_count=2,'Failed report matches two expected mathematics students');
 select sum(discipline_count) into l_value from v_teacher_ranking;
 assert_true(l_value=18,'Teacher counts total distinct assignments independently of grades');

 savepoint validation_correction;
 university_api.set_grade('00010001',l_math,2,date '2026-06-15');
 select average_grade into l_value from v_student_averages where faculty_number='00010001';
 assert_true(l_value=5,'Grade correction changes average from six to five');
 select rank_position into l_value from v_specialty_ranking where faculty_number='00010001';
 assert_true(l_value=3,'Grade correction changes ranking');
 rollback to validation_correction;
 select average_grade into l_value from v_student_averages where faculty_number='00010001';
 assert_true(l_value=6,'Caller rollback restores original average');

 savepoint validation_rename;
 university_api.rename_student_number('00010001','TEST-RENAME');
 select count(*) into l_count from grades where faculty_number='TEST-RENAME';
 assert_true(l_count=4,'Faculty number correction preserves all grades');
 select count(*) into l_count from students where faculty_number='00010001';
 assert_true(l_count=0,'Old faculty number removed consistently during correction');
 rollback to validation_rename;

 savepoint validation_teacher;
 l_disc(1).discipline_name:='Test A'; l_disc(1).semester_no:=1;
 l_disc(2).discipline_name:='Test B'; l_disc(2).semester_no:=2;
 university_api.create_teacher('Test',null,'Teacher',1,'+359000000000','test@university.example',l_disc,l_teacher,l_ids);
 select count(*) into l_count from discipline_teachers where teacher_id=l_teacher;
 assert_true(l_count=2 and l_ids.count=2,'Teacher and two disciplines created atomically');
 rollback to validation_teacher;

 university_api.validate_rules;
 select count(*) into l_count from students;
 assert_true(l_count=20,'Validation leaves seed student count unchanged');
 select count(*) into l_count from teachers;
 assert_true(l_count=6,'Validation leaves seed teacher count unchanged');
 select count(*) into l_count from disciplines;
 assert_true(l_count=15,'Validation leaves seed discipline count unchanged');
 select count(*) into l_count from grades;
 assert_true(l_count=64,'Validation leaves seed grade count unchanged');
 dbms_output.put_line('VALIDATION_PASSED: '||l_passed||' checks');
end;
/
rollback;
