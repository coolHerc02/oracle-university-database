-- One-time migration from the 10-table grading schema. Maintenance window.
-- Oracle DDL commits implicitly. Back up before running. Migrations 15/21 are
-- frozen artifacts for older releases, and are not run against this schema.
set define off
set serveroutput on
whenever sqlerror exit sql.sqlcode rollback
declare n number;
begin
 if user<>'UNIVERSITY_PROJECT' then raise_application_error(-20000,'Use UNIVERSITY_PROJECT.');end if;
 select count(*) into n from user_tables where table_name='CURRICULUM';
 if n<>0 then raise_application_error(-20150,'Curriculum already exists; migration not repeated.');end if;
 select count(*) into n from user_tab_columns where table_name='GRADES' and column_name='TEACHER_ID' and nullable='N';
 if n<>1 then raise_application_error(-20150,'Expected the previous grading-teacher schema.');end if;
end;
/
create table curriculum (
    curriculum_id number not null,
    specialty_id number not null,
    discipline_id number not null,
    semester_no number not null,
    constraint curriculum_pk primary key (curriculum_id),
    constraint curriculum_course_uq unique (specialty_id, discipline_id),
    constraint curriculum_id_ck check (curriculum_id > 0 and curriculum_id = trunc(curriculum_id)),
    constraint curriculum_specialty_fk foreign key (specialty_id) references specialties(specialty_id),
    constraint curriculum_discipline_fk foreign key (discipline_id) references disciplines(discipline_id),
    constraint curriculum_semester_fk foreign key (semester_no) references semesters(semester_no)
);
create sequence curriculum_seq start with 1 increment by 1 nocache;
create or replace trigger curriculum_bi
before insert on curriculum for each row
begin
 if :new.curriculum_id is null then :new.curriculum_id:=curriculum_seq.nextval;end if;
end;
/
alter table discipline_teachers add(curriculum_id number);
alter table grades add(curriculum_id number);
alter table grades drop constraint grades_assignment_fk;
alter table discipline_teachers drop constraint discipline_teachers_pk;
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
select s.faculty_number,s.first_name||' '||case when s.middle_name is not null then s.middle_name||' ' end||s.last_name student_name,
 s.specialty_id,sp.specialty_name,s.study_year_no,sy.year_label,
 count(distinct c.discipline_id) discipline_count,avg(g.grade_value) average_grade
from students s join specialties sp on sp.specialty_id=s.specialty_id
join study_years sy on sy.study_year_no=s.study_year_no
join grades g on g.faculty_number=s.faculty_number join curriculum c on c.curriculum_id=g.curriculum_id
group by s.faculty_number,s.first_name,s.middle_name,s.last_name,s.specialty_id,sp.specialty_name,s.study_year_no,sy.year_label;

create or replace view v_discipline_teachers as
select dt.curriculum_id,c.discipline_id,c.specialty_id,count(*) teacher_count,
 rtrim(xmlcast(xmlagg(xmlelement(e,t.first_name||' '||case when t.middle_name is not null then t.middle_name||' ' end||t.last_name||'; ') order by t.teacher_id) as clob),'; ') teacher_name,
 rtrim(xmlcast(xmlagg(xmlelement(e,a.title_name||'; ') order by t.teacher_id) as clob),'; ') academic_title,
 rtrim(xmlcast(xmlagg(xmlelement(e,t.phone||'; ') order by t.teacher_id) as clob),'; ') teacher_phone,
 rtrim(xmlcast(xmlagg(xmlelement(e,t.email||'; ') order by t.teacher_id) as clob),'; ') teacher_email
from discipline_teachers dt join curriculum c on c.curriculum_id=dt.curriculum_id
join teachers t on t.teacher_id=dt.teacher_id join academic_titles a on a.title_id=t.title_id
group by dt.curriculum_id,c.discipline_id,c.specialty_id;

create or replace view v_academic_report as
select s.faculty_number,s.first_name||' '||case when s.middle_name is not null then s.middle_name||' ' end||s.last_name student_name,
 s.email student_email,s.specialty_id,sp.specialty_name,s.study_year_no,sy.year_label,
 c.curriculum_id,d.discipline_id,d.discipline_name,c.semester_no,
 dt.teacher_count,dt.teacher_name,dt.academic_title,dt.teacher_phone,dt.teacher_email,
 g.grade_value,gs.grade_label,g.grade_date,gs.is_passing,g.teacher_id grading_teacher_id,
 gt.first_name||' '||case when gt.middle_name is not null then gt.middle_name||' ' end||gt.last_name grading_teacher_name,a.average_grade
from students s join specialties sp on sp.specialty_id=s.specialty_id
join study_years sy on sy.study_year_no=s.study_year_no
join grades g on g.faculty_number=s.faculty_number join curriculum c on c.curriculum_id=g.curriculum_id
join disciplines d on d.discipline_id=c.discipline_id join grade_scale gs on gs.grade_value=g.grade_value
join teachers gt on gt.teacher_id=g.teacher_id join v_discipline_teachers dt on dt.curriculum_id=c.curriculum_id
join v_student_averages a on a.faculty_number=s.faculty_number;
create or replace view v_failed_exams as
select faculty_number,student_name,specialty_id,specialty_name,study_year_no,curriculum_id,discipline_id,discipline_name,semester_no,grade_value,grade_date
from v_academic_report where is_passing=0;
create or replace view v_specialty_ranking as
select a.*,dense_rank() over(partition by specialty_id order by average_grade desc) rank_position from v_student_averages a;
create or replace view v_teacher_ranking as
select teacher_id,teacher_name,title_name,discipline_count,dense_rank() over(order by discipline_count desc) rank_position from(
select t.teacher_id,t.first_name||' '||case when t.middle_name is not null then t.middle_name||' ' end||t.last_name teacher_name,
 a.title_name,count(distinct c.discipline_id) discipline_count
from teachers t join academic_titles a on a.title_id=t.title_id
left join discipline_teachers dt on dt.teacher_id=t.teacher_id left join curriculum c on c.curriculum_id=dt.curriculum_id
group by t.teacher_id,t.first_name,t.middle_name,t.last_name,a.title_name);

create or replace package university_api as
    type t_discipline_input is record (
        discipline_name disciplines.discipline_name%type,
        semester_no curriculum.semester_no%type,
        specialty_id curriculum.specialty_id%type
    );
    type t_discipline_list is table of t_discipline_input index by pls_integer;
    type t_grade_input is record (
        discipline_id disciplines.discipline_id%type,
        grade_value grades.grade_value%type,
        grade_date grades.grade_date%type,
        teacher_id grades.teacher_id%type
    );
    type t_grade_list is table of t_grade_input index by pls_integer;

    function write_allowed return boolean;
    procedure backfill_grade_teachers;
    procedure migrate_legacy_curriculum;
    function curriculum_for(p_number varchar2,p_discipline number) return number;
    procedure create_catalog_discipline(p_name varchar2,p_id out number);
    procedure add_curriculum(p_specialty number,p_discipline number,p_semester number,p_teacher number,p_id out number);
    procedure update_curriculum(p_id number,p_semester number);
    procedure delete_curriculum(p_id number);
    procedure assign_curriculum_teacher(p_id number,p_teacher number);
    procedure unassign_curriculum_teacher(p_id number,p_teacher number);
    procedure replace_curriculum_teacher(p_id number,p_old number,p_new number);
    procedure set_curriculum_grade(p_number varchar2,p_id number,p_grade number,p_date date,p_teacher number default null);
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
        p_semester_no number default null
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
        p_grade_value number, p_grade_date date, p_teacher_id number default null
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

    procedure validate_rules is n number;
    begin
      select count(*) into n from teachers t where (select count(distinct c.discipline_id) from discipline_teachers dt join curriculum c on c.curriculum_id=dt.curriculum_id where dt.teacher_id=t.teacher_id)<2;
      if n>0 then raise_application_error(-20041,'Every teacher needs TWO distinct catalogue disciplines.');end if;
      select count(*) into n from curriculum c where not exists(select 1 from discipline_teachers dt where dt.curriculum_id=c.curriculum_id);
      if n>0 then raise_application_error(-20047,'Every curriculum entry needs a teacher.');end if;
      select count(*) into n from students s where (select count(*) from grades g where g.faculty_number=s.faculty_number)<2;
      if n>0 then raise_application_error(-20042,'Every student needs TWO graded courses.');end if;
      select count(*) into n from grades g join students s on s.faculty_number=g.faculty_number join curriculum c on c.curriculum_id=g.curriculum_id where s.specialty_id<>c.specialty_id;
      if n>0 then raise_application_error(-20140,'Grade curriculum must match the student specialty.');end if;
    end;

    procedure begin_change is
    begin
        if g_write_allowed then
            raise_application_error(-20021, 'Nested write operations are not supported.');
        end if;
        savepoint university_api_change;
        -- Serializes writers so concurrent changes cannot defeat minimum counts.
        lock table students, teachers, disciplines, curriculum, discipline_teachers, grades in exclusive mode nowait;
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

    function resolve_grade_teacher(p_discipline_id number,p_teacher_id number) return number is
        l_teacher number; l_count number;
    begin
        if sys_context('USERENV','SESSION_USER')=sys_context('USERENV','CURRENT_USER') then
            -- Schema owner is the administrator. NULL keeps legacy demo calls
            -- compatible by selecting a documented sample-data assignment.
            l_teacher:=p_teacher_id;
            if l_teacher is null then
                select min(teacher_id) into l_teacher from discipline_teachers where curriculum_id=p_discipline_id;
            end if;
        else
            select min(teacher_id) into l_teacher from teachers
            where sys_context('USERENV','SESSION_USER')='UP_TEACHER_'||to_char(teacher_id,'TM9');
            if l_teacher is null then raise_application_error(-20100,'No teacher mapped to this authenticated Oracle login.'); end if;
            if p_teacher_id is not null and p_teacher_id<>l_teacher then
                raise_application_error(-20101,'Cannot impersonate another teacher.');
            end if;
        end if;
        select count(*) into l_count from discipline_teachers
        where curriculum_id=p_discipline_id and teacher_id=l_teacher;
        if l_count<>1 then
            if sys_context('USERENV','SESSION_USER')=sys_context('USERENV','CURRENT_USER') then
                -- Return an impossible non-null key so the actual composite FK
                -- raises ORA-02291; never simulate system errors with RAISE_APPLICATION_ERROR.
                return nvl(l_teacher,-1);
            end if;
            raise_application_error(-20102,'This teacher does not teach this discipline.');
        end if;
        return l_teacher;
    end;

    procedure backfill_grade_teachers is
    begin
      if sys_context('USERENV','SESSION_USER')<>sys_context('USERENV','CURRENT_USER') then raise_application_error(-20103,'Owner only.');end if;
      begin_change;
      update grades g set teacher_id=(select min(dt.teacher_id) from discipline_teachers dt where dt.curriculum_id=g.curriculum_id) where teacher_id is null;
      finish_change;
    exception when others then cancel_change;raise;
    end;

    function curriculum_for(p_number varchar2,p_discipline number) return number is r number;
    begin
      select c.curriculum_id into r from curriculum c join students s on s.specialty_id=c.specialty_id
      where s.faculty_number=p_number and c.discipline_id=p_discipline;
      return r;
    exception when no_data_found then raise_application_error(-20141,'No curriculum entry for this student specialty and discipline.');
    end;

    procedure create_catalog_discipline(p_name varchar2,p_id out number) is
    begin
      begin_change;p_id:=disciplines_seq.nextval;insert into disciplines(discipline_id,discipline_name) values(p_id,p_name);finish_change;
    exception when others then cancel_change;raise;
    end;
    procedure add_curriculum(p_specialty number,p_discipline number,p_semester number,p_teacher number,p_id out number) is
    begin
      begin_change;p_id:=curriculum_seq.nextval;
      insert into curriculum values(p_id,p_specialty,p_discipline,p_semester);
      insert into discipline_teachers(curriculum_id,teacher_id) values(p_id,p_teacher);finish_change;
    exception when others then cancel_change;raise;
    end;
    procedure update_curriculum(p_id number,p_semester number) is
    begin
      begin_change;update curriculum set semester_no=p_semester where curriculum_id=p_id;
      if sql%rowcount<>1 then raise_application_error(-20142,'Curriculum entry not found.');end if;finish_change;
    exception when others then cancel_change;raise;
    end;
    procedure delete_curriculum(p_id number) is
    begin
      begin_change;delete from grades where curriculum_id=p_id;delete from discipline_teachers where curriculum_id=p_id;
      delete from curriculum where curriculum_id=p_id;
      if sql%rowcount<>1 then raise_application_error(-20142,'Curriculum entry not found.');end if;finish_change;
    exception when others then cancel_change;raise;
    end;
    procedure assign_curriculum_teacher(p_id number,p_teacher number) is
    begin
      begin_change;insert into discipline_teachers(curriculum_id,teacher_id) values(p_id,p_teacher);finish_change;
    exception when others then cancel_change;raise;
    end;
    procedure unassign_curriculum_teacher(p_id number,p_teacher number) is
    begin
      begin_change;delete from discipline_teachers where curriculum_id=p_id and teacher_id=p_teacher;
      if sql%rowcount<>1 then raise_application_error(-20072,'Assignment not found.');end if;finish_change;
    exception when others then cancel_change;raise;
    end;
    procedure replace_curriculum_teacher(p_id number,p_old number,p_new number) is
    begin
      begin_change;update discipline_teachers set teacher_id=p_new where curriculum_id=p_id and teacher_id=p_old;
      if sql%rowcount<>1 then raise_application_error(-20072,'Assignment not found.');end if;finish_change;
    exception when others then cancel_change;raise;
    end;
    procedure set_curriculum_grade(p_number varchar2,p_id number,p_grade number,p_date date,p_teacher number default null) is t number;n number;
    begin
      begin_change;
      select count(*) into n from students s join curriculum c on c.specialty_id=s.specialty_id where s.faculty_number=p_number and c.curriculum_id=p_id;
      if n<>1 then raise_application_error(-20140,'Grade curriculum must match the student specialty.');end if;
      t:=resolve_grade_teacher(p_id,p_teacher);
      merge into grades g using(select p_number f,p_id c from dual) x on(g.faculty_number=x.f and g.curriculum_id=x.c)
      when matched then update set grade_value=p_grade,grade_date=trunc(p_date),teacher_id=t
      when not matched then insert(faculty_number,curriculum_id,grade_value,grade_date,teacher_id) values(p_number,p_id,p_grade,trunc(p_date),t);
      finish_change;
    exception when others then cancel_change;raise;
    end;
    procedure migrate_legacy_curriculum is
    begin
      if sys_context('USERENV','SESSION_USER')<>sys_context('USERENV','CURRENT_USER') then raise_application_error(-20103,'Owner only.');end if;
      begin_change;
      execute immediate 'insert into curriculum select curriculum_seq.nextval,x.specialty_id,x.discipline_id,x.semester_no from (select sp.specialty_id,d.discipline_id,d.semester_no from specialties sp cross join disciplines d order by sp.specialty_id,d.discipline_id) x';
      execute immediate 'update discipline_teachers dt set curriculum_id=(select c.curriculum_id from curriculum c where c.discipline_id=dt.discipline_id and c.specialty_id=(select min(specialty_id) from specialties))';
      execute immediate 'insert into discipline_teachers(discipline_id,teacher_id,curriculum_id) select c.discipline_id,dt.teacher_id,c.curriculum_id from curriculum c join discipline_teachers dt on dt.discipline_id=c.discipline_id join curriculum origin on origin.curriculum_id=dt.curriculum_id where origin.specialty_id=(select min(specialty_id) from specialties) and c.specialty_id<>origin.specialty_id';
      execute immediate 'update grades g set curriculum_id=(select c.curriculum_id from curriculum c join students s on s.specialty_id=c.specialty_id where s.faculty_number=g.faculty_number and c.discipline_id=g.discipline_id)';
      finish_change;
    exception when others then cancel_change;raise;
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
            insert into disciplines(discipline_id,discipline_name) values(p_discipline_ids(i),p_disciplines(i).discipline_name);
            insert into curriculum(curriculum_id,specialty_id,discipline_id,semester_no)
            select curriculum_seq.nextval,nvl(p_disciplines(i).specialty_id,(select min(specialty_id) from specialties)),p_discipline_ids(i),p_disciplines(i).semester_no from dual;
            insert into discipline_teachers(curriculum_id,teacher_id)
            select curriculum_id,p_teacher_id from curriculum where discipline_id=p_discipline_ids(i);
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
        l_grade_teacher number; l_curriculum number;
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
            l_curriculum:=curriculum_for(p_faculty_number,p_grades(i).discipline_id);
            l_grade_teacher:=resolve_grade_teacher(l_curriculum,p_grades(i).teacher_id);
            insert into grades(faculty_number, curriculum_id, grade_value, grade_date, teacher_id)
            values(p_faculty_number, l_curriculum,
                   p_grades(i).grade_value, trunc(p_grades(i).grade_date),
                   l_grade_teacher);
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
        insert into grades(faculty_number, curriculum_id, grade_value, grade_date, teacher_id)
        select p_new_number, curriculum_id, grade_value, grade_date, teacher_id
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

    procedure add_discipline(p_name varchar2,p_semester_no number,p_teacher_id number,p_discipline_id out number) is cid number;
    begin
      begin_change;p_discipline_id:=disciplines_seq.nextval;cid:=curriculum_seq.nextval;
      insert into disciplines(discipline_id,discipline_name) values(p_discipline_id,p_name);
      insert into curriculum select cid,min(specialty_id),p_discipline_id,p_semester_no from specialties;
      insert into discipline_teachers(curriculum_id,teacher_id) values(cid,p_teacher_id);finish_change;
    exception when others then cancel_change;raise;
    end;

    procedure update_discipline(p_discipline_id number,p_name varchar2,p_semester_no number default null) is
    begin
      begin_change;
      if p_semester_no is not null then raise_application_error(-20143,'Semester belongs to CURRICULUM; use UPDATE_CURRICULUM.');end if;
      update disciplines set discipline_name=p_name where discipline_id=p_discipline_id;
      if sql%rowcount<>1 then raise_application_error(-20046,'Discipline not found.');end if;finish_change;
    exception when others then cancel_change;raise;
    end;

    procedure assign_teacher(p_discipline_id number,p_teacher_id number) is c number;
    begin
      select min(curriculum_id) into c from curriculum where discipline_id=p_discipline_id;
      assign_curriculum_teacher(nvl(c,-1),p_teacher_id);
    end;

    procedure unassign_teacher(p_discipline_id number,p_teacher_id number) is c number;
    begin
      select min(curriculum_id) into c from curriculum where discipline_id=p_discipline_id;
      unassign_curriculum_teacher(nvl(c,-1),p_teacher_id);
    end;

    procedure replace_teacher(p_discipline_id number,p_old_teacher_id number,p_new_teacher_id number) is c number;
    begin
      select min(curriculum_id) into c from curriculum where discipline_id=p_discipline_id;
      replace_curriculum_teacher(nvl(c,-1),p_old_teacher_id,p_new_teacher_id);
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
            insert into discipline_teachers(curriculum_id,teacher_id) select nvl(min(curriculum_id),-1),p_teacher_id from curriculum where discipline_id=p_discipline_ids(i);
        end loop;
        finish_change;
    exception when others then cancel_change; raise;
    end;

    procedure set_grade(p_faculty_number varchar2,p_discipline_id number,p_grade_value number,p_grade_date date,p_teacher_id number default null) is
    begin
      set_curriculum_grade(p_faculty_number,curriculum_for(p_faculty_number,p_discipline_id),p_grade_value,p_grade_date,p_teacher_id);
    end;

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
      delete from grades where curriculum_id in(select curriculum_id from curriculum where discipline_id=p_discipline_id);
      delete from discipline_teachers where curriculum_id in(select curriculum_id from curriculum where discipline_id=p_discipline_id);
      delete from curriculum where discipline_id=p_discipline_id;
      delete from disciplines where discipline_id=p_discipline_id;
      if sql%rowcount<>1 then raise_application_error(-20046,'Discipline not found.');end if;finish_change;
    exception when others then cancel_change;raise;
    end;

    procedure delete_grade(p_faculty_number varchar2,p_discipline_id number) is c number;
    begin
      c:=curriculum_for(p_faculty_number,p_discipline_id);begin_change;
      delete from grades where faculty_number=p_faculty_number and curriculum_id=c;
      if sql%rowcount<>1 then raise_application_error(-20062,'Grade not found.');end if;finish_change;
    exception when others then
      if g_write_allowed then cancel_change;end if;raise;
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

create or replace trigger curriculum_write_guard
before insert or update or delete on curriculum
begin
 if not university_api.write_allowed then raise_application_error(-20020,'Use UNIVERSITY_API.');end if;
end;
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
    -- Schema changes invalidate dependent packages/triggers. Recompile them
    -- before checking; no dependent object is excluded from final validation.
    dbms_utility.compile_schema(schema=>user,compile_all=>false);
    for e in (select name,type,line,position,text from user_errors order by name,sequence) loop
        dbms_output.put_line('COMPILE_ERROR|'||e.name||'|'||e.type||'|'||e.line||'|'||e.position||'|'||e.text);
    end loop;
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
 p_discipline1 disciplines.discipline_id%type, p_grade1 grades.grade_value%type, p_date1 grades.grade_date%type,
 p_discipline2 disciplines.discipline_id%type, p_grade2 grades.grade_value%type, p_date2 grades.grade_date%type
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
 p_name1 disciplines.discipline_name%type, p_semester1 curriculum.semester_no%type,
 p_name2 disciplines.discipline_name%type, p_semester2 curriculum.semester_no%type,
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
 p_name disciplines.discipline_name%type, p_semester curriculum.semester_no%type,
 p_teacher teachers.teacher_id%type, p_id out disciplines.discipline_id%type
) as
begin
 university_api.add_discipline(p_name,p_semester,p_teacher,p_id);
end;
/
create or replace procedure discipline_upd(
 p_id disciplines.discipline_id%type, p_name disciplines.discipline_name%type,
 p_semester curriculum.semester_no%type default null
) as
begin
 university_api.update_discipline(p_id,p_name,p_semester);
end;
/
-- INSERT must reject an existing pair; UPDATE must reject a missing pair.
-- Acquire the same writer locks before checking existence to avoid races.
create or replace procedure grade_ins(
 p_number grades.faculty_number%type, p_discipline disciplines.discipline_id%type,
 p_grade grades.grade_value%type, p_date grades.grade_date%type
) as
 l_count number;
begin
 savepoint grade_procedure_change;
 lock table students, teachers, disciplines, curriculum, discipline_teachers, grades in exclusive mode nowait;
 select count(*) into l_count from grades where faculty_number=p_number and curriculum_id=university_api.curriculum_for(p_number,p_discipline);
 if l_count<>0 then raise_application_error(-20061,'Grade already exists; use GRADE_UPD.'); end if;
 university_api.set_grade(p_number,p_discipline,p_grade,p_date);
exception when others then
 rollback to grade_procedure_change;
 raise;
end;
/
create or replace procedure grade_upd(
 p_number grades.faculty_number%type, p_discipline disciplines.discipline_id%type,
 p_grade grades.grade_value%type, p_date grades.grade_date%type
) as
 l_count number;
begin
 savepoint grade_procedure_change;
 lock table students, teachers, disciplines, curriculum, discipline_teachers, grades in exclusive mode nowait;
 select count(*) into l_count from grades where faculty_number=p_number and curriculum_id=university_api.curriculum_for(p_number,p_discipline);
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
  select d.discipline_id,d.discipline_name,c.semester_no,
         dbms_lob.substr(t.teacher_name,3000,1) teacher_name
  from disciplines d join curriculum c on c.discipline_id=d.discipline_id join v_discipline_teachers t on t.curriculum_id=c.curriculum_id
  where upper(d.discipline_name) like l_pattern escape '\'
  order by c.semester_no,d.discipline_name,d.discipline_id;
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
  select d.discipline_id,d.discipline_name,c.semester_no
  from disciplines d join curriculum c on c.discipline_id=d.discipline_id join discipline_teachers dt on dt.curriculum_id=c.curriculum_id
  where dt.teacher_id=p_teacher order by c.semester_no,d.discipline_name,d.discipline_id;
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
 p_discipline discipline_teachers.curriculum_id%type,
 p_teacher discipline_teachers.teacher_id%type
) as
begin university_api.assign_curriculum_teacher(p_discipline,p_teacher); end;
/
create or replace procedure discipline_teacher_del(
 p_discipline discipline_teachers.curriculum_id%type,
 p_teacher discipline_teachers.teacher_id%type
) as
begin university_api.unassign_curriculum_teacher(p_discipline,p_teacher); end;
/

-- AFTER INSERT feedback, generated only after the row has been inserted.
-- The transaction is still pending; a later ROLLBACK can undo the row.
create or replace trigger grades_after_insert
after insert on grades
for each row
begin
 dbms_output.put_line('AFTER INSERT: student='||:new.faculty_number||
  ', curriculum='||:new.curriculum_id||', grade='||:new.grade_value||' (transaction pending)');
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

-- Narrow, definer-rights API. Grant only this package to teacher database users.
-- A teacher login is UP_TEACHER_<teacher_id>; SESSION_USER cannot be selected
-- by supplying an API parameter or changing CURRENT_SCHEMA/CLIENT_IDENTIFIER.
set define off
set serveroutput on
whenever sqlerror exit sql.sqlcode rollback
create or replace package teacher_grading authid definer as
    function current_teacher_id return number;
    procedure insert_grade(p_student varchar2,p_discipline number,p_grade number,p_date date);
    procedure update_grade(p_student varchar2,p_discipline number,p_grade number,p_date date);
    procedure delete_grade(p_student varchar2,p_discipline number);
    procedure read_grades(p_result out sys_refcursor);
end teacher_grading;
/
create or replace package body teacher_grading as
    function current_teacher_id return number is t number;
    begin
        select min(teacher_id) into t from teachers
        where sys_context('USERENV','SESSION_USER')='UP_TEACHER_'||to_char(teacher_id,'TM9');
        if t is null then raise_application_error(-20100,'No teacher mapped to this authenticated Oracle login.'); end if;
        return t;
    end;
    function assigned_teacher(p_student varchar2,p_discipline number) return number is t number;n number;
    begin
        t:=current_teacher_id;
        select count(*) into n from discipline_teachers where curriculum_id=university_api.curriculum_for(p_student,p_discipline) and teacher_id=t;
        if n<>1 then raise_application_error(-20102,'This teacher does not teach this discipline.'); end if;
        return t;
    end;
    procedure insert_grade(p_student varchar2,p_discipline number,p_grade number,p_date date) is t number;n number;
    begin
        savepoint teacher_grade_change;
        lock table students,teachers,disciplines,curriculum,discipline_teachers,grades in exclusive mode nowait;
        t:=assigned_teacher(p_student,p_discipline);
        select count(*) into n from grades where faculty_number=p_student and curriculum_id=university_api.curriculum_for(p_student,p_discipline);
        if n<>0 then raise_application_error(-20061,'Grade already exists; use UPDATE_GRADE.'); end if;
        university_api.set_grade(p_student,p_discipline,p_grade,p_date,t);
    exception when others then rollback to teacher_grade_change;raise;
    end;
    procedure update_grade(p_student varchar2,p_discipline number,p_grade number,p_date date) is t number;n number;
    begin
        savepoint teacher_grade_change;
        lock table students,teachers,disciplines,curriculum,discipline_teachers,grades in exclusive mode nowait;
        t:=assigned_teacher(p_student,p_discipline);
        select count(*) into n from grades where faculty_number=p_student and curriculum_id=university_api.curriculum_for(p_student,p_discipline);
        if n<>1 then raise_application_error(-20062,'Grade does not exist; use INSERT_GRADE.'); end if;
        university_api.set_grade(p_student,p_discipline,p_grade,p_date,t);
    exception when others then rollback to teacher_grade_change;raise;
    end;
    procedure delete_grade(p_student varchar2,p_discipline number) is t number;
    begin
        savepoint teacher_grade_change;
        lock table students,teachers,disciplines,curriculum,discipline_teachers,grades in exclusive mode nowait;
        t:=assigned_teacher(p_student,p_discipline);
        university_api.delete_grade(p_student,p_discipline);
    exception when others then rollback to teacher_grade_change;raise;
    end;
    procedure read_grades(p_result out sys_refcursor) is t number;
    begin
        t:=current_teacher_id;
        open p_result for select r.* from v_academic_report r
        where exists(select 1 from discipline_teachers dt where dt.curriculum_id=r.curriculum_id and dt.teacher_id=t)
        order by r.faculty_number,r.semester_no,r.discipline_name,r.discipline_id;
    end;
end teacher_grading;
/
declare n number;
begin
 select count(*) into n from user_errors;
 if n<>0 then raise_application_error(-20109,'Compilation errors exist.');end if;
 dbms_output.put_line('TEACHER_GRADING_COMPILED');
end;
/

begin university_api.migrate_legacy_curriculum;end;
/
alter table discipline_teachers modify(curriculum_id not null);
alter table grades modify(curriculum_id not null);
alter table discipline_teachers drop constraint dt_discipline_fk;
drop index grades_assignment_ix;
alter table grades drop constraint grades_pk;
alter table discipline_teachers drop column discipline_id;
alter table grades drop column discipline_id;
alter table discipline_teachers add constraint discipline_teachers_pk primary key(curriculum_id,teacher_id);
alter table discipline_teachers add constraint dt_curriculum_fk foreign key(curriculum_id) references curriculum(curriculum_id);
alter table grades add constraint grades_pk primary key(faculty_number,curriculum_id);
alter table grades add constraint grades_assignment_fk foreign key(curriculum_id,teacher_id) references discipline_teachers(curriculum_id,teacher_id);
alter table disciplines drop constraint disciplines_semester_fk;
drop index disciplines_semester_ix;
alter table disciplines drop column semester_no;
create index grades_assignment_ix on grades(curriculum_id,teacher_id);
create index curriculum_discipline_ix on curriculum(discipline_id);
create index curriculum_semester_ix on curriculum(semester_no);
begin dbms_utility.compile_schema(schema=>user,compile_all=>false);end;
/
begin dbms_session.reset_package;end;
/
declare n number;
begin
 select count(*) into n from user_errors;
 if n<>0 then raise_application_error(-20151,'Compilation errors after curriculum migration.');end if;
 university_api.validate_rules;
end;
/
commit;
prompt CURRICULUM_MIGRATION_COMPLETED
