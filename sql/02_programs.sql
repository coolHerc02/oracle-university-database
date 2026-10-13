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
