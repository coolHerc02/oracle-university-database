-- Data-preserving 1:N to M:N migration for an existing UNIVERSITY_PROJECT.
-- Run once, after saving a complete backup; Oracle DDL commits implicitly.
-- Applications must be idle during this schema migration.
set define off
set serveroutput on
whenever sqlerror exit sql.sqlcode rollback
variable before_students number
variable before_teachers number
variable before_disciplines number
variable before_grades number
declare n number;
begin
 if user<>'UNIVERSITY_PROJECT' then raise_application_error(-20000,'Use UNIVERSITY_PROJECT.'); end if;
 select count(*) into n from user_tables where table_name='DISCIPLINE_TEACHERS';
 if n<>0 then raise_application_error(-20080,'M:N table already exists. Migration not repeated.'); end if;
 select count(*) into n from user_tab_columns where table_name='DISCIPLINES' and column_name='TEACHER_ID';
 if n<>1 then raise_application_error(-20081,'Expected the previous single-teacher schema.'); end if;
 select count(*) into :before_students from students;
 select count(*) into :before_teachers from teachers;
 select count(*) into :before_disciplines from disciplines;
 select count(*) into :before_grades from grades;
end;
/
create table discipline_teachers (
    discipline_id number not null,
    teacher_id number not null,
    constraint discipline_teachers_pk primary key (discipline_id, teacher_id),
    constraint dt_discipline_fk foreign key (discipline_id) references disciplines (discipline_id),
    constraint dt_teacher_fk foreign key (teacher_id) references teachers (teacher_id)
);
create index dt_teacher_ix on discipline_teachers(teacher_id);
insert into discipline_teachers(discipline_id,teacher_id)
select discipline_id,teacher_id from disciplines;
declare n number;
begin
 select count(*) into n from disciplines d
 where not exists(select 1 from discipline_teachers dt
                  where dt.discipline_id=d.discipline_id and dt.teacher_id=d.teacher_id);
 if n<>0 then raise_application_error(-20082,'Not all original assignments were copied.'); end if;
 dbms_output.put_line('ALL_ORIGINAL_TEACHING_ASSIGNMENTS_COPIED');
end;
/
alter table disciplines drop constraint disciplines_teacher_fk;
drop index disciplines_teacher_ix;
alter table disciplines drop column teacher_id;
comment on table disciplines is 'Each discipline belongs to one semester and has one or more teachers through DISCIPLINE_TEACHERS.';
comment on table discipline_teachers is 'Many-to-many teaching assignments. Composite PK prevents duplicate pairs. Each discipline has at least one teacher; each teacher leads at least two distinct disciplines.';

-- Recreate dependent views, package, guards and procedures.
set define off
set serveroutput on
whenever sqlerror exit sql.sqlcode rollback

begin
    if user <> 'UNIVERSITY_PROJECT' then
        raise_application_error(-20000, 'Use UNIVERSITY_PROJECT.');
    end if;
end;
/

create or replace view v_student_averages as
select s.faculty_number,
       s.first_name || ' ' ||
       case when s.middle_name is not null then s.middle_name || ' ' end || s.last_name student_name,
       s.specialty_id, sp.specialty_name,
       s.study_year_no, sy.year_label,
       count(g.discipline_id) discipline_count,
       avg(g.grade_value) average_grade
from students s
join specialties sp on sp.specialty_id = s.specialty_id
join study_years sy on sy.study_year_no = s.study_year_no
join grades g on g.faculty_number = s.faculty_number
group by s.faculty_number, s.first_name, s.middle_name, s.last_name,
         s.specialty_id, sp.specialty_name, s.study_year_no, sy.year_label;

-- CLOB aggregation keeps one academic row per grade, even with many teachers.
create or replace view v_discipline_teachers as
select dt.discipline_id, count(*) teacher_count,
       rtrim(xmlcast(xmlagg(xmlelement(e,
         t.first_name || ' ' ||
         case when t.middle_name is not null then t.middle_name || ' ' end ||
         t.last_name || '; ') order by t.teacher_id) as clob), '; ') teacher_name,
       rtrim(xmlcast(xmlagg(xmlelement(e, at.title_name || '; ')
         order by t.teacher_id) as clob), '; ') academic_title,
       rtrim(xmlcast(xmlagg(xmlelement(e, t.phone || '; ')
         order by t.teacher_id) as clob), '; ') teacher_phone,
       rtrim(xmlcast(xmlagg(xmlelement(e, t.email || '; ')
         order by t.teacher_id) as clob), '; ') teacher_email
from discipline_teachers dt
join teachers t on t.teacher_id = dt.teacher_id
join academic_titles at on at.title_id = t.title_id
group by dt.discipline_id;

create or replace view v_academic_report as
select s.faculty_number,
       s.first_name || ' ' ||
       case when s.middle_name is not null then s.middle_name || ' ' end || s.last_name student_name,
       s.email student_email,
       s.specialty_id, sp.specialty_name, s.study_year_no, sy.year_label,
       d.discipline_id, d.discipline_name, d.semester_no,
       dt.teacher_count, dt.teacher_name, dt.academic_title, dt.teacher_phone, dt.teacher_email,
       g.grade_value, gs.grade_label, g.grade_date, gs.is_passing,
       a.average_grade
from students s
join specialties sp on sp.specialty_id = s.specialty_id
join study_years sy on sy.study_year_no = s.study_year_no
join grades g on g.faculty_number = s.faculty_number
join grade_scale gs on gs.grade_value = g.grade_value
join disciplines d on d.discipline_id = g.discipline_id
join v_discipline_teachers dt on dt.discipline_id = d.discipline_id
join v_student_averages a on a.faculty_number = s.faculty_number;

create or replace view v_failed_exams as
select faculty_number, student_name, specialty_id, specialty_name,
       study_year_no, discipline_id, discipline_name, grade_value, grade_date
from v_academic_report where is_passing = 0;

create or replace view v_specialty_ranking as
select a.*,
       dense_rank() over (partition by specialty_id order by average_grade desc) rank_position
from v_student_averages a;

create or replace view v_teacher_ranking as
select teacher_id, teacher_name, title_name, discipline_count,
       dense_rank() over (order by discipline_count desc) rank_position
from (
    select t.teacher_id,
           t.first_name || ' ' ||
           case when t.middle_name is not null then t.middle_name || ' ' end || t.last_name teacher_name,
           at.title_name, count(d.discipline_id) discipline_count
    from teachers t
    join academic_titles at on at.title_id = t.title_id
    left join discipline_teachers d on d.teacher_id = t.teacher_id
    group by t.teacher_id, t.first_name, t.middle_name, t.last_name, at.title_name
);

create or replace package university_api as
    type t_discipline_input is record (
        discipline_name disciplines.discipline_name%type,
        semester_no disciplines.semester_no%type
    );
    type t_discipline_list is table of t_discipline_input index by pls_integer;
    type t_grade_input is record (
        discipline_id disciplines.discipline_id%type,
        grade_value grades.grade_value%type,
        grade_date grades.grade_date%type
    );
    type t_grade_list is table of t_grade_input index by pls_integer;

    function write_allowed return boolean;
    procedure validate_rules;

    procedure create_teacher(
        p_first_name varchar2, p_middle_name varchar2, p_last_name varchar2,
        p_title_id number, p_phone varchar2, p_email varchar2,
        p_disciplines t_discipline_list,
        p_teacher_id out number, p_discipline_ids out sys.odcinumberlist
    );
    procedure create_student(
        p_faculty_number varchar2,
        p_first_name varchar2, p_middle_name varchar2, p_last_name varchar2,
        p_specialty_id number, p_study_year_no number, p_email varchar2,
        p_grades t_grade_list
    );
    procedure update_student(
        p_faculty_number varchar2,
        p_first_name varchar2, p_middle_name varchar2, p_last_name varchar2,
        p_specialty_id number, p_study_year_no number, p_email varchar2
    );
    procedure rename_student_number(p_old_number varchar2, p_new_number varchar2);
    procedure update_teacher(
        p_teacher_id number,
        p_first_name varchar2, p_middle_name varchar2, p_last_name varchar2,
        p_title_id number, p_phone varchar2, p_email varchar2
    );
    procedure add_discipline(
        p_name varchar2, p_semester_no number, p_teacher_id number,
        p_discipline_id out number
    );
    procedure update_discipline(
        p_discipline_id number, p_name varchar2,
        p_semester_no number
    );
    procedure assign_teacher(p_discipline_id number, p_teacher_id number);
    procedure unassign_teacher(p_discipline_id number, p_teacher_id number);
    procedure replace_teacher(p_discipline_id number, p_old_teacher_id number, p_new_teacher_id number);
    procedure create_teacher_for_disciplines(
        p_first_name varchar2, p_middle_name varchar2, p_last_name varchar2,
        p_title_id number, p_phone varchar2, p_email varchar2,
        p_discipline_ids sys.odcinumberlist, p_teacher_id out number
    );
    procedure set_grade(
        p_faculty_number varchar2, p_discipline_id number,
        p_grade_value number, p_grade_date date
    );
    procedure get_academic_report(p_faculty_number varchar2, p_result out sys_refcursor);
    procedure print_academic_report(p_faculty_number varchar2);
    procedure delete_student(p_faculty_number varchar2);
    procedure delete_teacher(p_teacher_id number);
    procedure delete_discipline(p_discipline_id number);
    procedure delete_grade(p_faculty_number varchar2, p_discipline_id number);
end university_api;
/

create or replace package body university_api as
    g_write_allowed boolean := false;

    function write_allowed return boolean is
    begin
        return g_write_allowed;
    end;

    procedure validate_rules is
        l_teacher_id number;
        l_faculty_number varchar2(20);
        l_discipline_id number;
    begin
        select min(t.teacher_id) into l_teacher_id
        from teachers t
        where (select count(*) from discipline_teachers d where d.teacher_id = t.teacher_id) < 2;
        if l_teacher_id is not null then
            raise_application_error(-20041, 'Teacher ' || l_teacher_id || ' requires at least two disciplines.');
        end if;
        select min(d.discipline_id) into l_discipline_id
        from disciplines d
        where not exists (select 1 from discipline_teachers dt where dt.discipline_id=d.discipline_id);
        if l_discipline_id is not null then
            raise_application_error(-20047, 'Discipline ' || l_discipline_id || ' requires at least one teacher.');
        end if;
        select min(s.faculty_number) into l_faculty_number
        from students s
        where (select count(*) from grades g where g.faculty_number = s.faculty_number) < 2;
        if l_faculty_number is not null then
            raise_application_error(-20042, 'Student ' || l_faculty_number || ' requires at least two disciplines.');
        end if;
    end;

    procedure begin_change is
    begin
        if g_write_allowed then
            raise_application_error(-20021, 'Nested write operations are not supported.');
        end if;
        savepoint university_api_change;
        -- Serializes writers so concurrent changes cannot defeat minimum counts.
        lock table students, teachers, disciplines, discipline_teachers, grades in exclusive mode nowait;
        g_write_allowed := true;
    end;

    procedure finish_change is
    begin
        validate_rules;
        g_write_allowed := false;
    end;

    procedure cancel_change is
    begin
        g_write_allowed := false;
        rollback to university_api_change;
    end;

    procedure create_teacher(
        p_first_name varchar2, p_middle_name varchar2, p_last_name varchar2,
        p_title_id number, p_phone varchar2, p_email varchar2,
        p_disciplines t_discipline_list,
        p_teacher_id out number, p_discipline_ids out sys.odcinumberlist
    ) is
    begin
        begin_change;
        if p_disciplines.count < 2 or p_disciplines.first <> 1
           or p_disciplines.last <> p_disciplines.count then
            raise_application_error(-20030, 'Supply at least two disciplines with consecutive indices.');
        end if;
        p_teacher_id := teachers_seq.nextval;
        insert into teachers(teacher_id, first_name, middle_name, last_name, title_id, phone, email)
        values(p_teacher_id, p_first_name, p_middle_name, p_last_name, p_title_id, p_phone, p_email);
        p_discipline_ids := sys.odcinumberlist();
        for i in 1 .. p_disciplines.count loop
            p_discipline_ids.extend;
            p_discipline_ids(i) := disciplines_seq.nextval;
            insert into disciplines(discipline_id, discipline_name, semester_no)
            values(p_discipline_ids(i), p_disciplines(i).discipline_name, p_disciplines(i).semester_no);
            insert into discipline_teachers(discipline_id,teacher_id)
            values(p_discipline_ids(i),p_teacher_id);
        end loop;
        finish_change;
    exception when others then
        cancel_change;
        raise;
    end;

    procedure create_student(
        p_faculty_number varchar2,
        p_first_name varchar2, p_middle_name varchar2, p_last_name varchar2,
        p_specialty_id number, p_study_year_no number, p_email varchar2,
        p_grades t_grade_list
    ) is
    begin
        begin_change;
        if p_grades.count < 2 or p_grades.first <> 1 or p_grades.last <> p_grades.count then
            raise_application_error(-20031, 'Supply grades in at least two disciplines with consecutive indices.');
        end if;
        insert into students(faculty_number, first_name, middle_name, last_name,
                             specialty_id, study_year_no, email)
        values(p_faculty_number, p_first_name, p_middle_name, p_last_name,
               p_specialty_id, p_study_year_no, p_email);
        for i in 1 .. p_grades.count loop
            insert into grades(faculty_number, discipline_id, grade_value, grade_date)
            values(p_faculty_number, p_grades(i).discipline_id,
                   p_grades(i).grade_value, trunc(p_grades(i).grade_date));
        end loop;
        finish_change;
    exception when others then
        cancel_change;
        raise;
    end;

    procedure update_student(
        p_faculty_number varchar2,
        p_first_name varchar2, p_middle_name varchar2, p_last_name varchar2,
        p_specialty_id number, p_study_year_no number, p_email varchar2
    ) is
    begin
        begin_change;
        update students set first_name = p_first_name, middle_name = p_middle_name,
               last_name = p_last_name, specialty_id = p_specialty_id,
               study_year_no = p_study_year_no, email = p_email
        where faculty_number = p_faculty_number;
        if sql%rowcount <> 1 then raise_application_error(-20043, 'Student not found.'); end if;
        finish_change;
    exception when others then
        cancel_change;
        raise;
    end;

    procedure rename_student_number(p_old_number varchar2, p_new_number varchar2) is
    begin
        begin_change;
        if p_old_number = p_new_number then
            raise_application_error(-20044, 'Use a different faculty number.');
        end if;
        insert into students(faculty_number, first_name, middle_name, last_name,
                             specialty_id, study_year_no, email)
        select p_new_number, first_name, middle_name, last_name,
               specialty_id, study_year_no, email
        from students where faculty_number = p_old_number;
        if sql%rowcount <> 1 then raise_application_error(-20043, 'Student not found.'); end if;
        insert into grades(faculty_number, discipline_id, grade_value, grade_date)
        select p_new_number, discipline_id, grade_value, grade_date
        from grades where faculty_number = p_old_number;
        delete from grades where faculty_number = p_old_number;
        delete from students where faculty_number = p_old_number;
        finish_change;
    exception when others then
        cancel_change;
        raise;
    end;

    procedure update_teacher(
        p_teacher_id number,
        p_first_name varchar2, p_middle_name varchar2, p_last_name varchar2,
        p_title_id number, p_phone varchar2, p_email varchar2
    ) is
    begin
        begin_change;
        update teachers set first_name = p_first_name, middle_name = p_middle_name,
               last_name = p_last_name, title_id = p_title_id, phone = p_phone, email = p_email
        where teacher_id = p_teacher_id;
        if sql%rowcount <> 1 then raise_application_error(-20045, 'Teacher not found.'); end if;
        finish_change;
    exception when others then
        cancel_change;
        raise;
    end;

    procedure add_discipline(
        p_name varchar2, p_semester_no number, p_teacher_id number,
        p_discipline_id out number
    ) is
    begin
        begin_change;
        p_discipline_id := disciplines_seq.nextval;
        insert into disciplines(discipline_id, discipline_name, semester_no)
        values(p_discipline_id, p_name, p_semester_no);
        insert into discipline_teachers(discipline_id,teacher_id) values(p_discipline_id,p_teacher_id);
        finish_change;
    exception when others then
        cancel_change;
        raise;
    end;

    procedure update_discipline(
        p_discipline_id number, p_name varchar2,
        p_semester_no number
    ) is
    begin
        begin_change;
        update disciplines set discipline_name = p_name,
               semester_no = p_semester_no
        where discipline_id = p_discipline_id;
        if sql%rowcount <> 1 then raise_application_error(-20046, 'Discipline not found.'); end if;
        finish_change;
    exception when others then
        cancel_change;
        raise;
    end;

    procedure assign_teacher(p_discipline_id number, p_teacher_id number) is
    begin
        begin_change;
        insert into discipline_teachers(discipline_id,teacher_id) values(p_discipline_id,p_teacher_id);
        finish_change;
    exception when others then cancel_change; raise;
    end;

    procedure unassign_teacher(p_discipline_id number, p_teacher_id number) is
    begin
        begin_change;
        delete from discipline_teachers where discipline_id=p_discipline_id and teacher_id=p_teacher_id;
        if sql%rowcount<>1 then raise_application_error(-20072,'Teaching assignment not found.'); end if;
        finish_change;
    exception when others then cancel_change; raise;
    end;

    procedure replace_teacher(p_discipline_id number, p_old_teacher_id number, p_new_teacher_id number) is
    begin
        begin_change;
        update discipline_teachers set teacher_id=p_new_teacher_id
        where discipline_id=p_discipline_id and teacher_id=p_old_teacher_id;
        if sql%rowcount<>1 then raise_application_error(-20072,'Teaching assignment not found.'); end if;
        finish_change;
    exception when others then cancel_change; raise;
    end;

    procedure create_teacher_for_disciplines(
        p_first_name varchar2, p_middle_name varchar2, p_last_name varchar2,
        p_title_id number, p_phone varchar2, p_email varchar2,
        p_discipline_ids sys.odcinumberlist, p_teacher_id out number
    ) is
        l_count pls_integer;
    begin
        begin_change;
        begin l_count:=p_discipline_ids.count;
        exception when collection_is_null then l_count:=0; end;
        if l_count<2 then raise_application_error(-20030,'Supply at least two distinct existing disciplines.'); end if;
        p_teacher_id:=teachers_seq.nextval;
        insert into teachers(teacher_id,first_name,middle_name,last_name,title_id,phone,email)
        values(p_teacher_id,p_first_name,p_middle_name,p_last_name,p_title_id,p_phone,p_email);
        for i in 1..l_count loop
            insert into discipline_teachers(discipline_id,teacher_id) values(p_discipline_ids(i),p_teacher_id);
        end loop;
        finish_change;
    exception when others then cancel_change; raise;
    end;

    procedure set_grade(
        p_faculty_number varchar2, p_discipline_id number,
        p_grade_value number, p_grade_date date
    ) is
    begin
        begin_change;
        merge into grades g
        using (select p_faculty_number faculty_number, p_discipline_id discipline_id from dual) source
        on (g.faculty_number = source.faculty_number and g.discipline_id = source.discipline_id)
        when matched then update set g.grade_value = p_grade_value, g.grade_date = trunc(p_grade_date)
        when not matched then
            insert(faculty_number, discipline_id, grade_value, grade_date)
            values(p_faculty_number, p_discipline_id, p_grade_value, trunc(p_grade_date));
        finish_change;
    exception when others then
        cancel_change;
        raise;
    end;

    -- Deletes are atomic and validate the same minimum counts as inserts/updates.
    -- Only the explicitly selected student's grades are removed with the student.
    procedure delete_student(p_faculty_number varchar2) is
    begin
        begin_change;
        delete from grades where faculty_number=p_faculty_number;
        delete from students where faculty_number=p_faculty_number;
        if sql%rowcount<>1 then raise_application_error(-20043,'Student not found.'); end if;
        finish_change;
    exception when others then cancel_change; raise;
    end;

    -- A teacher can be removed only if every remaining discipline has a teacher.
    procedure delete_teacher(p_teacher_id number) is
    begin
        begin_change;
        delete from discipline_teachers where teacher_id=p_teacher_id;
        delete from teachers where teacher_id=p_teacher_id;
        if sql%rowcount<>1 then raise_application_error(-20045,'Teacher not found.'); end if;
        finish_change;
    exception when others then cancel_change; raise;
    end;

    -- Grades and teaching assignments of this discipline are removed together.
    -- Reject the operation if any remaining student/teacher would have <2 courses.
    procedure delete_discipline(p_discipline_id number) is
    begin
        begin_change;
        delete from grades where discipline_id=p_discipline_id;
        delete from discipline_teachers where discipline_id=p_discipline_id;
        delete from disciplines where discipline_id=p_discipline_id;
        if sql%rowcount<>1 then raise_application_error(-20046,'Discipline not found.'); end if;
        finish_change;
    exception when others then cancel_change; raise;
    end;

    procedure delete_grade(p_faculty_number varchar2, p_discipline_id number) is
    begin
        begin_change;
        delete from grades where faculty_number=p_faculty_number and discipline_id=p_discipline_id;
        if sql%rowcount<>1 then raise_application_error(-20062,'Grade not found.'); end if;
        finish_change;
    exception when others then cancel_change; raise;
    end;

    procedure get_academic_report(p_faculty_number varchar2, p_result out sys_refcursor) is
    begin
        open p_result for
        select * from v_academic_report where faculty_number = p_faculty_number
        order by semester_no, discipline_name, discipline_id;
    end;

    procedure print_academic_report(p_faculty_number varchar2) is
        cursor c_report is
            select student_name, specialty_name, year_label, discipline_name,
                   semester_no, grade_value, grade_date, average_grade
            from v_academic_report where faculty_number = p_faculty_number
            order by semester_no, discipline_name, discipline_id;
        l_count number := 0;
    begin
        for r in c_report loop
            if l_count = 0 then
                dbms_output.put_line('Student: ' || p_faculty_number || ' ' || r.student_name);
                dbms_output.put_line('Specialty: ' || r.specialty_name || ', ' || r.year_label);
                dbms_output.put_line('Average: ' || to_char(round(r.average_grade, 2)));
            end if;
            dbms_output.put_line('Semester ' || r.semester_no || ': ' || r.discipline_name ||
                                 ' | grade ' || r.grade_value || ' | ' || to_char(r.grade_date, 'YYYY-MM-DD'));
            l_count := l_count + 1;
        end loop;
        if l_count = 0 then raise_application_error(-20043, 'Student not found.'); end if;
    end;
end university_api;
/

create or replace trigger students_write_guard
before insert or update or delete on students
begin
    if not university_api.write_allowed then
        raise_application_error(-20020, 'Use UNIVERSITY_API to maintain the project rules.');
    end if;
end;
/
create or replace trigger teachers_write_guard
before insert or update or delete on teachers
begin
    if not university_api.write_allowed then
        raise_application_error(-20020, 'Use UNIVERSITY_API to maintain the project rules.');
    end if;
end;
/
create or replace trigger disciplines_write_guard
before insert or update or delete on disciplines
begin
    if not university_api.write_allowed then
        raise_application_error(-20020, 'Use UNIVERSITY_API to maintain the project rules.');
    end if;
end;
/
create or replace trigger dt_write_guard
before insert or update or delete on discipline_teachers
begin
    if not university_api.write_allowed then
        raise_application_error(-20020, 'Use UNIVERSITY_API to maintain teaching assignments.');
    end if;
end;
/

create or replace trigger grades_write_guard
before insert or update or delete on grades
begin
    if not university_api.write_allowed then
        raise_application_error(-20020, 'Use UNIVERSITY_API to maintain the project rules.');
    end if;
end;
/

declare
    l_errors number;
    l_invalid number;
begin
    select count(*) into l_errors from user_errors where type <> 'PROCEDURE';
    select count(*) into l_invalid from user_objects where status <> 'VALID' and object_type <> 'PROCEDURE';
    if l_errors <> 0 or l_invalid <> 0 then
        raise_application_error(-20050, 'Compilation errors or invalid objects exist.');
    end if;
    dbms_output.put_line('PROGRAMS_COMPILED_OK');
end;
/

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

-- Add two shared teaching examples to the supplied seed data, when present.
declare d number; t number; n number;
begin
 select min(discipline_id) into d from disciplines where discipline_name=unistr('\041c\0430\0442\0435\043c\0430\0442\0438\043a\0430');
 select min(teacher_id) into t from teachers where email='teacher2@university.example';
 if d is not null and t is not null then
  select count(*) into n from discipline_teachers where discipline_id=d and teacher_id=t;
  if n=0 then university_api.assign_teacher(d,t); end if;
 end if;
 select min(discipline_id) into d from disciplines where discipline_name=unistr('\0411\0430\0437\0438 \043e\0442 \0434\0430\043d\043d\0438');
 select min(teacher_id) into t from teachers where email='teacher1@university.example';
 if d is not null and t is not null then
  select count(*) into n from discipline_teachers where discipline_id=d and teacher_id=t;
  if n=0 then university_api.assign_teacher(d,t); end if;
 end if;
 university_api.validate_rules;
 select count(*) into n from students;
 if n<>:before_students then raise_application_error(-20083,'Student rows changed unexpectedly.'); end if;
 select count(*) into n from teachers;
 if n<>:before_teachers then raise_application_error(-20083,'Teacher rows changed unexpectedly.'); end if;
 select count(*) into n from disciplines;
 if n<>:before_disciplines then raise_application_error(-20083,'Discipline rows changed unexpectedly.'); end if;
 select count(*) into n from grades;
 if n<>:before_grades then raise_application_error(-20083,'Grade rows changed unexpectedly.'); end if;
 dbms_output.put_line('MIGRATION_CORE_ROW_COUNTS_PRESERVED');
end;
/
commit;
prompt MANY_TEACHERS_MIGRATION_COMPLETED
