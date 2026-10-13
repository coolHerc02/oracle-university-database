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
            (select count(*) from discipline_teachers) into r from dual;
        return r;
    end;
begin
    if user<>'UNIVERSITY_PROJECT' then raise_application_error(-20000,'Use UNIVERSITY_PROJECT.'); end if;
    savepoint crud_validation_start;
    lock table students,teachers,disciplines,discipline_teachers,grades in exclusive mode nowait;
    l_base:=core_counts;
    rejects('begin university_api.delete_student('''||l_student||'''); end;',-20043,'Missing student rejected');
    rejects('begin university_api.delete_teacher(-1); end;',-20045,'Missing teacher rejected');
    rejects('begin university_api.delete_discipline(-1); end;',-20046,'Missing discipline rejected');
    rejects('begin university_api.delete_grade('''||l_student||''',-1); end;',-20062,'Missing grade rejected');
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
    select count(*) into l_n from disciplines d join discipline_teachers dt on dt.discipline_id=d.discipline_id
        join grades g on g.discipline_id=d.discipline_id
        where d.discipline_id=l_ids(1) and dt.teacher_id=l_teacher and g.faculty_number=l_student;
    ok(l_n=1,'Failed discipline DELETE restores course, assignment and grade');
    rejects('begin university_api.delete_teacher('||l_teacher||'); end;',
        -20047,'Last teacher of a discipline cannot be deleted');
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
    select count(*) into l_n from disciplines d join grades g on g.discipline_id=d.discipline_id
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
