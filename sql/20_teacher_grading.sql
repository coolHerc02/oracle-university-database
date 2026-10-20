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
