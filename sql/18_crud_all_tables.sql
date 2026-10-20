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
