set define off
set serveroutput on size unlimited
set linesize 420
whenever sqlerror exit sql.sqlcode rollback
begin
 if user<>'UNIVERSITY_PROJECT' then raise_application_error(-20000,'Use UNIVERSITY_PROJECT.');end if;
end;
/
declare
 checks pls_integer:=0;
 lines dbms_output.chararr;nlines integer;output_text clob;row_count number;n number;
 log_text clob;new_id number;
 type t_snapshots is table of clob index by pls_integer;before_rows t_snapshots;
 procedure ok(b boolean,message varchar2) is
 begin
  if b is null or not b then raise_application_error(-20290,message);end if;
  checks:=checks+1;log_text:=log_text||'PASS: '||message||chr(10);
 end;
 procedure capture(p_call varchar2) is
 begin
  nlines:=10000;dbms_output.get_lines(lines,nlines);
  execute immediate 'begin '||p_call||';end;';
  nlines:=10000;dbms_output.get_lines(lines,nlines);output_text:=null;row_count:=0;
  for i in 1..nlines loop
   if substr(lines(i),1,4)='ROW|' then row_count:=row_count+1;end if;
   output_text:=output_text||lines(i)||chr(10);
  end loop;
 end;
 procedure rejects(p_call varchar2,wanted number,message varchar2) is actual number:=0;
 begin
  begin execute immediate 'begin '||p_call||';end;';exception when others then actual:=sqlcode;end;
  ok(actual=wanted,message);
 end;
begin
 savepoint table_cursor_validation;
 before_rows(1):=dbms_xmlgen.getxml('select * from SPECIALTIES order by specialty_id');
 before_rows(2):=dbms_xmlgen.getxml('select * from ACADEMIC_TITLES order by title_id');
 before_rows(3):=dbms_xmlgen.getxml('select * from STUDY_YEARS order by study_year_no');
 before_rows(4):=dbms_xmlgen.getxml('select * from SEMESTERS order by semester_no');
 before_rows(5):=dbms_xmlgen.getxml('select * from GRADE_SCALE order by grade_value');
 before_rows(6):=dbms_xmlgen.getxml('select * from STUDENTS order by faculty_number');
 before_rows(7):=dbms_xmlgen.getxml('select * from TEACHERS order by teacher_id');
 before_rows(8):=dbms_xmlgen.getxml('select * from DISCIPLINES order by discipline_id');
 before_rows(9):=dbms_xmlgen.getxml('select * from CURRICULUM order by curriculum_id');
 before_rows(10):=dbms_xmlgen.getxml('select * from DISCIPLINE_TEACHERS order by curriculum_id,teacher_id,academic_year');
 before_rows(11):=dbms_xmlgen.getxml('select * from GRADES order by faculty_number,curriculum_id');
 select count(*) into n from SPECIALTIES;
 capture('list_specialties');
 ok(row_count=n,'SPECIALTIES: one result per base row');
 ok(instr(output_text,'ROWS|SPECIALTIES|'||to_char(n,'TM9'))>0,'SPECIALTIES: correct empty/nonempty summary');
 capture('list_specialties(p_keyword=>''   '')');ok(row_count=n,'list_specialties: blank p_keyword lists all rows');
 rejects('list_specialties(p_keyword=>rpad(''x'',1001,''x''))',-20200,'list_specialties: oversized p_keyword rejected');
 select count(*) into n from ACADEMIC_TITLES;
 capture('list_academic_titles');
 ok(row_count=n,'ACADEMIC_TITLES: one result per base row');
 ok(instr(output_text,'ROWS|ACADEMIC_TITLES|'||to_char(n,'TM9'))>0,'ACADEMIC_TITLES: correct empty/nonempty summary');
 capture('list_academic_titles(p_keyword=>''   '')');ok(row_count=n,'list_academic_titles: blank p_keyword lists all rows');
 rejects('list_academic_titles(p_keyword=>rpad(''x'',1001,''x''))',-20200,'list_academic_titles: oversized p_keyword rejected');
 select count(*) into n from STUDY_YEARS;
 capture('list_study_years');
 ok(row_count=n,'STUDY_YEARS: one result per base row');
 ok(instr(output_text,'ROWS|STUDY_YEARS|'||to_char(n,'TM9'))>0,'STUDY_YEARS: correct empty/nonempty summary');
 capture('list_study_years(p_keyword=>''   '')');ok(row_count=n,'list_study_years: blank p_keyword lists all rows');
 rejects('list_study_years(p_keyword=>rpad(''x'',1001,''x''))',-20200,'list_study_years: oversized p_keyword rejected');
 select count(*) into n from SEMESTERS;
 capture('list_semesters');
 ok(row_count=n,'SEMESTERS: one result per base row');
 ok(instr(output_text,'ROWS|SEMESTERS|'||to_char(n,'TM9'))>0,'SEMESTERS: correct empty/nonempty summary');
 capture('list_semesters(p_year_keyword=>''   '')');ok(row_count=n,'list_semesters: blank p_year_keyword lists all rows');
 rejects('list_semesters(p_year_keyword=>rpad(''x'',1001,''x''))',-20200,'list_semesters: oversized p_year_keyword rejected');
 select count(*) into n from GRADE_SCALE;
 capture('list_grade_scale');
 ok(row_count=n,'GRADE_SCALE: one result per base row');
 ok(instr(output_text,'ROWS|GRADE_SCALE|'||to_char(n,'TM9'))>0,'GRADE_SCALE: correct empty/nonempty summary');
 select count(*) into n from STUDENTS;
 capture('list_students');
 ok(row_count=n,'STUDENTS: one result per base row');
 ok(instr(output_text,'ROWS|STUDENTS|'||to_char(n,'TM9'))>0,'STUDENTS: correct empty/nonempty summary');
 capture('list_students(p_keyword=>''   '')');ok(row_count=n,'list_students: blank p_keyword lists all rows');
 rejects('list_students(p_keyword=>rpad(''x'',1001,''x''))',-20200,'list_students: oversized p_keyword rejected');
 capture('list_students(p_specialty_keyword=>''   '')');ok(row_count=n,'list_students: blank p_specialty_keyword lists all rows');
 rejects('list_students(p_specialty_keyword=>rpad(''x'',1001,''x''))',-20200,'list_students: oversized p_specialty_keyword rejected');
 capture('list_students(p_year_keyword=>''   '')');ok(row_count=n,'list_students: blank p_year_keyword lists all rows');
 rejects('list_students(p_year_keyword=>rpad(''x'',1001,''x''))',-20200,'list_students: oversized p_year_keyword rejected');
 select count(*) into n from TEACHERS;
 capture('list_teachers');
 ok(row_count=n,'TEACHERS: one result per base row');
 ok(instr(output_text,'ROWS|TEACHERS|'||to_char(n,'TM9'))>0,'TEACHERS: correct empty/nonempty summary');
 capture('list_teachers(p_keyword=>''   '')');ok(row_count=n,'list_teachers: blank p_keyword lists all rows');
 rejects('list_teachers(p_keyword=>rpad(''x'',1001,''x''))',-20200,'list_teachers: oversized p_keyword rejected');
 capture('list_teachers(p_title_keyword=>''   '')');ok(row_count=n,'list_teachers: blank p_title_keyword lists all rows');
 rejects('list_teachers(p_title_keyword=>rpad(''x'',1001,''x''))',-20200,'list_teachers: oversized p_title_keyword rejected');
 select count(*) into n from DISCIPLINES;
 capture('list_disciplines');
 ok(row_count=n,'DISCIPLINES: one result per base row');
 ok(instr(output_text,'ROWS|DISCIPLINES|'||to_char(n,'TM9'))>0,'DISCIPLINES: correct empty/nonempty summary');
 capture('list_disciplines(p_keyword=>''   '')');ok(row_count=n,'list_disciplines: blank p_keyword lists all rows');
 rejects('list_disciplines(p_keyword=>rpad(''x'',1001,''x''))',-20200,'list_disciplines: oversized p_keyword rejected');
 select count(*) into n from CURRICULUM;
 capture('list_curriculum');
 ok(row_count=n,'CURRICULUM: one result per base row');
 ok(instr(output_text,'ROWS|CURRICULUM|'||to_char(n,'TM9'))>0,'CURRICULUM: correct empty/nonempty summary');
 capture('list_curriculum(p_discipline_keyword=>''   '')');ok(row_count=n,'list_curriculum: blank p_discipline_keyword lists all rows');
 rejects('list_curriculum(p_discipline_keyword=>rpad(''x'',1001,''x''))',-20200,'list_curriculum: oversized p_discipline_keyword rejected');
 capture('list_curriculum(p_specialty_keyword=>''   '')');ok(row_count=n,'list_curriculum: blank p_specialty_keyword lists all rows');
 rejects('list_curriculum(p_specialty_keyword=>rpad(''x'',1001,''x''))',-20200,'list_curriculum: oversized p_specialty_keyword rejected');
 select count(*) into n from DISCIPLINE_TEACHERS;
 capture('list_teaching_assignments');
 ok(row_count=n,'DISCIPLINE_TEACHERS: one result per base row');
 ok(instr(output_text,'ROWS|DISCIPLINE_TEACHERS|'||to_char(n,'TM9'))>0,'DISCIPLINE_TEACHERS: correct empty/nonempty summary');
 capture('list_teaching_assignments(p_discipline_keyword=>''   '')');ok(row_count=n,'list_teaching_assignments: blank p_discipline_keyword lists all rows');
 rejects('list_teaching_assignments(p_discipline_keyword=>rpad(''x'',1001,''x''))',-20200,'list_teaching_assignments: oversized p_discipline_keyword rejected');
 capture('list_teaching_assignments(p_teacher_keyword=>''   '')');ok(row_count=n,'list_teaching_assignments: blank p_teacher_keyword lists all rows');
 rejects('list_teaching_assignments(p_teacher_keyword=>rpad(''x'',1001,''x''))',-20200,'list_teaching_assignments: oversized p_teacher_keyword rejected');
 capture('list_teaching_assignments(p_specialty_keyword=>''   '')');ok(row_count=n,'list_teaching_assignments: blank p_specialty_keyword lists all rows');
 rejects('list_teaching_assignments(p_specialty_keyword=>rpad(''x'',1001,''x''))',-20200,'list_teaching_assignments: oversized p_specialty_keyword rejected');
 select count(*) into n from GRADES;
 capture('list_grades');
 ok(row_count=n,'GRADES: one result per base row');
 ok(instr(output_text,'ROWS|GRADES|'||to_char(n,'TM9'))>0,'GRADES: correct empty/nonempty summary');
 capture('list_grades(p_discipline_keyword=>''   '')');ok(row_count=n,'list_grades: blank p_discipline_keyword lists all rows');
 rejects('list_grades(p_discipline_keyword=>rpad(''x'',1001,''x''))',-20200,'list_grades: oversized p_discipline_keyword rejected');
 capture('list_grades(p_specialty_keyword=>''   '')');ok(row_count=n,'list_grades: blank p_specialty_keyword lists all rows');
 rejects('list_grades(p_specialty_keyword=>rpad(''x'',1001,''x''))',-20200,'list_grades: oversized p_specialty_keyword rejected');

 insert into specialties(specialty_name) values('LIST 100%_\') returning specialty_id into new_id;
 capture('list_specialties(''100%'')');ok(row_count=1,'Literal percent does not become a wildcard');
 capture('list_specialties(''_'')');ok(row_count=1,'Literal underscore does not become a wildcard');
 capture('list_specialties(''\'')');ok(row_count=1,'Literal backslash is escaped');
 capture('list_specialties(''list 100'')');ok(row_count=1,'Case-insensitive keyword search');
 capture('list_specialties(''LIST-MISSING-983144'')');ok(row_count=0 and instr(output_text,'ROWS|SPECIALTIES|0')>0,'Empty search reports zero rows');
 capture('list_specialties(chr(39)||'' or 1=1 --'')');ok(row_count=0,'Apostrophe input remains literal data');
 capture('list_students(p_specialty_keyword=>unistr(''\041a\043e\043c\043f''))');
 select count(*) into n from students s join specialties sp on sp.specialty_id=s.specialty_id where sp.specialty_name like unistr('%\041a\043e\043c\043f%');
 ok(row_count=n and n>0,'Student specialty filter uses the related name');
 capture('list_teachers(p_title_keyword=>unistr(''\043f\0440\043e\0444''))');
 select count(*) into n from teachers t join academic_titles a on a.title_id=t.title_id where a.title_name like unistr('%\043f\0440\043e\0444%');
 ok(row_count=n and n>0,'Teacher title filter uses the related name');
 capture('list_semesters(p_term_no=>1)');select count(*) into n from semesters where term_no=1;ok(row_count=n,'Semester term filter');
 capture('list_grade_scale(p_is_passing=>0)');ok(row_count=1 and instr(output_text,'grade_value=2')>0,'Failed grade-scale filter');
 capture('list_curriculum(p_semester_no=>6)');select count(*) into n from curriculum where semester_no=6;ok(row_count=n,'Curriculum semester filter');
 capture('list_teaching_assignments(p_academic_year=>2026)');select count(*) into n from discipline_teachers where academic_year=2026;ok(row_count=n,'Assignment year filter');
 capture('list_grades(p_faculty_number=>''00010001'',p_academic_year=>2025)');
 select count(*) into n from grades where faculty_number='00010001' and academic_year=2025;
 ok(row_count=n and n>0,'Grade faculty number and historical year filter');
 ok(instr(output_text,'teacher_email=teacher1@university.example')>0 and instr(output_text,'academic_year_label=2025/2026')>0,'Grade output identifies historical grader and year');
 capture('list_grades(p_faculty_number=>''00010001'',p_academic_year=>2026)');ok(row_count=0,'Different academic year does not leak historical grades');
 capture('list_grades(p_min_grade=>6)');select count(*) into n from grades where grade_value=6;ok(row_count=n,'Grade minimum filter');
 rejects('list_semesters(p_term_no=>3)',-20201,'Invalid term rejected');
 rejects('list_grade_scale(p_is_passing=>2)',-20201,'Invalid passing flag rejected');
 rejects('list_grades(p_academic_year=>2026.5)',-20201,'Fractional academic year rejected');
 rejects('list_grades(p_academic_year=>1899)',-20201,'Out-of-range academic year rejected');
 rejects('list_grades(p_min_grade=>7)',-20201,'Invalid minimum grade rejected');
 rejects('list_curriculum(p_semester_no=>1.5)',-20201,'Fractional semester rejected');
 rollback to table_cursor_validation;
 ok(dbms_lob.compare(before_rows(1),dbms_xmlgen.getxml('select * from SPECIALTIES order by specialty_id'))=0,'SPECIALTIES: all rows and fields preserved');
 ok(dbms_lob.compare(before_rows(2),dbms_xmlgen.getxml('select * from ACADEMIC_TITLES order by title_id'))=0,'ACADEMIC_TITLES: all rows and fields preserved');
 ok(dbms_lob.compare(before_rows(3),dbms_xmlgen.getxml('select * from STUDY_YEARS order by study_year_no'))=0,'STUDY_YEARS: all rows and fields preserved');
 ok(dbms_lob.compare(before_rows(4),dbms_xmlgen.getxml('select * from SEMESTERS order by semester_no'))=0,'SEMESTERS: all rows and fields preserved');
 ok(dbms_lob.compare(before_rows(5),dbms_xmlgen.getxml('select * from GRADE_SCALE order by grade_value'))=0,'GRADE_SCALE: all rows and fields preserved');
 ok(dbms_lob.compare(before_rows(6),dbms_xmlgen.getxml('select * from STUDENTS order by faculty_number'))=0,'STUDENTS: all rows and fields preserved');
 ok(dbms_lob.compare(before_rows(7),dbms_xmlgen.getxml('select * from TEACHERS order by teacher_id'))=0,'TEACHERS: all rows and fields preserved');
 ok(dbms_lob.compare(before_rows(8),dbms_xmlgen.getxml('select * from DISCIPLINES order by discipline_id'))=0,'DISCIPLINES: all rows and fields preserved');
 ok(dbms_lob.compare(before_rows(9),dbms_xmlgen.getxml('select * from CURRICULUM order by curriculum_id'))=0,'CURRICULUM: all rows and fields preserved');
 ok(dbms_lob.compare(before_rows(10),dbms_xmlgen.getxml('select * from DISCIPLINE_TEACHERS order by curriculum_id,teacher_id,academic_year'))=0,'DISCIPLINE_TEACHERS: all rows and fields preserved');
 ok(dbms_lob.compare(before_rows(11),dbms_xmlgen.getxml('select * from GRADES order by faculty_number,curriculum_id'))=0,'GRADES: all rows and fields preserved');

 select count(*) into n from specialties where specialty_id=new_id;ok(n=0,'Temporary literal-keyword fixture rolled back');
 select count(*) into n from user_objects where status<>'VALID';ok(n=0,'All database objects remain VALID');
 for i in 0..trunc((dbms_lob.getlength(log_text)-1)/8000) loop dbms_output.put_line(dbms_lob.substr(log_text,8000,1+i*8000));end loop;
 dbms_output.put_line('TABLE_CURSOR_VALIDATION_PASSED: '||checks||' checks');
exception when others then rollback to table_cursor_validation;raise;
end;
/
