-- SOURCE: 01_schema.sql
-- University database: Oracle 11g XE, eleven normalized tables.
-- Import-only DDL is in models/university_import.sql.
-- Executed in UNIVERSITY_PROJECT; saved native model matches this schema.
-- Minimum two disciplines per student/teacher are enforced by sql/02_programs.sql.
set define off
set serveroutput on
whenever sqlerror exit sql.sqlcode rollback

declare
    l_count number;
begin
    if user <> 'UNIVERSITY_PROJECT' then
        raise_application_error(-20000, 'Use the UNIVERSITY_PROJECT schema.');
    end if;
    select count(*) into l_count from user_objects
    where object_name in (
        'SPECIALTIES','ACADEMIC_TITLES','STUDY_YEARS','SEMESTERS',
        'CURRICULUM','GRADE_SCALE','STUDENTS','TEACHERS','DISCIPLINES','DISCIPLINE_TEACHERS','GRADES',
        'SPECIALTIES_SEQ','ACADEMIC_TITLES_SEQ','TEACHERS_SEQ','DISCIPLINES_SEQ','CURRICULUM_SEQ'
    );
    if l_count > 0 then
        raise_application_error(-20001, 'Project objects already exist. No reset is performed.');
    end if;
end;
/

create table specialties (
    specialty_id number not null,
    specialty_name varchar2(120 char) not null,
    constraint specialties_pk primary key (specialty_id),
    constraint specialties_name_uq unique (specialty_name),
    constraint specialties_id_ck check (specialty_id > 0 and specialty_id = trunc(specialty_id)),
    constraint specialties_name_ck check (trim(specialty_name) is not null)
);

create table academic_titles (
    title_id number not null,
    title_name varchar2(80 char) not null,
    constraint academic_titles_pk primary key (title_id),
    constraint academic_titles_name_uq unique (title_name),
    constraint academic_titles_id_ck check (title_id > 0 and title_id = trunc(title_id)),
    constraint academic_titles_name_ck check (trim(title_name) is not null)
);

create table study_years (
    study_year_no number not null,
    year_label varchar2(30 char) not null,
    constraint study_years_pk primary key (study_year_no),
    constraint study_years_label_uq unique (year_label),
    constraint study_years_no_ck check (study_year_no > 0 and study_year_no = trunc(study_year_no)),
    constraint study_years_label_ck check (trim(year_label) is not null)
);

create table semesters (
    semester_no number not null,
    study_year_no number not null,
    term_no number not null,
    constraint semesters_pk primary key (semester_no),
    constraint semesters_year_fk foreign key (study_year_no) references study_years (study_year_no),
    constraint semesters_year_term_uq unique (study_year_no, term_no),
    constraint semesters_no_ck check (semester_no > 0 and semester_no = trunc(semester_no)),
    constraint semesters_term_ck check (term_no in (1, 2)),
    constraint semesters_order_ck check (semester_no = 2 * (study_year_no - 1) + term_no)
);

create table grade_scale (
    grade_value number not null,
    grade_label varchar2(30 char) not null,
    is_passing number not null,
    constraint grade_scale_pk primary key (grade_value),
    constraint grade_scale_label_uq unique (grade_label),
    constraint grade_scale_value_ck check (
        grade_value between 2 and 6 and grade_value = trunc(grade_value)
    ),
    constraint grade_scale_passing_ck check (
        (grade_value = 2 and is_passing = 0)
        or (grade_value between 3 and 6 and is_passing = 1)
    ),
    constraint grade_scale_label_ck check (trim(grade_label) is not null)
);

create table students (
    faculty_number varchar2(20 char) not null,
    first_name varchar2(60 char) not null,
    middle_name varchar2(60 char),
    last_name varchar2(60 char) not null,
    specialty_id number not null,
    study_year_no number not null,
    email varchar2(254 char) not null,
    constraint students_pk primary key (faculty_number),
    constraint students_specialty_fk foreign key (specialty_id) references specialties (specialty_id),
    constraint students_year_fk foreign key (study_year_no) references study_years (study_year_no),
    constraint students_number_ck check (trim(faculty_number) is not null),
    constraint students_first_name_ck check (trim(first_name) is not null),
    constraint students_last_name_ck check (trim(last_name) is not null),
    constraint students_email_ck check (email like '%_@_%._%')
);

create table teachers (
    teacher_id number not null,
    first_name varchar2(60 char) not null,
    middle_name varchar2(60 char),
    last_name varchar2(60 char) not null,
    title_id number not null,
    phone varchar2(30 char) not null,
    email varchar2(254 char) not null,
    constraint teachers_pk primary key (teacher_id),
    constraint teachers_title_fk foreign key (title_id) references academic_titles (title_id),
    constraint teachers_id_ck check (teacher_id > 0 and teacher_id = trunc(teacher_id)),
    constraint teachers_first_name_ck check (trim(first_name) is not null),
    constraint teachers_last_name_ck check (trim(last_name) is not null),
    constraint teachers_phone_ck check (trim(phone) is not null),
    constraint teachers_email_ck check (email like '%_@_%._%')
);

create table disciplines (
    discipline_id number not null,
    discipline_name varchar2(150 char) not null,
    constraint disciplines_pk primary key (discipline_id),
    constraint disciplines_id_ck check (discipline_id > 0 and discipline_id = trunc(discipline_id)),
    constraint disciplines_name_ck check (trim(discipline_name) is not null)
);

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

create table discipline_teachers (
    curriculum_id number not null,
    teacher_id number not null,
    constraint discipline_teachers_pk primary key (curriculum_id, teacher_id),
    constraint dt_curriculum_fk foreign key (curriculum_id) references curriculum (curriculum_id),
    constraint dt_teacher_fk foreign key (teacher_id) references teachers (teacher_id)
);

create table grades (
    faculty_number varchar2(20 char) not null,
    curriculum_id number not null,
    grade_value number not null,
    grade_date date not null,
    teacher_id number not null,
    constraint grades_pk primary key (faculty_number, curriculum_id),
    constraint grades_student_fk foreign key (faculty_number) references students (faculty_number),
    constraint grades_assignment_fk foreign key (curriculum_id, teacher_id)
        references discipline_teachers (curriculum_id, teacher_id),
    constraint grades_value_fk foreign key (grade_value) references grade_scale (grade_value)
);

create index students_specialty_ix on students (specialty_id);
create index students_year_ix on students (study_year_no);
create index teachers_title_ix on teachers (title_id);
create index curriculum_discipline_ix on curriculum(discipline_id);
create index curriculum_semester_ix on curriculum(semester_no);
create index dt_teacher_ix on discipline_teachers (teacher_id);
create index grades_assignment_ix on grades (curriculum_id, teacher_id);
create index grades_value_ix on grades (grade_value);
-- grades_pk covers the student FK; semesters_year_term_uq covers the year FK.

create sequence curriculum_seq start with 1 increment by 1 nocache;
create sequence specialties_seq start with 100 increment by 1 nocache;
create sequence academic_titles_seq start with 100 increment by 1 nocache;
create sequence teachers_seq start with 1 increment by 1 nocache;
create sequence disciplines_seq start with 1 increment by 1 nocache;

create or replace trigger curriculum_bi
before insert on curriculum for each row
begin
 if :new.curriculum_id is null then :new.curriculum_id:=curriculum_seq.nextval;end if;
end;
/
create or replace trigger specialties_bi
before insert on specialties for each row
begin
    if :new.specialty_id is null then :new.specialty_id := specialties_seq.nextval; end if;
end;
/
create or replace trigger academic_titles_bi
before insert on academic_titles for each row
begin
    if :new.title_id is null then :new.title_id := academic_titles_seq.nextval; end if;
end;
/
create or replace trigger teachers_bi
before insert on teachers for each row
begin
    if :new.teacher_id is null then :new.teacher_id := teachers_seq.nextval; end if;
end;
/
create or replace trigger disciplines_bi
before insert on disciplines for each row
begin
    if :new.discipline_id is null then :new.discipline_id := disciplines_seq.nextval; end if;
end;
/

comment on table specialties is 'Specialty reference data. Names are stored once.';
comment on table academic_titles is 'Academic title reference data for teachers.';
comment on table study_years is 'Permitted current study years and their display labels.';
comment on table semesters is 'Global semester number and its study year/term mapping.';
comment on table grade_scale is 'Bulgarian integer grade scale 2-6 with labels and passing status.';
comment on table students is 'Students. Each must have grades in at least two distinct disciplines after a completed operation.';
comment on table teachers is 'Teachers. Each must lead at least two distinct disciplines after a completed operation.';
comment on table disciplines is 'Course catalogue. Semester belongs to the specialty curriculum, not to this catalogue.';
comment on table curriculum is 'One course in a specialty curriculum and its semester. Each entry has one or more assigned teachers.';
comment on table discipline_teachers is 'Teaching assignments per specialty curriculum entry. Composite PK prevents duplicate pairs. Each curriculum entry has a teacher; each teacher leads at least two distinct catalogue disciplines.';
comment on table grades is 'One mandatory grade and date for every recorded student-discipline pair. Corrections use UPDATE.';

comment on column students.faculty_number is 'Text identifier preserving leading zeroes and letters.';
comment on column students.middle_name is 'Optional middle or patronymic name.';
comment on column teachers.phone is 'Text phone number preserving prefix, plus sign and leading zeroes.';
comment on column semesters.term_no is 'First or second semester within the study year.';
comment on column grades.grade_date is 'Date of the examination/grade.';
comment on column grades.teacher_id is 'Responsible grading teacher. Must be assigned to the same discipline. Teacher sessions derive this identity from SESSION_USER.';
comment on column grade_scale.is_passing is '0 for grade 2; 1 for grades 3 through 6.';

prompt UNIVERSITY_SCHEMA_READY

-- SOURCE: 02_programs.sql
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

-- SOURCE: 10_standalone_programs.sql
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

-- SOURCE: 20_teacher_grading.sql
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

-- SOURCE: 03_seed_data.sql
-- Fictional educational data. Run once after 01_schema.sql and 02_programs.sql.
set define off
set serveroutput on
whenever sqlerror exit sql.sqlcode rollback

declare
 l_count number;
begin
 if user <> 'UNIVERSITY_PROJECT' then raise_application_error(-20000,'Use UNIVERSITY_PROJECT.'); end if;
 select (select count(*) from students)+(select count(*) from teachers)+(select count(*) from specialties)+(select count(*) from academic_titles)+(select count(*) from study_years)+(select count(*) from grade_scale) into l_count from dual;
 if l_count <> 0 then raise_application_error(-20060,'Seed data requires an empty project schema. No data is removed.'); end if;
end;
/
insert into specialties values (1,unistr('\041a\043e\043c\043f\044e\0442\044a\0440\043d\0438 \043d\0430\0443\043a\0438'));
insert into specialties values (2,unistr('\0421\043e\0444\0442\0443\0435\0440\043d\043e \0438\043d\0436\0435\043d\0435\0440\0441\0442\0432\043e'));
insert into specialties values (3,unistr('\0418\043a\043e\043d\043e\043c\0438\043a\0430'));
insert into academic_titles values (1,unistr('\0430\0441\0438\0441\0442\0435\043d\0442'));
insert into academic_titles values (2,unistr('\0433\043b\0430\0432\0435\043d \0430\0441\0438\0441\0442\0435\043d\0442'));
insert into academic_titles values (3,unistr('\0434\043e\0446\0435\043d\0442'));
insert into academic_titles values (4,unistr('\043f\0440\043e\0444\0435\0441\043e\0440'));
insert into study_years values (1,unistr('I \043a\0443\0440\0441'));
insert into study_years values (2,unistr('II \043a\0443\0440\0441'));
insert into study_years values (3,unistr('III \043a\0443\0440\0441'));
insert into study_years values (4,unistr('IV \043a\0443\0440\0441'));
insert into study_years values (5,unistr('V \043a\0443\0440\0441'));
insert into study_years values (6,unistr('VI \043a\0443\0440\0441'));
insert into semesters values (1,1,1);
insert into semesters values (2,1,2);
insert into semesters values (3,2,1);
insert into semesters values (4,2,2);
insert into semesters values (5,3,1);
insert into semesters values (6,3,2);
insert into semesters values (7,4,1);
insert into semesters values (8,4,2);
insert into semesters values (9,5,1);
insert into semesters values (10,5,2);
insert into semesters values (11,6,1);
insert into semesters values (12,6,2);
insert into grade_scale values (2,unistr('\0421\043b\0430\0431'),0);
insert into grade_scale values (3,unistr('\0421\0440\0435\0434\0435\043d'),1);
insert into grade_scale values (4,unistr('\0414\043e\0431\044a\0440'),1);
insert into grade_scale values (5,unistr('\041c\043d\043e\0433\043e \0434\043e\0431\044a\0440'),1);
insert into grade_scale values (6,unistr('\041e\0442\043b\0438\0447\0435\043d'),1);

declare
 l_disciplines university_api.t_discipline_list;
 l_grades university_api.t_grade_list;
 l_teacher_id number; l_copy_id number;
 l_created_ids sys.odcinumberlist;
 type t_ids is table of number index by pls_integer;
 l_ids t_ids;
begin
 l_disciplines.delete;
 l_disciplines(1).discipline_name := unistr('\041c\0430\0442\0435\043c\0430\0442\0438\043a\0430'); l_disciplines(1).semester_no := 1;
 l_disciplines(2).discipline_name := unistr('\0410\043b\0433\043e\0440\0438\0442\043c\0438'); l_disciplines(2).semester_no := 2;
 l_disciplines(3).discipline_name := unistr('\0414\0438\0441\043a\0440\0435\0442\043d\0430 \043c\0430\0442\0435\043c\0430\0442\0438\043a\0430'); l_disciplines(3).semester_no := 2;
 university_api.create_teacher(unistr('\041f\0435\0442\044a\0440'),unistr('\0418\0432\0430\043d\043e\0432'),unistr('\041d\0438\043a\043e\043b\043e\0432'),4,'+359000000001','teacher1@university.example',l_disciplines,l_teacher_id,l_created_ids);
 l_ids(1) := l_created_ids(1);
 l_ids(2) := l_created_ids(2);
 l_ids(3) := l_created_ids(3);
 l_disciplines.delete;
 l_disciplines(1).discipline_name := unistr('\0411\0430\0437\0438 \043e\0442 \0434\0430\043d\043d\0438'); l_disciplines(1).semester_no := 3;
 l_disciplines(2).discipline_name := unistr('SQL \043f\0440\043e\0433\0440\0430\043c\0438\0440\0430\043d\0435'); l_disciplines(2).semester_no := 4;
 l_disciplines(3).discipline_name := unistr('\041c\043e\0434\0435\043b\0438\0440\0430\043d\0435 \043d\0430 \0434\0430\043d\043d\0438'); l_disciplines(3).semester_no := 3;
 university_api.create_teacher(unistr('\041c\0430\0440\0438\044f'),unistr('\041f\0435\0442\0440\043e\0432\0430'),unistr('\0413\0435\043e\0440\0433\0438\0435\0432\0430'),3,'+359000000002','teacher2@university.example',l_disciplines,l_teacher_id,l_created_ids);
 l_ids(4) := l_created_ids(1);
 l_ids(5) := l_created_ids(2);
 l_ids(6) := l_created_ids(3);
 l_disciplines.delete;
 l_disciplines(1).discipline_name := unistr('\041e\043f\0435\0440\0430\0446\0438\043e\043d\043d\0438 \0441\0438\0441\0442\0435\043c\0438'); l_disciplines(1).semester_no := 3;
 l_disciplines(2).discipline_name := unistr('\041a\043e\043c\043f\044e\0442\044a\0440\043d\0438 \043c\0440\0435\0436\0438'); l_disciplines(2).semester_no := 4;
 university_api.create_teacher(unistr('\0418\0432\0430\043d'),unistr('\041a\043e\043b\0435\0432'),unistr('\0414\0438\043c\0438\0442\0440\043e\0432'),2,'+359000000003','teacher3@university.example',l_disciplines,l_teacher_id,l_created_ids);
 l_ids(7) := l_created_ids(1);
 l_ids(8) := l_created_ids(2);
 l_disciplines.delete;
 l_disciplines(1).discipline_name := unistr('\041e\0441\043d\043e\0432\0438 \043d\0430 \0438\043a\043e\043d\043e\043c\0438\043a\0430\0442\0430'); l_disciplines(1).semester_no := 1;
 l_disciplines(2).discipline_name := unistr('\0421\0442\0430\0442\0438\0441\0442\0438\043a\0430'); l_disciplines(2).semester_no := 2;
 university_api.create_teacher(unistr('\0415\043b\0435\043d\0430'),unistr('\041d\0438\043a\043e\043b\043e\0432\0430'),unistr('\0421\0442\043e\044f\043d\043e\0432\0430'),3,'+359000000004','teacher4@university.example',l_disciplines,l_teacher_id,l_created_ids);
 l_ids(9) := l_created_ids(1);
 l_ids(10) := l_created_ids(2);
 l_disciplines.delete;
 l_disciplines(1).discipline_name := unistr('\0421\043e\0444\0442\0443\0435\0440\043d\043e \0438\043d\0436\0435\043d\0435\0440\0441\0442\0432\043e'); l_disciplines(1).semester_no := 5;
 l_disciplines(2).discipline_name := unistr('\0423\0435\0431 \0442\0435\0445\043d\043e\043b\043e\0433\0438\0438'); l_disciplines(2).semester_no := 6;
 university_api.create_teacher(unistr('\0413\0435\043e\0440\0433\0438'),unistr('\0422\043e\0434\043e\0440\043e\0432'),unistr('\041f\0435\0442\0440\043e\0432'),4,'+359000000005','teacher5@university.example',l_disciplines,l_teacher_id,l_created_ids);
 l_ids(11) := l_created_ids(1);
 l_ids(12) := l_created_ids(2);
 l_disciplines.delete;
 l_disciplines(1).discipline_name := unistr('\0410\043d\0433\043b\0438\0439\0441\043a\0438 \0435\0437\0438\043a'); l_disciplines(1).semester_no := 1;
 l_disciplines(2).discipline_name := unistr('\0410\043a\0430\0434\0435\043c\0438\0447\0435\043d \0430\043d\0433\043b\0438\0439\0441\043a\0438'); l_disciplines(2).semester_no := 2;
 university_api.create_teacher(unistr('\0410\043d\043d\0430'),unistr('\0414\0438\043c\0438\0442\0440\043e\0432\0430'),unistr('\041a\043e\043b\0435\0432\0430'),1,'+359000000006','teacher6@university.example',l_disciplines,l_teacher_id,l_created_ids);
 l_ids(13) := l_created_ids(1);
 l_ids(14) := l_created_ids(2);
 select teacher_id into l_teacher_id from teachers where email='teacher2@university.example';
 university_api.assign_teacher(l_ids(1),l_teacher_id);
 select teacher_id into l_teacher_id from teachers where email='teacher1@university.example';
 university_api.assign_teacher(l_ids(4),l_teacher_id);
 -- Explicitly copy the legacy common programme into specialties 2 and 3.
 -- Future curricula are managed separately; teacher APIs never create curricula.
 for c in(select c.*, (select min(teacher_id) from discipline_teachers dt where dt.curriculum_id=c.curriculum_id) initial_teacher
          from curriculum c where c.specialty_id=(select min(specialty_id) from specialties)) loop
   for sp in(select specialty_id from specialties where specialty_id<>c.specialty_id order by specialty_id) loop
     university_api.add_curriculum(sp.specialty_id,c.discipline_id,c.semester_no,c.initial_teacher,l_copy_id);
     for t in(select teacher_id from discipline_teachers where curriculum_id=c.curriculum_id and teacher_id<>c.initial_teacher) loop
       university_api.assign_curriculum_teacher(l_copy_id,t.teacher_id);
     end loop;
   end loop;
 end loop;
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(1); l_grades(1).grade_value := 6; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(2); l_grades(2).grade_value := 6; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(13); l_grades(3).grade_value := 6; l_grades(3).grade_date := date '2026-06-12';
 l_grades(4).discipline_id := l_ids(3); l_grades(4).grade_value := 6; l_grades(4).grade_date := date '2026-06-13';
 university_api.create_student('00010001',unistr('\0410\043b\0435\043a\0441\0430\043d\0434\044a\0440'),unistr('\0418\0432\0430\043d\043e\0432'),unistr('\041f\0435\0442\0440\043e\0432'),1,1,'student1@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(1); l_grades(1).grade_value := 5; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(2); l_grades(2).grade_value := 4; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(13); l_grades(3).grade_value := 5; l_grades(3).grade_date := date '2026-06-12';
 l_grades(4).discipline_id := l_ids(9); l_grades(4).grade_value := 4; l_grades(4).grade_date := date '2026-06-13';
 university_api.create_student('00010002',unistr('\041c\0430\0440\0438\044f'),unistr('\0413\0435\043e\0440\0433\0438\0435\0432\0430'),unistr('\0414\0438\043c\0438\0442\0440\043e\0432\0430'),2,1,'student2@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(1); l_grades(1).grade_value := 2; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(2); l_grades(2).grade_value := 3; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(13); l_grades(3).grade_value := 4; l_grades(3).grade_date := date '2026-06-12';
 l_grades(4).discipline_id := l_ids(10); l_grades(4).grade_value := 3; l_grades(4).grade_date := date '2026-06-13';
 university_api.create_student('00010003',unistr('\0418\0432\0430\043d'),unistr('\041f\0435\0442\0440\043e\0432'),unistr('\0421\0442\043e\044f\043d\043e\0432'),3,1,'student3@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(1); l_grades(1).grade_value := 6; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(2); l_grades(2).grade_value := 6; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(13); l_grades(3).grade_value := 6; l_grades(3).grade_date := date '2026-06-12';
 l_grades(4).discipline_id := l_ids(3); l_grades(4).grade_value := 6; l_grades(4).grade_date := date '2026-06-13';
 university_api.create_student('00010004',unistr('\0415\043b\0435\043d\0430'),unistr('\041d\0438\043a\043e\043b\043e\0432\0430'),unistr('\0413\0435\043e\0440\0433\0438\0435\0432\0430'),1,1,'student4@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(1); l_grades(1).grade_value := 4; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(2); l_grades(2).grade_value := 5; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(13); l_grades(3).grade_value := 5; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010005',unistr('\0413\0435\043e\0440\0433\0438'),unistr('\0414\0438\043c\0438\0442\0440\043e\0432'),unistr('\0418\0432\0430\043d\043e\0432'),2,1,'student5@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(1); l_grades(1).grade_value := 2; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(2); l_grades(2).grade_value := 2; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(13); l_grades(3).grade_value := 3; l_grades(3).grade_date := date '2026-06-12';
 l_grades(4).discipline_id := l_ids(14); l_grades(4).grade_value := 3; l_grades(4).grade_date := date '2026-06-13';
 university_api.create_student('00010006',unistr('\0410\043d\043d\0430'),unistr('\0421\0442\043e\044f\043d\043e\0432\0430'),unistr('\041f\0435\0442\0440\043e\0432\0430'),3,1,'student6@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(4); l_grades(1).grade_value := 5; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(5); l_grades(2).grade_value := 5; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(7); l_grades(3).grade_value := 5; l_grades(3).grade_date := date '2026-06-12';
 l_grades(4).discipline_id := l_ids(6); l_grades(4).grade_value := 5; l_grades(4).grade_date := date '2026-06-13';
 university_api.create_student('00010007',unistr('\041d\0438\043a\043e\043b\0430\0439'),unistr('\0410\043b\0435\043a\0441\0430\043d\0434\0440\043e\0432'),unistr('\041a\043e\043b\0435\0432'),1,2,'student7@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(4); l_grades(1).grade_value := 6; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(5); l_grades(2).grade_value := 5; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(7); l_grades(3).grade_value := 5; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010008',unistr('\0412\0438\043a\0442\043e\0440\0438\044f'),unistr('\0418\0432\0430\043d\043e\0432\0430'),unistr('\041d\0438\043a\043e\043b\043e\0432\0430'),2,2,'student8@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(4); l_grades(1).grade_value := 3; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(5); l_grades(2).grade_value := 4; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(7); l_grades(3).grade_value := 2; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010009',unistr('\0414\0438\043c\0438\0442\044a\0440'),unistr('\0413\0435\043e\0440\0433\0438\0435\0432'),unistr('\0422\043e\0434\043e\0440\043e\0432'),3,2,'student9@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(4); l_grades(1).grade_value := 4; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(5); l_grades(2).grade_value := 4; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(7); l_grades(3).grade_value := 5; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010010',unistr('\041f\0435\0442\044f'),unistr('\041f\0435\0442\0440\043e\0432\0430'),unistr('\041a\043e\0441\0442\043e\0432\0430'),1,2,'student10@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(4); l_grades(1).grade_value := 6; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(5); l_grades(2).grade_value := 6; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(7); l_grades(3).grade_value := 5; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010011',unistr('\0411\043e\0440\0438\0441'),unistr('\041d\0438\043a\043e\043b\043e\0432'),unistr('\0414\0438\043c\0438\0442\0440\043e\0432'),2,2,'student11@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(4); l_grades(1).grade_value := 2; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(5); l_grades(2).grade_value := 3; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(7); l_grades(3).grade_value := 3; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010012',unistr('\0421\043e\0444\0438\044f'),unistr('\0422\043e\0434\043e\0440\043e\0432\0430'),unistr('\0418\0432\0430\043d\043e\0432\0430'),3,2,'student12@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(11); l_grades(1).grade_value := 5; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(12); l_grades(2).grade_value := 5; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(8); l_grades(3).grade_value := 4; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010013',unistr('\041c\0430\0440\0442\0438\043d'),unistr('\041a\043e\043b\0435\0432'),unistr('\041f\0435\0442\0440\043e\0432'),1,3,'student13@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(11); l_grades(1).grade_value := 4; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(12); l_grades(2).grade_value := 6; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(8); l_grades(3).grade_value := 5; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010014',unistr('\0414\0435\0441\0438\0441\043b\0430\0432\0430'),unistr('\0414\0438\043c\0438\0442\0440\043e\0432\0430'),unistr('\0421\0442\043e\044f\043d\043e\0432\0430'),2,3,'student14@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(11); l_grades(1).grade_value := 3; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(12); l_grades(2).grade_value := 2; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(8); l_grades(3).grade_value := 4; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010015',unistr('\0425\0440\0438\0441\0442\043e'),unistr('\0418\0432\0430\043d\043e\0432'),unistr('\041d\0438\043a\043e\043b\043e\0432'),3,3,'student15@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(11); l_grades(1).grade_value := 6; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(12); l_grades(2).grade_value := 5; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(8); l_grades(3).grade_value := 6; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010016',unistr('\0420\0430\043b\0438\0446\0430'),unistr('\0413\0435\043e\0440\0433\0438\0435\0432\0430'),unistr('\041a\043e\0441\0442\043e\0432\0430'),1,3,'student16@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(11); l_grades(1).grade_value := 5; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(12); l_grades(2).grade_value := 5; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(8); l_grades(3).grade_value := 5; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010017',unistr('\041f\0430\0432\0435\043b'),unistr('\0421\0442\043e\044f\043d\043e\0432'),unistr('\041a\043e\043b\0435\0432'),2,3,'student17@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(11); l_grades(1).grade_value := 2; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(12); l_grades(2).grade_value := 3; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(8); l_grades(3).grade_value := 4; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010018',unistr('\0419\043e\0430\043d\0430'),unistr('\041f\0435\0442\0440\043e\0432\0430'),unistr('\0414\0438\043c\0438\0442\0440\043e\0432\0430'),3,3,'student18@university.example',l_grades);
 university_api.validate_rules;
 dbms_output.put_line('SEED_DATA_CREATED_OK');
end;
/
commit;
select 'SPECIALTIES' table_name,count(*) row_count from specialties
union all select 'ACADEMIC_TITLES',count(*) from academic_titles
union all select 'STUDY_YEARS',count(*) from study_years
union all select 'SEMESTERS',count(*) from semesters
union all select 'GRADE_SCALE',count(*) from grade_scale
union all select 'STUDENTS',count(*) from students
union all select 'TEACHERS',count(*) from teachers
union all select 'DISCIPLINES',count(*) from disciplines
union all select 'GRADES',count(*) from grades
union all select 'DISCIPLINE_TEACHERS',count(*) from discipline_teachers
union all select 'CURRICULUM',count(*) from curriculum;
prompt SEED_COMMITTED_OK

-- SOURCE: 25_curriculum_example.sql
-- Committed fictional example requested by the owner: SA in SIT/6 and KST/4.
-- Safe to repeat: existing example rows are retained, not overwritten.
set define off
set serveroutput on
whenever sqlerror exit sql.sqlcode rollback
declare
 sit number;kst number;sa number;math number;cs number;ck number;cm number;n number;
 g university_api.t_grade_list;
begin
 select min(specialty_id) into sit from specialties where specialty_name=unistr('\0421\0418\0422');
 if sit is null then insert into specialties(specialty_name) values(unistr('\0421\0418\0422')) returning specialty_id into sit;end if;
 select min(specialty_id) into kst from specialties where specialty_name=unistr('\041a\0421\0422');
 if kst is null then insert into specialties(specialty_name) values(unistr('\041a\0421\0422')) returning specialty_id into kst;end if;
 select min(discipline_id) into sa from disciplines where discipline_name=unistr('\0421\0410');
 if sa is null then university_api.create_catalog_discipline(unistr('\0421\0410'),sa);end if;
 select min(curriculum_id) into cs from curriculum where specialty_id=sit and discipline_id=sa;
 if cs is null then university_api.add_curriculum(sit,sa,6,1,cs);end if;
 select min(curriculum_id) into ck from curriculum where specialty_id=kst and discipline_id=sa;
 if ck is null then university_api.add_curriculum(kst,sa,4,1,ck);end if;
 select count(*) into n from discipline_teachers where curriculum_id=ck and teacher_id=2;
 if n=0 then university_api.assign_curriculum_teacher(ck,2);end if;
 select min(discipline_id) into math from disciplines where discipline_name=unistr('\041c\0430\0442\0435\043c\0430\0442\0438\043a\0430');
 for sp in(select specialty_id from specialties where specialty_id in(sit,kst)) loop
   select min(curriculum_id) into cm from curriculum where specialty_id=sp.specialty_id and discipline_id=math;
   if cm is null then university_api.add_curriculum(sp.specialty_id,math,1,1,cm);end if;
 end loop;
 g(1).discipline_id:=sa;g(1).grade_value:=5;g(1).grade_date:=date '2026-10-20';g(1).teacher_id:=1;
 g(2).discipline_id:=math;g(2).grade_value:=6;g(2).grade_date:=date '2026-10-20';g(2).teacher_id:=1;
 select count(*) into n from students where faculty_number='SIT-DEMO';
 if n=0 then university_api.create_student('SIT-DEMO','Demo',null,'SIT',sit,3,'sit.demo@university.example',g);end if;
 select count(*) into n from students where faculty_number='KST-DEMO';
 if n=0 then university_api.create_student('KST-DEMO','Demo',null,'KST',kst,2,'kst.demo@university.example',g);end if;
 university_api.validate_rules;
end;
/
commit;
select sp.specialty_name,d.discipline_name,c.semester_no,c.curriculum_id,dt.teacher_id
from curriculum c join specialties sp on sp.specialty_id=c.specialty_id
join disciplines d on d.discipline_id=c.discipline_id
join discipline_teachers dt on dt.curriculum_id=c.curriculum_id
where d.discipline_name=unistr('\0421\0410') order by sp.specialty_name,dt.teacher_id;
prompt CURRICULUM_EXAMPLE_READY

-- SOURCE: 07_validation.sql
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

-- SOURCE: 11_lesson_demo.sql
set define off
set serveroutput on
whenever sqlerror exit sql.sqlcode rollback
prompt LESSON DEMONSTRATION: changes will be rolled back

declare
 l_teacher number; l_d1 number; l_d2 number; l_d3 number;
 l_title number; l_specialty number; l_year number;
begin
 select min(title_id) into l_title from academic_titles;
 select min(specialty_id) into l_specialty from specialties;
 select min(study_year_no) into l_year from study_years;
 teacher_ins('Demo',null,'Teacher',l_title,'+359000000099','demo.teacher@university.example',
  'Demo modelling',1,'Demo databases',2,l_teacher,l_d1,l_d2);
 student_ins('DEMO-LESSON','Demo',null,'Student',l_specialty,l_year,'demo.student@university.example',
  l_d1,4,date '2026-06-10',l_d2,5,date '2026-06-11');
 student_upd('DEMO-LESSON','Demo',null,'Student',l_specialty,l_year,'updated.student@university.example');
 teacher_upd(l_teacher,'Demo',null,'Teacher',l_title,'+359000000098','updated.teacher@university.example');
 discipline_ins('Demo SQL',3,l_teacher,l_d3);
 discipline_upd(l_d3,'Demo SQL and PL/SQL');
 grade_ins('DEMO-LESSON',l_d3,6,date '2026-06-12');
 grade_upd('DEMO-LESSON',l_d1,5,date '2026-06-13');
 dbms_output.put_line('EXPLICIT OPEN/FETCH/CLOSE CURSOR:');
 academic_report('DEMO-LESSON');
 dbms_output.put_line('FOR CURSOR - TEACHER DISCIPLINES:');
 teacher_disciplines(l_teacher);
 dbms_output.put_line('LIKE CURSOR - STUDENT KEYWORD:');
 find_student('Demo');
 dbms_output.put_line('LIKE CURSOR - DISCIPLINE KEYWORD:');
 find_discipline('PL/SQL');
end;
/
rollback;
prompt LESSON_DEMO_ROLLED_BACK

prompt SEEDED ACADEMIC REPORT - EXPLICIT CURSOR
begin academic_report('00010001'); end;
/
prompt CYRILLIC KEYWORD SEARCH
begin find_student(unistr('\0410\043b\0435\043a\0441\0430\043d\0434\044a\0440')); end;
/
begin find_discipline(unistr('\0431\0430\0437\0438')); end;
/

-- SOURCE: 12_lesson_validation.sql
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
 discipline_upd(l_d3,'LESSON updated discipline');
 university_api.update_curriculum(university_api.curriculum_for('LESSON-STUDENT',l_d3),4);
 select count(*) into l_count from disciplines d join curriculum c on c.discipline_id=d.discipline_id where d.discipline_id=l_d3 and c.semester_no=4
 and discipline_name='LESSON updated discipline';
 assert_true(l_count=1,'DISCIPLINE_UPD changes name and semester');

 grade_ins('LESSON-STUDENT',l_d3,6,date '2026-06-12');
 select count(*) into l_count from grades where faculty_number='LESSON-STUDENT';
 assert_true(l_count=3,'GRADE_INS adds one new student-discipline pair');
 grade_upd('LESSON-STUDENT',l_d3,5,date '2026-06-13');
 select grade_value,grade_date into l_value,l_date from grades
 where faculty_number='LESSON-STUDENT' and curriculum_id=university_api.curriculum_for('LESSON-STUDENT',l_d3);
 assert_true(l_value=5 and l_date=date '2026-06-13','GRADE_UPD corrects existing value and date');
 expect_error('begin grade_ins(''LESSON-STUDENT'','||l_d3||',2,date ''2026-06-14''); end;',
 -20061,'GRADE_INS refuses duplicate pair');
 select grade_value into l_value from grades where faculty_number='LESSON-STUDENT' and curriculum_id=university_api.curriculum_for('LESSON-STUDENT',l_d3);
 assert_true(l_value=5,'Refused INSERT does not overwrite grade');
 expect_error('begin grade_upd(''LESSON-STUDENT'',999999,4,date ''2026-06-14''); end;',
 -20141,'GRADE_UPD refuses absent curriculum');
 expect_error('begin grade_upd(''LESSON-STUDENT'','||l_d3||',2.5,date ''2026-06-14''); end;',
 -2291,'Standalone procedure rejects fractional grade');
 expect_error('begin grade_upd(''LESSON-STUDENT'','||l_d3||',5,null); end;',
 -1407,'Standalone procedure rejects NULL grade date');
 select grade_value,grade_date into l_value,l_date from grades
 where faculty_number='LESSON-STUDENT' and curriculum_id=university_api.curriculum_for('LESSON-STUDENT',l_d3);
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
 select count(*) into l_count from students; assert_true(l_count=20,'ROLLBACK restores twenty seed students');
 select count(*) into l_count from teachers; assert_true(l_count=6,'ROLLBACK restores six seed teachers');
 select count(*) into l_count from disciplines; assert_true(l_count=15,'ROLLBACK restores fifteen seed disciplines');
 select count(*) into l_count from grades; assert_true(l_count=64,'ROLLBACK restores sixty-four seed grades');
 select count(*) into l_count from specialties; assert_true(l_count=5,'ROLLBACK removes temporary lookup');
 select count(*) into l_count from user_errors; assert_true(l_count=0,'No Oracle compilation errors');
 dbms_output.put_line('LESSON_VALIDATION_PASSED: '||l_passed||' checks');
exception when others then rollback; raise;
end;
/

-- SOURCE: 16_many_teachers_validation.sql
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

-- SOURCE: 17_many_teachers_demo.sql
set define off
set serveroutput on
set long 1000000
set longchunksize 32767
set linesize 260
set pagesize 100
whenever sqlerror exit sql.sqlcode rollback
column discipline_name format a30
column teacher_name format a70
column average_grade format 990.00
prompt COMMITTED_SHARED_DISCIPLINES
select d.discipline_name,dt.teacher_count,dt.teacher_name
from disciplines d join v_discipline_teachers dt on dt.discipline_id=d.discipline_id
where dt.teacher_count>1 order by d.discipline_name;
prompt ASSIGN_AND_REMOVE_A_CO_TEACHER_THEN_ROLLBACK
declare d number;t number;
begin
 select min(discipline_id) into d from disciplines where discipline_name=unistr('\041c\0430\0442\0435\043c\0430\0442\0438\043a\0430');
 select teacher_id into t from teachers where email='teacher6@university.example';
 discipline_teacher_ins(d,t);
end;
/
select discipline_name,teacher_count,teacher_name,grade_value,average_grade
from v_academic_report where faculty_number='00010001' order by semester_no,discipline_name;
declare d number;t number;
begin
 select min(discipline_id) into d from disciplines where discipline_name=unistr('\041c\0430\0442\0435\043c\0430\0442\0438\043a\0430');
 select teacher_id into t from teachers where email='teacher6@university.example';
 discipline_teacher_del(d,t);
end;
/
rollback;
prompt MANY_TEACHERS_DEMO_ROLLED_BACK

-- SOURCE: 18_crud_all_tables.sql
-- C=INSERT, R=SELECT, U=UPDATE, D=DELETE: one actual operation of each kind
-- for all eleven tables. Protected tables are changed through UNIVERSITY_API.
-- Run with F5 in SQL Developer after installing the current 02_programs.sql.
-- No COMMIT or DDL. Own changes are rolled back; caller's earlier work is kept.
-- Sequences advance normally even when table changes are rolled back.
set define off
set serveroutput on size unlimited
whenever sqlerror exit sql.sqlcode rollback

declare
    l_checks pls_integer:=0;
    l_id number; l_year number; l_sem number; l_title number; l_specialty number;
    l_teacher number; l_other number; l_fixture_teacher number; l_discipline number; l_curriculum number; l_temp_specialty number;
    l_courses sys.odcinumberlist;
    l_grades university_api.t_grade_list;
    l_student varchar2(20):='CRUD_'||substr(rawtohex(sys_guid()),1,15);
    l_name varchar2(254); l_n number; l_term number;
    type t_names is table of varchar2(40) index by pls_integer;
    type t_snapshots is table of clob index by pls_integer;
    l_tables t_names; l_order t_names; l_before t_snapshots; l_after clob;
    procedure ok(p_test boolean,p_message varchar2) is
    begin
        if p_test is null or not p_test then raise_application_error(-20801,p_message); end if;
        l_checks:=l_checks+1;
        dbms_output.put_line('PASS: '||p_message);
    end;
    procedure snapshot_before is
    begin
        l_tables(1):='SPECIALTIES'; l_order(1):='specialty_id';
        l_tables(2):='ACADEMIC_TITLES'; l_order(2):='title_id';
        l_tables(3):='STUDY_YEARS'; l_order(3):='study_year_no';
        l_tables(4):='SEMESTERS'; l_order(4):='semester_no';
        l_tables(5):='GRADE_SCALE'; l_order(5):='grade_value';
        l_tables(6):='STUDENTS'; l_order(6):='faculty_number';
        l_tables(7):='TEACHERS'; l_order(7):='teacher_id';
        l_tables(8):='DISCIPLINES'; l_order(8):='discipline_id';
        l_tables(9):='DISCIPLINE_TEACHERS'; l_order(9):='curriculum_id,teacher_id';
        l_tables(10):='GRADES'; l_order(10):='faculty_number,curriculum_id';
        l_tables(11):='CURRICULUM'; l_order(11):='curriculum_id';
        for i in 1..11 loop
            l_before(i):=dbms_xmlgen.getxml('select * from '||l_tables(i)||' order by '||l_order(i));
        end loop;
    end;
begin
    if user<>'UNIVERSITY_PROJECT' then raise_application_error(-20000,'Use UNIVERSITY_PROJECT.'); end if;
    savepoint crud_demo_start;
    lock table students,teachers,disciplines,discipline_teachers,grades,
        specialties,academic_titles,study_years,semesters,grade_scale,curriculum in exclusive mode nowait;
    snapshot_before;
    select min(specialty_id) into l_specialty from specialties;
    select min(title_id) into l_title from academic_titles;
    select min(study_year_no) into l_year from study_years;
    select min(semester_no) into l_sem from semesters;
    select min(teacher_id) into l_teacher from teachers;
    select discipline_id bulk collect into l_courses from
        (select discipline_id from disciplines order by discipline_id) where rownum<=3;
    if l_courses.count<3 or l_teacher is null then
        raise_application_error(-20802,'Load the supplied sample data first.');
    end if;

    -- SPECIALTIES: INSERT / SELECT / UPDATE / DELETE.
    insert into specialties(specialty_name) values('CRUD specialty') returning specialty_id into l_id;
    ok(sql%rowcount=1,'SPECIALTIES C');
    select specialty_name into l_name from specialties where specialty_id=l_id;
    ok(l_name='CRUD specialty','SPECIALTIES R');
    update specialties set specialty_name='CRUD specialty updated' where specialty_id=l_id;
    select specialty_name into l_name from specialties where specialty_id=l_id;
    ok(l_name='CRUD specialty updated','SPECIALTIES U');
    delete from specialties where specialty_id=l_id;
    ok(sql%rowcount=1,'SPECIALTIES D');

    -- ACADEMIC_TITLES.
    insert into academic_titles(title_name) values('CRUD title') returning title_id into l_id;
    ok(sql%rowcount=1,'ACADEMIC_TITLES C');
    select title_name into l_name from academic_titles where title_id=l_id;
    ok(l_name='CRUD title','ACADEMIC_TITLES R');
    update academic_titles set title_name='CRUD title updated' where title_id=l_id;
    select title_name into l_name from academic_titles where title_id=l_id;
    ok(l_name='CRUD title updated','ACADEMIC_TITLES U');
    delete from academic_titles where title_id=l_id;
    ok(sql%rowcount=1,'ACADEMIC_TITLES D');

    -- STUDY_YEARS: use a free positive natural key.
    select max(study_year_no)+1 into l_id from study_years;
    insert into study_years values(l_id,'CRUD year');
    ok(sql%rowcount=1,'STUDY_YEARS C');
    select year_label into l_name from study_years where study_year_no=l_id;
    ok(l_name='CRUD year','STUDY_YEARS R');
    update study_years set year_label='CRUD year updated' where study_year_no=l_id;
    select year_label into l_name from study_years where study_year_no=l_id;
    ok(l_name='CRUD year updated','STUDY_YEARS U');
    delete from study_years where study_year_no=l_id;
    ok(sql%rowcount=1,'STUDY_YEARS D');

    -- SEMESTERS: an unused fixture year keeps the year/term formula valid.
    insert into study_years values(l_id,'CRUD semester fixture');
    l_n:=2*(l_id-1)+1;
    insert into semesters values(l_n,l_id,1);
    ok(sql%rowcount=1,'SEMESTERS C');
    select term_no into l_term from semesters where semester_no=l_n;
    ok(l_term=1,'SEMESTERS R');
    update semesters set semester_no=l_n+1,term_no=2 where semester_no=l_n;
    select term_no into l_term from semesters where semester_no=l_n+1;
    ok(l_term=2,'SEMESTERS U');
    delete from semesters where semester_no=l_n+1;
    ok(sql%rowcount=1,'SEMESTERS D');
    delete from study_years where study_year_no=l_id;

    -- GRADE_SCALE already contains all five legal values (2..6).
    -- In a savepoint, move references 6 -> 5, free 6, and demonstrate CRUD.
    -- Restore BOTH the original scale row and grades immediately afterwards.
    savepoint crud_scale_fixture;
    for g in (select g.faculty_number,c.discipline_id,g.grade_date from grades g join curriculum c on c.curriculum_id=g.curriculum_id where g.grade_value=6) loop
        university_api.set_grade(g.faculty_number,g.discipline_id,5,g.grade_date);
    end loop;
    delete from grade_scale where grade_value=6;
    insert into grade_scale values(6,'CRUD excellent',1);
    ok(sql%rowcount=1,'GRADE_SCALE C');
    select grade_label into l_name from grade_scale where grade_value=6;
    ok(l_name='CRUD excellent','GRADE_SCALE R');
    update grade_scale set grade_label='CRUD excellent updated' where grade_value=6;
    select grade_label into l_name from grade_scale where grade_value=6;
    ok(l_name='CRUD excellent updated','GRADE_SCALE U');
    delete from grade_scale where grade_value=6;
    ok(sql%rowcount=1,'GRADE_SCALE D');
    rollback to crud_scale_fixture;

    -- TEACHERS: create a teacher with two existing courses, then remove him.
    university_api.create_teacher_for_disciplines('CRUD',null,'Teacher',l_title,
        '+359000009999','crud.teacher@university.example',
        sys.odcinumberlist(l_courses(1),l_courses(2)),l_id);
    select count(*) into l_n from teachers where teacher_id=l_id;
    ok(l_n=1,'TEACHERS C');
    select first_name into l_name from teachers where teacher_id=l_id;
    ok(l_name='CRUD','TEACHERS R');
    university_api.update_teacher(l_id,'CRUD updated',null,'Teacher',l_title,
        '+359000009998','crud.teacher.updated@university.example');
    select first_name into l_name from teachers where teacher_id=l_id;
    ok(l_name='CRUD updated','TEACHERS U');
    university_api.delete_teacher(l_id);
    select count(*) into l_n from teachers where teacher_id=l_id;
    ok(l_n=0,'TEACHERS D');

    -- DISCIPLINES: no enrolled students; teacher keeps his original courses.
    university_api.add_discipline('CRUD discipline',l_sem,l_teacher,l_discipline);
    select count(*) into l_n from disciplines where discipline_id=l_discipline;
    ok(l_n=1,'DISCIPLINES C');
    select discipline_name into l_name from disciplines where discipline_id=l_discipline;
    ok(l_name='CRUD discipline','DISCIPLINES R');
    university_api.update_discipline(l_discipline,'CRUD discipline updated');
    select discipline_name into l_name from disciplines where discipline_id=l_discipline;
    ok(l_name='CRUD discipline updated','DISCIPLINES U');
    university_api.delete_discipline(l_discipline);
    select count(*) into l_n from disciplines where discipline_id=l_discipline;
    ok(l_n=0,'DISCIPLINES D');

    -- STUDENTS: create together with two mandatory grades.
    l_grades(1).discipline_id:=l_courses(1); l_grades(1).grade_value:=5;
    l_grades(1).grade_date:=date '2026-10-13';
    l_grades(2).discipline_id:=l_courses(2); l_grades(2).grade_value:=6;
    l_grades(2).grade_date:=date '2026-10-13';
    university_api.create_student(l_student,'CRUD',null,'Student',l_specialty,l_year,
        'crud.student@university.example',l_grades);
    select count(*) into l_n from students where faculty_number=l_student;
    ok(l_n=1,'STUDENTS C');
    select first_name into l_name from students where faculty_number=l_student;
    ok(l_name='CRUD','STUDENTS R');
    university_api.update_student(l_student,'CRUD updated',null,'Student',l_specialty,l_year,
        'crud.student.updated@university.example');
    select first_name into l_name from students where faculty_number=l_student;
    ok(l_name='CRUD updated','STUDENTS U');

    -- GRADES: third grade can be deleted while the student retains two.
    grade_ins(l_student,l_courses(3),4,date '2026-10-13');
    select count(*) into l_n from grades where faculty_number=l_student and curriculum_id=university_api.curriculum_for(l_student,l_courses(3));
    ok(l_n=1,'GRADES C');
    select grade_value into l_n from grades where faculty_number=l_student and curriculum_id=university_api.curriculum_for(l_student,l_courses(3));
    ok(l_n=4,'GRADES R');
    grade_upd(l_student,l_courses(3),5,date '2026-10-14');
    select grade_value into l_n from grades where faculty_number=l_student and curriculum_id=university_api.curriculum_for(l_student,l_courses(3));
    ok(l_n=5,'GRADES U');
    university_api.delete_grade(l_student,l_courses(3));
    select count(*) into l_n from grades where faculty_number=l_student and curriculum_id=university_api.curriculum_for(l_student,l_courses(3));
    ok(l_n=0,'GRADES D');
    university_api.delete_student(l_student);
    select count(*) into l_n from students where faculty_number=l_student;
    ok(l_n=0,'STUDENTS D');

    -- DISCIPLINE_TEACHERS: create an extra assignment, update its teacher,
    -- then delete it. Every course always keeps its original teacher(s).
    university_api.create_teacher_for_disciplines('CRUD',null,'Assignment fixture',l_title,
        '+359000009997','crud.assignment@university.example',
        sys.odcinumberlist(l_courses(1),l_courses(2)),l_fixture_teacher);
    select min(teacher_id) into l_other from teachers t
    where t.teacher_id<>l_fixture_teacher and not exists
        (select 1 from discipline_teachers dt where dt.teacher_id=t.teacher_id and dt.curriculum_id=(select curriculum_id from curriculum where specialty_id=l_specialty and discipline_id=l_courses(3)));
    if l_other is null then raise_application_error(-20802,'No free co-teacher for this demonstration.'); end if;
    university_api.assign_teacher(l_courses(3),l_fixture_teacher);
    select count(*) into l_n from discipline_teachers where curriculum_id=(select curriculum_id from curriculum where specialty_id=l_specialty and discipline_id=l_courses(3)) and teacher_id=l_fixture_teacher;
    ok(l_n=1,'DISCIPLINE_TEACHERS C');
    select teacher_id into l_n from discipline_teachers where curriculum_id=(select curriculum_id from curriculum where specialty_id=l_specialty and discipline_id=l_courses(3)) and teacher_id=l_fixture_teacher;
    ok(l_n=l_fixture_teacher,'DISCIPLINE_TEACHERS R');
    university_api.replace_teacher(l_courses(3),l_fixture_teacher,l_other);
    select count(*) into l_n from discipline_teachers where curriculum_id=(select curriculum_id from curriculum where specialty_id=l_specialty and discipline_id=l_courses(3)) and teacher_id=l_other;
    ok(l_n=1,'DISCIPLINE_TEACHERS U');
    university_api.unassign_teacher(l_courses(3),l_other);
    select count(*) into l_n from discipline_teachers where curriculum_id=(select curriculum_id from curriculum where specialty_id=l_specialty and discipline_id=l_courses(3)) and teacher_id=l_other;
    ok(l_n=0,'DISCIPLINE_TEACHERS D');
    university_api.delete_teacher(l_fixture_teacher);


    -- CURRICULUM: a course may have different semesters in different specialties.
    insert into specialties(specialty_name) values('CRUD curriculum fixture') returning specialty_id into l_temp_specialty;
    university_api.add_curriculum(l_temp_specialty,l_courses(1),1,l_teacher,l_curriculum);
    select count(*) into l_n from curriculum where curriculum_id=l_curriculum;
    ok(l_n=1,'CURRICULUM C');
    select semester_no into l_n from curriculum where curriculum_id=l_curriculum;
    ok(l_n=1,'CURRICULUM R');
    university_api.update_curriculum(l_curriculum,2);
    select semester_no into l_n from curriculum where curriculum_id=l_curriculum;
    ok(l_n=2,'CURRICULUM U');
    university_api.delete_curriculum(l_curriculum);
    select count(*) into l_n from curriculum where curriculum_id=l_curriculum;
    ok(l_n=0,'CURRICULUM D');
    delete from specialties where specialty_id=l_temp_specialty;

    university_api.validate_rules;
    ok(l_checks=44,'44 CRUD operations actually succeeded');
    rollback to crud_demo_start;
    for i in 1..11 loop
        l_after:=dbms_xmlgen.getxml('select * from '||l_tables(i)||' order by '||l_order(i));
        ok(dbms_lob.compare(l_before(i),l_after)=0,l_tables(i)||' all rows and fields restored');
        dbms_lob.freetemporary(l_before(i)); dbms_lob.freetemporary(l_after);
    end loop;
    dbms_output.put_line('CRUD_ALL_TABLES_PASSED: 44 operations; 11 tables; 56 checks; own changes rolled back');
exception when others then
    rollback to crud_demo_start;
    raise;
end;
/

-- SOURCE: 19_crud_validation.sql
-- Negative/atomicity checks for the four new DELETE operations.
-- Own fixtures only; no COMMIT; all test changes are rolled back.
set define off
set serveroutput on size unlimited
whenever sqlerror exit sql.sqlcode rollback
declare
    l_checks pls_integer:=0;
    l_student varchar2(20):='CRUD_FAIL_'||substr(rawtohex(sys_guid()),1,10);
    l_inputs university_api.t_discipline_list;
    l_grades university_api.t_grade_list;
    l_ids sys.odcinumberlist;
    l_teacher number; l_original_teacher number;
    l_title number; l_specialty number; l_year number; l_sem number;
    l_n number; l_name varchar2(60); l_base varchar2(200);
    procedure ok(p_test boolean,p_message varchar2) is
    begin
        if p_test is null or not p_test then raise_application_error(-20811,p_message); end if;
        l_checks:=l_checks+1; dbms_output.put_line('PASS: '||p_message);
    end;
    procedure rejects(p_sql varchar2,p_code number,p_message varchar2) is
        l_actual number:=0;
    begin
        begin execute immediate p_sql; exception when others then l_actual:=sqlcode; end;
        ok(l_actual=p_code,p_message||' (SQLCODE '||l_actual||')');
    end;
    function core_counts return varchar2 is r varchar2(200);
    begin
        select (select count(*) from students)||'/'||(select count(*) from teachers)||'/'||
            (select count(*) from disciplines)||'/'||(select count(*) from grades)||'/'||
            (select count(*) from discipline_teachers)||'/'||(select count(*) from curriculum) into r from dual;
        return r;
    end;
begin
    if user<>'UNIVERSITY_PROJECT' then raise_application_error(-20000,'Use UNIVERSITY_PROJECT.'); end if;
    savepoint crud_validation_start;
    lock table students,teachers,disciplines,curriculum,discipline_teachers,grades in exclusive mode nowait;
    l_base:=core_counts;
    rejects('begin university_api.delete_student('''||l_student||'''); end;',-20043,'Missing student rejected');
    rejects('begin university_api.delete_teacher(-1); end;',-20045,'Missing teacher rejected');
    rejects('begin university_api.delete_discipline(-1); end;',-20046,'Missing discipline rejected');
    rejects('begin university_api.delete_grade('''||l_student||''',-1); end;',-20141,'Missing student curriculum rejected');
    rejects('delete from grades where faculty_number='''||l_student||'''',-20020,'Direct DELETE guard stays active');
    select min(title_id) into l_title from academic_titles;
    select min(specialty_id) into l_specialty from specialties;
    select min(study_year_no) into l_year from study_years;
    select min(semester_no) into l_sem from semesters;
    select min(teacher_id) into l_original_teacher from teachers;
    for i in 1..3 loop
        l_inputs(i).discipline_name:='CRUD delete fixture '||i;
        l_inputs(i).semester_no:=l_sem;
    end loop;
    university_api.create_teacher('CRUD',null,'Delete fixture',l_title,'+359000009990',
        'crud.delete@university.example',l_inputs,l_teacher,l_ids);
    for i in 1..2 loop
        l_grades(i).discipline_id:=l_ids(i); l_grades(i).grade_value:=5;
        l_grades(i).grade_date:=date '2026-10-13';
    end loop;
    university_api.create_student(l_student,'CRUD',null,'Delete fixture',l_specialty,l_year,
        'crud.delete.student@university.example',l_grades);
    university_api.update_student(l_student,'Prior change',null,'Delete fixture',l_specialty,l_year,
        'crud.delete.student@university.example');
    rejects('begin university_api.delete_grade('''||l_student||''','||l_ids(1)||'); end;',
        -20042,'Student cannot lose his second grade');
    select count(*) into l_n from grades where faculty_number=l_student;
    ok(l_n=2,'Failed grade DELETE preserves both grades');
    select first_name into l_name from students where faculty_number=l_student;
    ok(l_name='Prior change','Failed operation keeps caller prior changes');
    rejects('begin university_api.delete_discipline('||l_ids(1)||'); end;',
        -20042,'Discipline DELETE checks affected students');
    select count(*) into l_n from disciplines d join curriculum c on c.discipline_id=d.discipline_id join discipline_teachers dt on dt.curriculum_id=c.curriculum_id
        join grades g on g.curriculum_id=c.curriculum_id
        where d.discipline_id=l_ids(1) and dt.teacher_id=l_teacher and g.faculty_number=l_student;
    ok(l_n=1,'Failed discipline DELETE restores course, assignment and grade');
    rejects('begin university_api.delete_teacher('||l_teacher||'); end;',
        -2292,'Teacher referenced by grades cannot be deleted');
    select count(*) into l_n from discipline_teachers where teacher_id=l_teacher;
    ok(l_n=3,'Failed teacher DELETE restores all assignments');
    university_api.set_grade(l_student,l_ids(3),6,date '2026-10-13');
    university_api.delete_discipline(l_ids(1));
    select count(*) into l_n from disciplines where discipline_id=l_ids(1);
    ok(l_n=0,'Allowed discipline DELETE removes selected course');
    select count(*) into l_n from grades where faculty_number=l_student;
    ok(l_n=2,'Allowed discipline DELETE retains two student grades');
    select count(*) into l_n from discipline_teachers where teacher_id=l_teacher;
    ok(l_n=2,'Allowed discipline DELETE retains two teacher courses');
    rejects('begin university_api.delete_discipline('||l_ids(2)||'); end;',
        -20041,'Teacher cannot lose his second discipline');
    select count(*) into l_n from disciplines d join curriculum c on c.discipline_id=d.discipline_id join grades g on g.curriculum_id=c.curriculum_id
        where d.discipline_id=l_ids(2) and g.faculty_number=l_student;
    ok(l_n=1,'Rejected second-course DELETE restores related rows');
    university_api.delete_student(l_student);
    select (select count(*) from students where faculty_number=l_student)+
        (select count(*) from grades where faculty_number=l_student) into l_n from dual;
    ok(l_n=0,'Student DELETE removes only its dependent grade rows');
    university_api.assign_teacher(l_ids(2),l_original_teacher);
    university_api.assign_teacher(l_ids(3),l_original_teacher);
    university_api.delete_teacher(l_teacher);
    select (select count(*) from teachers where teacher_id=l_teacher)+
        (select count(*) from discipline_teachers where teacher_id=l_teacher) into l_n from dual;
    select count(*) into l_sem from disciplines where discipline_id in(l_ids(2),l_ids(3));
    ok(l_n=0 and l_sem=2,'Teacher DELETE preserves courses with another teacher');
    rollback to crud_validation_start;
    university_api.validate_rules;
    ok(core_counts=l_base and not university_api.write_allowed,'Baseline restored and write guard closed');
    if l_checks<>20 then raise_application_error(-20812,'Expected exactly 20 CRUD safety checks.'); end if;
    dbms_output.put_line('CRUD_VALIDATION_PASSED: 20 checks');
exception when others then rollback to crud_validation_start; raise;
end;
/

-- SOURCE: 22_grade_teacher_validation.sql
-- Structural and data-integrity checks complementing real-login JDBC tests.
set define off
set serveroutput on size unlimited
whenever sqlerror exit sql.sqlcode rollback
declare
 n number; passed number:=0; before_xml clob; after_xml clob; code number;
 procedure ok(test boolean,message varchar2) is
 begin
  if test is null or not test then raise_application_error(-20120,message);end if;
  passed:=passed+1;dbms_output.put_line('PASS: '||message);
 end;
begin
 savepoint grade_teacher_validation;
 select count(*) into n from user_tab_columns where table_name='GRADES' and column_name='TEACHER_ID' and nullable='N';
 ok(n=1,'GRADES.teacher_id is mandatory');
 select count(*) into n from user_constraints where table_name='GRADES' and constraint_name='GRADES_ASSIGNMENT_FK' and status='ENABLED' and validated='VALIDATED';
 ok(n=1,'Composite assignment FK is enabled and validated');
 select count(*) into n from user_cons_columns where constraint_name='GRADES_ASSIGNMENT_FK'
 and ((column_name='CURRICULUM_ID' and position=1) or (column_name='TEACHER_ID' and position=2));
 ok(n=2,'Composite FK column order is discipline then teacher');
 select count(*) into n from user_constraints fk join user_constraints pk on pk.constraint_name=fk.r_constraint_name
 where fk.constraint_name='GRADES_ASSIGNMENT_FK' and pk.table_name='DISCIPLINE_TEACHERS';
 ok(n=1,'FK points to DISCIPLINE_TEACHERS, not just TEACHERS');
 select count(*) into n from user_cons_columns where constraint_name='GRADES_PK'
 and ((column_name='FACULTY_NUMBER' and position=1) or(column_name='CURRICULUM_ID' and position=2));
 ok(n=2,'One grade per student-course remains the primary key');
 select count(*) into n from user_cons_columns where constraint_name='GRADES_PK' and column_name='TEACHER_ID';
 ok(n=0,'Teacher is not added to the grade primary key');
 select count(*) into n from grades g where not exists(select 1 from discipline_teachers dt where dt.curriculum_id=g.curriculum_id and dt.teacher_id=g.teacher_id);
 ok(n=0,'Every grade belongs to a valid teaching assignment');
 select count(*) into n from grades;
 ok(n=64,'All sixty-four sample grades retained');
 select count(*) into n from v_academic_report;
 ok(n=64,'Academic report still has one row per grade');
 select count(*) into n from v_academic_report where grading_teacher_id is null or grading_teacher_name is null;
 ok(n=0,'Academic report identifies the grading teacher');
 select count(*) into n from user_objects where status<>'VALID';
 ok(n=0,'All schema objects are valid');
 select count(*) into n from user_errors;
 ok(n=0,'No compilation errors');
 before_xml:=dbms_xmlgen.getxml('select * from grades order by faculty_number,curriculum_id');
 code:=0;
 begin university_api.set_grade('00010001',1,4,date '2026-10-20',3);exception when others then code:=sqlcode;end;
 ok(code=-2291,'Even the owner cannot store an unassigned teacher in a grade');
 code:=0;
 begin university_api.unassign_teacher(1,1);exception when others then code:=sqlcode;end;
 ok(code=-2292,'Assignment referenced by grades cannot be removed');
 after_xml:=dbms_xmlgen.getxml('select * from grades order by faculty_number,curriculum_id');
 ok(dbms_lob.compare(before_xml,after_xml)=0,'Rejected operations preserve all grade values, dates and authors');
 ok(not university_api.write_allowed,'Write guard is closed after rejected operations');
 rollback to grade_teacher_validation;
 dbms_output.put_line('GRADE_TEACHER_VALIDATION_PASSED: '||passed||' checks');
exception when others then rollback to grade_teacher_validation;raise;
end;
/

-- SOURCE: 23_curriculum_validation.sql
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

-- SOURCE: 08_schema_snapshot.sql
set define off
set serveroutput on
set heading off
set feedback off
set pagesize 0
set linesize 32767
set trimout on
set trimspool on
select 'TABLE|'||table_name from user_tables order by table_name;
select 'COLUMN|'||table_name||'|'||column_name||'|'||data_type||'|'||
       nvl(to_char(char_length),'')||'|'||nvl(char_used,'')||'|'||nullable||'|'||
       nvl(to_char(data_precision),'')||'|'||nvl(to_char(data_scale),'')
from user_tab_columns where table_name in (select table_name from user_tables)
order by table_name,column_id;
select 'KEY|'||c.table_name||'|'||c.constraint_name||'|'||c.constraint_type||'|'||
       listagg(cc.column_name,',') within group(order by cc.position)
from user_constraints c join user_cons_columns cc on cc.constraint_name=c.constraint_name
where c.constraint_type in('P','U') group by c.table_name,c.constraint_name,c.constraint_type
order by c.table_name,c.constraint_name;
select 'FK|'||c.table_name||'|'||c.constraint_name||'|'||
       listagg(cc.column_name,',') within group(order by cc.position)||'|'||
       r.table_name||'|'||listagg(rc.column_name,',') within group(order by cc.position)
from user_constraints c
join user_cons_columns cc on cc.constraint_name=c.constraint_name
join user_constraints r on r.constraint_name=c.r_constraint_name and c.r_owner=user
join user_cons_columns rc on rc.constraint_name=r.constraint_name and rc.position=cc.position
where c.constraint_type='R'
group by c.table_name,c.constraint_name,r.table_name
order by c.table_name,c.constraint_name;
declare
begin
 for r in (select table_name,constraint_name,search_condition from user_constraints
           where constraint_type='C' order by table_name,constraint_name) loop
  dbms_output.put_line('CHECK|'||r.table_name||'|'||r.constraint_name||'|'||replace(replace(r.search_condition,chr(10),' '),chr(13),' '));
 end loop;
end;
/
select 'OBJECT|'||object_type||'|'||object_name||'|'||status from user_objects
where object_type in ('PACKAGE','PACKAGE BODY','PROCEDURE','TRIGGER','VIEW','SEQUENCE')
order by object_type,object_name;

prompt FULL_BUILD_COMPLETED
