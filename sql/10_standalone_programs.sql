set define off
set serveroutput on
whenever sqlerror exit sql.sqlcode rollback

begin
 if user <> 'UNIVERSITY_PROJECT' then raise_application_error(-20000,'Use UNIVERSITY_PROJECT.'); end if;
end;
/

-- Standalone INSERT/UPDATE procedures following the supplied %TYPE templates.
-- All writes keep the minimum-two rules by delegating to UNIVERSITY_API.
create or replace procedure student_ins(
 p_number students.faculty_number%type,
 p_first students.first_name%type, p_middle students.middle_name%type, p_last students.last_name%type,
 p_specialty students.specialty_id%type, p_year students.study_year_no%type, p_email students.email%type,
 p_discipline1 grades.discipline_id%type, p_grade1 grades.grade_value%type, p_date1 grades.grade_date%type,
 p_discipline2 grades.discipline_id%type, p_grade2 grades.grade_value%type, p_date2 grades.grade_date%type
) as
 l_grades university_api.t_grade_list;
begin
 l_grades(1).discipline_id:=p_discipline1; l_grades(1).grade_value:=p_grade1; l_grades(1).grade_date:=p_date1;
 l_grades(2).discipline_id:=p_discipline2; l_grades(2).grade_value:=p_grade2; l_grades(2).grade_date:=p_date2;
 university_api.create_student(p_number,p_first,p_middle,p_last,p_specialty,p_year,p_email,l_grades);
end;
/
create or replace procedure student_upd(
 p_number students.faculty_number%type,
 p_first students.first_name%type, p_middle students.middle_name%type, p_last students.last_name%type,
 p_specialty students.specialty_id%type, p_year students.study_year_no%type, p_email students.email%type
) as
begin
 university_api.update_student(p_number,p_first,p_middle,p_last,p_specialty,p_year,p_email);
end;
/
create or replace procedure teacher_ins(
 p_first teachers.first_name%type, p_middle teachers.middle_name%type, p_last teachers.last_name%type,
 p_title teachers.title_id%type, p_phone teachers.phone%type, p_email teachers.email%type,
 p_name1 disciplines.discipline_name%type, p_semester1 disciplines.semester_no%type,
 p_name2 disciplines.discipline_name%type, p_semester2 disciplines.semester_no%type,
 p_teacher_id out teachers.teacher_id%type,
 p_discipline1 out disciplines.discipline_id%type, p_discipline2 out disciplines.discipline_id%type
) as
 l_disciplines university_api.t_discipline_list;
 l_ids sys.odcinumberlist;
begin
 l_disciplines(1).discipline_name:=p_name1; l_disciplines(1).semester_no:=p_semester1;
 l_disciplines(2).discipline_name:=p_name2; l_disciplines(2).semester_no:=p_semester2;
 university_api.create_teacher(p_first,p_middle,p_last,p_title,p_phone,p_email,l_disciplines,p_teacher_id,l_ids);
 p_discipline1:=l_ids(1); p_discipline2:=l_ids(2);
end;
/
create or replace procedure teacher_upd(
 p_id teachers.teacher_id%type, p_first teachers.first_name%type,
 p_middle teachers.middle_name%type, p_last teachers.last_name%type,
 p_title teachers.title_id%type, p_phone teachers.phone%type, p_email teachers.email%type
) as
begin
 university_api.update_teacher(p_id,p_first,p_middle,p_last,p_title,p_phone,p_email);
end;
/
create or replace procedure discipline_ins(
 p_name disciplines.discipline_name%type, p_semester disciplines.semester_no%type,
 p_teacher teachers.teacher_id%type, p_id out disciplines.discipline_id%type
) as
begin
 university_api.add_discipline(p_name,p_semester,p_teacher,p_id);
end;
/
create or replace procedure discipline_upd(
 p_id disciplines.discipline_id%type, p_name disciplines.discipline_name%type,
 p_semester disciplines.semester_no%type
) as
begin
 university_api.update_discipline(p_id,p_name,p_semester);
end;
/
-- INSERT must reject an existing pair; UPDATE must reject a missing pair.
-- Acquire the same writer locks before checking existence to avoid races.
create or replace procedure grade_ins(
 p_number grades.faculty_number%type, p_discipline grades.discipline_id%type,
 p_grade grades.grade_value%type, p_date grades.grade_date%type
) as
 l_count number;
begin
 savepoint grade_procedure_change;
 lock table students, teachers, disciplines, discipline_teachers, grades in exclusive mode nowait;
 select count(*) into l_count from grades where faculty_number=p_number and discipline_id=p_discipline;
 if l_count<>0 then raise_application_error(-20061,'Grade already exists; use GRADE_UPD.'); end if;
 university_api.set_grade(p_number,p_discipline,p_grade,p_date);
exception when others then
 rollback to grade_procedure_change;
 raise;
end;
/
create or replace procedure grade_upd(
 p_number grades.faculty_number%type, p_discipline grades.discipline_id%type,
 p_grade grades.grade_value%type, p_date grades.grade_date%type
) as
 l_count number;
begin
 savepoint grade_procedure_change;
 lock table students, teachers, disciplines, discipline_teachers, grades in exclusive mode nowait;
 select count(*) into l_count from grades where faculty_number=p_number and discipline_id=p_discipline;
 if l_count=0 then raise_application_error(-20062,'Grade does not exist; use GRADE_INS.'); end if;
 university_api.set_grade(p_number,p_discipline,p_grade,p_date);
exception when others then
 rollback to grade_procedure_change;
 raise;
end;
/

-- Explicit cursor: OPEN / FETCH / %NOTFOUND / CLOSE, including error cleanup.
create or replace procedure academic_report(p_number students.faculty_number%type) as
 cursor cur_academic is
  select student_name,specialty_name,year_label,discipline_name,semester_no,grade_value,grade_date,average_grade
  from v_academic_report where faculty_number=p_number
  order by semester_no,discipline_name,discipline_id;
 l_row cur_academic%rowtype;
 l_count pls_integer:=0;
begin
 open cur_academic;
 loop
  fetch cur_academic into l_row;
  exit when cur_academic%notfound;
  if l_count=0 then
   dbms_output.put_line('Student: '||p_number||' '||l_row.student_name);
   dbms_output.put_line('Specialty: '||l_row.specialty_name||'; '||l_row.year_label);
   dbms_output.put_line('Average: '||to_char(l_row.average_grade,'FM0D00','NLS_NUMERIC_CHARACTERS=''.,'''));
  end if;
  dbms_output.put_line('Semester '||l_row.semester_no||': '||l_row.discipline_name||
   ' | grade '||l_row.grade_value||' | '||to_char(l_row.grade_date,'YYYY-MM-DD'));
  l_count:=l_count+1;
 end loop;
 close cur_academic;
 if l_count=0 then raise_application_error(-20043,'Student not found.'); end if;
exception when others then
 if cur_academic%isopen then close cur_academic; end if;
 raise;
end;
/
-- LIKE keyword search treats %, _ and backslash literally.
create or replace procedure find_student(p_keywords varchar2) as
 l_pattern varchar2(4000);
 cursor cur_students is
  select faculty_number,student_name,specialty_name,year_label,average_grade
  from v_student_averages
  where upper(student_name) like l_pattern escape '\'
  order by student_name,faculty_number;
 l_count pls_integer:=0;
begin
 if length(p_keywords)>1000 then raise_application_error(-20063,'Keyword is too long.'); end if;
 l_pattern:='%'||replace(replace(replace(upper(trim(p_keywords)),'\','\\'),'%','\%'),'_','\_')||'%';
 for r in cur_students loop
  dbms_output.put_line(r.faculty_number||' | '||r.student_name||' | '||r.specialty_name||
   ' | '||r.year_label||' | '||to_char(r.average_grade,'FM0D00','NLS_NUMERIC_CHARACTERS=''.,'''));
  l_count:=l_count+1;
 end loop;
 dbms_output.put_line('Student matches: '||l_count);
end;
/
create or replace procedure find_discipline(p_keywords varchar2) as
 l_pattern varchar2(4000);
 cursor cur_disciplines is
  select d.discipline_id,d.discipline_name,d.semester_no,
         dbms_lob.substr(t.teacher_name,3000,1) teacher_name
  from disciplines d join v_discipline_teachers t on t.discipline_id=d.discipline_id
  where upper(d.discipline_name) like l_pattern escape '\'
  order by d.semester_no,d.discipline_name,d.discipline_id;
 l_count pls_integer:=0;
begin
 if length(p_keywords)>1000 then raise_application_error(-20063,'Keyword is too long.'); end if;
 l_pattern:='%'||replace(replace(replace(upper(trim(p_keywords)),'\','\\'),'%','\%'),'_','\_')||'%';
 for r in cur_disciplines loop
  dbms_output.put_line(r.discipline_id||' | '||r.discipline_name||' | semester '||
   r.semester_no||' | '||r.teacher_name);
  l_count:=l_count+1;
 end loop;
 dbms_output.put_line('Discipline matches: '||l_count);
end;
/
create or replace procedure teacher_disciplines(p_teacher teachers.teacher_id%type) as
 cursor cur_disciplines is
  select d.discipline_id,d.discipline_name,d.semester_no
  from disciplines d join discipline_teachers dt on dt.discipline_id=d.discipline_id
  where dt.teacher_id=p_teacher order by d.semester_no,d.discipline_name,d.discipline_id;
 l_exists number;
begin
 select count(*) into l_exists from teachers where teacher_id=p_teacher;
 if l_exists=0 then raise_application_error(-20045,'Teacher not found.'); end if;
 for r in cur_disciplines loop
  dbms_output.put_line(r.discipline_id||' | '||r.discipline_name||' | semester '||r.semester_no);
 end loop;
end;
/

create or replace procedure discipline_teacher_ins(
 p_discipline discipline_teachers.discipline_id%type,
 p_teacher discipline_teachers.teacher_id%type
) as
begin university_api.assign_teacher(p_discipline,p_teacher); end;
/
create or replace procedure discipline_teacher_del(
 p_discipline discipline_teachers.discipline_id%type,
 p_teacher discipline_teachers.teacher_id%type
) as
begin university_api.unassign_teacher(p_discipline,p_teacher); end;
/

-- AFTER INSERT feedback, generated only after the row has been inserted.
-- The transaction is still pending; a later ROLLBACK can undo the row.
create or replace trigger grades_after_insert
after insert on grades
for each row
begin
 dbms_output.put_line('AFTER INSERT: student='||:new.faculty_number||
  ', discipline='||:new.discipline_id||', grade='||:new.grade_value||' (transaction pending)');
end;
/

declare l_errors number; l_invalid number;
begin
 select count(*) into l_errors from user_errors;
 select count(*) into l_invalid from user_objects where status<>'VALID';
 if l_errors<>0 or l_invalid<>0 then raise_application_error(-20050,'Standalone program compilation failed.'); end if;
 dbms_output.put_line('LESSON_PROGRAMS_COMPILED_OK: 14 standalone procedures, 1 AFTER INSERT trigger');
end;
/
