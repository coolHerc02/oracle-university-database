set define off
set serveroutput on size unlimited
whenever sqlerror exit sql.sqlcode rollback
declare
 l_passed pls_integer:=0; l_count number; l_value number; l_error number;
 l_teacher number; l_d1 number; l_d2 number; l_d3 number; l_lookup number;
 l_title number; l_specialty number; l_year number; l_date date;
 l_lines dbms_output.chararr; l_linecount integer; l_text varchar2(32767);
 procedure assert_true(p_value boolean,p_name varchar2) is
 begin
  if p_value is null or not p_value then raise_application_error(-20998,'FAIL: '||p_name); end if;
  l_passed:=l_passed+1; dbms_output.put_line('PASS '||l_passed||': '||p_name);
 end;
 procedure expect_error(p_sql varchar2,p_code number,p_name varchar2) is
  l_actual number:=0;
 begin
  begin execute immediate p_sql; exception when others then l_actual:=sqlcode; end;
  assert_true(l_actual=p_code,p_name||' (expected '||p_code||', actual '||l_actual||')');
 end;
 procedure capture_output is
 begin
  l_linecount:=1000; l_text:=null;
  dbms_output.get_lines(l_lines,l_linecount);
  for i in 1..l_linecount loop
   l_text:=l_text||l_lines(i)||chr(10);
  end loop;
  for i in 1..l_linecount loop dbms_output.put_line(l_lines(i)); end loop;
 end;
begin
 if user<>'UNIVERSITY_PROJECT' then raise_application_error(-20000,'Use UNIVERSITY_PROJECT.'); end if;
 select count(*) into l_count from user_objects where object_type='PROCEDURE' and status='VALID'
 and object_name in ('STUDENT_INS','STUDENT_UPD','TEACHER_INS','TEACHER_UPD','DISCIPLINE_INS','DISCIPLINE_UPD',
 'GRADE_INS','GRADE_UPD','ACADEMIC_REPORT','FIND_STUDENT','FIND_DISCIPLINE','TEACHER_DISCIPLINES',
 'DISCIPLINE_TEACHER_INS','DISCIPLINE_TEACHER_DEL');
 assert_true(l_count=14,'Fourteen standalone procedures VALID');
 select count(*) into l_count from user_triggers
 where trigger_name='GRADES_AFTER_INSERT' and trigger_type='AFTER EACH ROW' and status='ENABLED';
 assert_true(l_count=1,'AFTER INSERT row trigger enabled');
 select min(title_id) into l_title from academic_titles;
 select min(specialty_id) into l_specialty from specialties;
 select min(study_year_no) into l_year from study_years;

 insert into specialties(specialty_name) values('LESSON lookup') returning specialty_id into l_lookup;
 assert_true(l_lookup is not null and l_lookup>0,'BEFORE INSERT sequence trigger supplies lookup ID');

 teacher_ins('LESSON',null,'Teacher',l_title,'+359000000099','lesson.teacher@university.example',
 'LESSON discipline 1',1,'LESSON discipline 2',2,l_teacher,l_d1,l_d2);
 select count(*) into l_count from discipline_teachers where teacher_id=l_teacher;
 assert_true(l_count=2 and l_d1<>l_d2,'TEACHER_INS creates two distinct disciplines atomically');
 teacher_upd(l_teacher,'LESSON',null,'Updated',l_title,'+359000000098','updated.teacher@university.example');
 select count(*) into l_count from teachers where teacher_id=l_teacher and last_name='Updated' and phone='+359000000098';
 assert_true(l_count=1,'TEACHER_UPD changes contact data');

 student_ins('LESSON-STUDENT','LESSON',null,'Student',l_specialty,l_year,'lesson.student@university.example',
 l_d1,4,date '2026-06-10',l_d2,5,date '2026-06-11');
 select count(*) into l_count from grades where faculty_number='LESSON-STUDENT';
 assert_true(l_count=2,'STUDENT_INS creates student and two grades');
 capture_output;
 assert_true(instr(l_text,'AFTER INSERT: student=LESSON-STUDENT')>0,'AFTER trigger reports actual inserted grades');
 student_upd('LESSON-STUDENT','LESSON',null,'Updated',l_specialty,l_year,'updated.student@university.example');
 select count(*) into l_count from students where faculty_number='LESSON-STUDENT' and last_name='Updated'
 and email='updated.student@university.example';
 assert_true(l_count=1,'STUDENT_UPD corrects names and email');

 discipline_ins('LESSON discipline 3',3,l_teacher,l_d3);
 select count(*) into l_count from discipline_teachers where teacher_id=l_teacher;
 assert_true(l_count=3,'DISCIPLINE_INS adds a discipline');
 discipline_upd(l_d3,'LESSON updated discipline',4);
 select count(*) into l_count from disciplines where discipline_id=l_d3 and semester_no=4
 and discipline_name='LESSON updated discipline';
 assert_true(l_count=1,'DISCIPLINE_UPD changes name and semester');

 grade_ins('LESSON-STUDENT',l_d3,6,date '2026-06-12');
 select count(*) into l_count from grades where faculty_number='LESSON-STUDENT';
 assert_true(l_count=3,'GRADE_INS adds one new student-discipline pair');
 grade_upd('LESSON-STUDENT',l_d3,5,date '2026-06-13');
 select grade_value,grade_date into l_value,l_date from grades
 where faculty_number='LESSON-STUDENT' and discipline_id=l_d3;
 assert_true(l_value=5 and l_date=date '2026-06-13','GRADE_UPD corrects existing value and date');
 expect_error('begin grade_ins(''LESSON-STUDENT'','||l_d3||',2,date ''2026-06-14''); end;',
 -20061,'GRADE_INS refuses duplicate pair');
 select grade_value into l_value from grades where faculty_number='LESSON-STUDENT' and discipline_id=l_d3;
 assert_true(l_value=5,'Refused INSERT does not overwrite grade');
 expect_error('begin grade_upd(''LESSON-STUDENT'',999999,4,date ''2026-06-14''); end;',
 -20062,'GRADE_UPD refuses missing pair');
 expect_error('begin grade_upd(''LESSON-STUDENT'','||l_d3||',2.5,date ''2026-06-14''); end;',
 -2291,'Standalone procedure rejects fractional grade');
 expect_error('begin grade_upd(''LESSON-STUDENT'','||l_d3||',5,null); end;',
 -1407,'Standalone procedure rejects NULL grade date');
 select grade_value,grade_date into l_value,l_date from grades
 where faculty_number='LESSON-STUDENT' and discipline_id=l_d3;
 assert_true(l_value=5 and l_date=date '2026-06-13','Failed UPDATE restores previous value and date');

 expect_error('begin student_ins(''LESSON-DUP'',''LESSON'',null,''Student'','||l_specialty||','||l_year||
 ',''lesson.dup@university.example'','||l_d1||',4,date ''2026-06-10'','||l_d1||',5,date ''2026-06-11''); end;',
 -1,'STUDENT_INS rejects repeated discipline atomically');
 select count(*) into l_count from students where faculty_number='LESSON-DUP';
 assert_true(l_count=0,'Failed student insertion leaves no partial student');
 expect_error('begin academic_report(''LESSON-MISSING''); end;',-20043,'Explicit cursor reports missing student');
 academic_report('LESSON-STUDENT'); capture_output;
 assert_true(instr(l_text,'Student: LESSON-STUDENT LESSON Updated')>0 and instr(l_text,'Average: 4.67')>0,
 'OPEN/FETCH/CLOSE cursor prints ordered academic report and average');
 teacher_disciplines(l_teacher); capture_output;
 assert_true(instr(l_text,'LESSON updated discipline | semester 4')>0,'FOR cursor lists teacher disciplines');
 find_student(unistr('\0410\043b\0435\043a\0441\0430\043d\0434\044a\0440')); capture_output;
 assert_true(instr(l_text,'00010001')>0 and instr(l_text,'Student matches: 1')>0,'LIKE cursor finds Cyrillic student keyword');
 find_student('%'); capture_output;
 assert_true(instr(l_text,'Student matches: 0')>0,'LIKE cursor treats percent as literal text');
 find_discipline('LESSON updated'); capture_output;
 assert_true(instr(l_text,'Discipline matches: 1')>0,'LIKE cursor finds discipline keyword');
 expect_error('begin teacher_disciplines(999999); end;',-20045,'Teacher cursor rejects missing teacher');
 university_api.validate_rules;
 assert_true(not university_api.write_allowed,'Write guard inactive after successful and failed procedures');

 rollback;
 select count(*) into l_count from students; assert_true(l_count=18,'ROLLBACK restores eighteen seed students');
 select count(*) into l_count from teachers; assert_true(l_count=6,'ROLLBACK restores six seed teachers');
 select count(*) into l_count from disciplines; assert_true(l_count=14,'ROLLBACK restores fourteen seed disciplines');
 select count(*) into l_count from grades; assert_true(l_count=60,'ROLLBACK restores sixty seed grades');
 select count(*) into l_count from specialties; assert_true(l_count=3,'ROLLBACK removes temporary lookup');
 select count(*) into l_count from user_errors; assert_true(l_count=0,'No Oracle compilation errors');
 dbms_output.put_line('LESSON_VALIDATION_PASSED: '||l_passed||' checks');
exception when others then rollback; raise;
end;
/
