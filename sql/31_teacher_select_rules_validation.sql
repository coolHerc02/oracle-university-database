-- Reporting fixtures are rolled back. Core minimum-two rules remain active.
set define off
set serveroutput on size unlimited
whenever sqlerror exit sql.sqlcode rollback
declare
 n number;checks pls_integer:=0;report clob;title_id number;specialty_id number;
 teacher_a number;teacher_b number;owner_teacher number;curr_a number;curr_b number;
 course_a number;course_b number;course_name varchar2(100);year_label varchar2(30);
 inputs university_api.t_grade_list;
 output_lines dbms_output.chararr;line_count integer;output_text varchar2(32767);
 type t_texts is table of clob index by pls_integer;
 type t_names is table of varchar2(100) index by pls_integer;
 before_rows t_texts;table_names t_names;row_order t_names;
 procedure ok(b boolean,message varchar2) is
 begin
  if b is null or not b then raise_application_error(-20980,message);end if;
  checks:=checks+1;report:=report||'PASS: '||message||chr(10);
 end;
 procedure drain is
 begin
  line_count:=1000;output_text:=null;dbms_output.get_lines(output_lines,line_count);
  for i in 1..line_count loop output_text:=output_text||output_lines(i)||chr(10);end loop;
 end;
 procedure rejected(p_sql varchar2,message varchar2) is actual number:=0;
 begin
  begin execute immediate p_sql;exception when others then actual:=sqlcode;end;
  ok(actual=-20063,message);
 end;
 procedure print_report is offset_no number:=1;piece varchar2(8000);
 begin
  while offset_no<=dbms_lob.getlength(report) loop
   piece:=dbms_lob.substr(report,8000,offset_no);dbms_output.put_line(piece);offset_no:=offset_no+length(piece);
  end loop;
 end;
begin
 if user<>'UNIVERSITY_PROJECT' then raise_application_error(-20000,'Use UNIVERSITY_PROJECT.');end if;
 savepoint teacher_select_validation;
 table_names(1):='SPECIALTIES';row_order(1):='specialty_id';
 table_names(2):='ACADEMIC_TITLES';row_order(2):='title_id';
 table_names(3):='STUDY_YEARS';row_order(3):='study_year_no';
 table_names(4):='SEMESTERS';row_order(4):='semester_no';
 table_names(5):='GRADE_SCALE';row_order(5):='grade_value';
 table_names(6):='STUDENTS';row_order(6):='faculty_number';
 table_names(7):='TEACHERS';row_order(7):='teacher_id';
 table_names(8):='DISCIPLINES';row_order(8):='discipline_id';
 table_names(9):='CURRICULUM';row_order(9):='curriculum_id';
 table_names(10):='DISCIPLINE_TEACHERS';row_order(10):='curriculum_id,teacher_id,academic_year';
 table_names(11):='GRADES';row_order(11):='faculty_number,curriculum_id';
 for i in 1..11 loop before_rows(i):=dbms_xmlgen.getxml('select * from '||table_names(i)||' order by '||row_order(i));end loop;

 select count(*) into n from user_procedures where object_name='UNIVERSITY_API'
 and procedure_name in('FIND_TEACHERS_BY_TITLE','FIND_STUDENTS_BY_SPECIALTY');ok(n=2,'Both related-object keyword procedures are installed');
 select count(*) into n from user_tab_columns where table_name='V_STUDENT_AVERAGES' and column_name='STUDENT_EMAIL';ok(n=1,'Student reporting includes email');
 select count(*) into n from user_tab_columns where table_name='V_TEACHER_RANKING' and column_name in('TEACHER_PHONE','TEACHER_EMAIL');ok(n=2,'Teacher reporting includes both contact fields');
 select count(*) into n from user_tab_columns where table_name='V_ACADEMIC_REPORT' and column_name in('GRADING_TEACHER_TITLE','GRADING_TEACHER_PHONE','GRADING_TEACHER_EMAIL');ok(n=3,'Academic reporting identifies the actual grader with title and contacts');

 select min(teacher_id) into owner_teacher from teachers;
 select min(discipline_id) into course_a from disciplines;
 select min(discipline_id) into course_b from disciplines where discipline_id>course_a;
 select discipline_name into course_name from disciplines where discipline_id=course_a;
 select sy.year_label into year_label from study_years sy where study_year_no=1;
 insert into academic_titles(title_name) values('BOARD Title 100%_\') returning academic_titles.title_id into title_id;
 university_api.create_teacher_for_disciplines('BOARD',null,'Duplicate',title_id,'+359000008801',
  'board.teacher.a@university.example',sys.odcinumberlist(course_a,course_b),teacher_a,2025);
 university_api.create_teacher_for_disciplines('BOARD',null,'Duplicate',title_id,'+359000008802',
  'board.teacher.b@university.example',sys.odcinumberlist(course_a,course_b),teacher_b,2025);
 select count(*) into n from v_teacher_ranking where teacher_id in(teacher_a,teacher_b) and discipline_count=2;
 ok(n=2,'Teachers with the same name retain two independent aggregate rows');

 insert into specialties(specialty_name) values('BOARD specialty 100%_\') returning specialties.specialty_id into specialty_id;
 university_api.add_curriculum(specialty_id,course_a,1,owner_teacher,curr_a,2025);
 university_api.add_curriculum(specialty_id,course_b,2,owner_teacher,curr_b,2025);
 inputs(1).discipline_id:=course_a;inputs(1).grade_value:=4;inputs(1).grade_date:=date '2026-06-15';inputs(1).academic_year:=2025;
 inputs(2).discipline_id:=course_b;inputs(2).grade_value:=4;inputs(2).grade_date:=date '2026-06-15';inputs(2).academic_year:=2025;
 university_api.create_student('BOARD-ONE','BOARD',null,'Duplicate',specialty_id,1,'board.student.a@university.example',inputs);
 inputs(1).grade_value:=6;inputs(2).grade_value:=6;
 university_api.create_student('BOARD-TWO','BOARD',null,'Duplicate',specialty_id,1,'board.student.b@university.example',inputs);
 select count(*) into n from v_student_averages where (faculty_number='BOARD-ONE' and average_grade=4) or(faculty_number='BOARD-TWO' and average_grade=6);
 ok(n=2,'Students with the same name retain their separate averages');

 drain;university_api.find_teachers_by_title('BOARD Title');drain;
 ok(instr(output_text,'Teacher matches: 2')>0,'Title keyword filters the joined reference object');
 ok(instr(output_text,'+359000008801')>0 and instr(output_text,'board.teacher.a@university.example')>0 and instr(output_text,'disciplines: 2')>0,'Title cursor prints full teacher characteristics');
 university_api.find_teachers_by_title('board title');drain;ok(instr(output_text,'Teacher matches: 2')>0,'Title keyword search ignores letter case');
 university_api.find_teachers_by_title('%');drain;ok(instr(output_text,'Teacher matches: 2')>0,'Percent in teacher keyword is literal text');
 university_api.find_teachers_by_title('_');drain;ok(instr(output_text,'Teacher matches: 2')>0,'Underscore in teacher keyword is literal text');
 university_api.find_teachers_by_title('\');drain;ok(instr(output_text,'Teacher matches: 2')>0,'Backslash in teacher keyword is literal text');
 university_api.find_teachers_by_title('BOARD missing title');drain;ok(instr(output_text,'Teacher matches: 0')>0,'No teacher matches is a valid empty result');
 select count(*) into n from teachers;
 university_api.find_teachers_by_title(null);drain;ok(instr(output_text,'Teacher matches: '||n)>0,'Empty title keyword lists all teachers');
 rejected('begin university_api.find_teachers_by_title(rpad(''x'',1001,''x''));end;','Oversized teacher keyword rejected');
 rejected('begin university_api.find_students_by_specialty(rpad(''x'',1001,''x''));end;','Oversized specialty keyword rejected');
 university_api.find_students_by_specialty('board specialty');drain;
 ok(instr(output_text,'Student matches: 2')>0,'Specialty keyword filters the joined reference object');
 ok(instr(output_text,'BOARD-ONE')>0 and instr(output_text,'board.student.a@university.example')>0 and instr(output_text,year_label)>0,'Specialty cursor prints faculty number email specialty and study year');
 university_api.find_students_by_specialty('%');drain;ok(instr(output_text,'Student matches: 2')>0,'Percent in specialty keyword is literal text');
 university_api.find_students_by_specialty('_');drain;ok(instr(output_text,'Student matches: 2')>0,'Underscore in specialty keyword is literal text');
 university_api.find_students_by_specialty('\');drain;ok(instr(output_text,'Student matches: 2')>0,'Backslash in specialty keyword is literal text');
 find_student('BOARD Duplicate');drain;ok(instr(output_text,'Student matches: 2')>0 and instr(output_text,'board.student.b@university.example')>0,'Existing student cursor now includes contact data');
 find_discipline(course_name);drain;ok(instr(output_text,'BOARD specialty 100%_\')>0 and instr(output_text,'teacher1@university.example')>0 and instr(output_text,'2025/2026')>0,'Discipline cursor prints specialty semester teacher contacts and academic year');
 academic_report('BOARD-ONE');drain;ok(instr(output_text,'board.student.a@university.example')>0 and instr(output_text,'teacher1@university.example')>0 and instr(output_text,'2025/2026')>0,'Explicit cursor includes student and grader characteristics');
 university_api.print_academic_report('BOARD-ONE');drain;ok(instr(output_text,'board.student.a@university.example')>0 and instr(output_text,'teacher1@university.example')>0 and instr(output_text,'2025/2026')>0,'FOR cursor includes student and grader characteristics');
 university_api.assign_curriculum_teacher(curr_a,teacher_a,2026);
 select discipline_count into n from v_teacher_ranking where teacher_id=teacher_a;ok(n=2,'Another year of the same catalogue course does not inflate teacher count');
 select count(*) into n from v_academic_report where faculty_number in('BOARD-ONE','BOARD-TWO');ok(n=4,'Extra assignment year never duplicates academic grades');
 university_api.validate_rules;ok(not university_api.write_allowed,'Business rules pass and write guard is closed');
 rollback to teacher_select_validation;
 for i in 1..11 loop
  ok(dbms_lob.compare(before_rows(i),dbms_xmlgen.getxml('select * from '||table_names(i)||' order by '||row_order(i)))=0,table_names(i)||' all rows and fields restored');
 end loop;
 drain;print_report;
 dbms_output.put_line('TEACHER_SELECT_RULES_VALIDATION_PASSED: '||checks||' checks');
exception when others then rollback to teacher_select_validation;raise;
end;
/
