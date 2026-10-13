-- Run only in UNIVERSITY_PROJECT. SQL Developer: Run Script (F5).
set echo off
set feedback on
set serveroutput on
set define off
set pagesize 100
set linesize 180
whenever oserror exit failure rollback
whenever sqlerror exit sql.sqlcode rollback

declare
    l_count number;
begin
    if user <> 'UNIVERSITY_PROJECT' then
        raise_application_error(-20000, 'Use the UNIVERSITY_PROJECT schema.');
    end if;
    select count(*) into l_count from user_objects
    where object_name in ('PBD_ENV_PROBE','PBD_ENV_SEQ','PBD_ENV_BI',
                          'PBD_ENV_VIEW','PBD_ENV_SET_GRADE');
    if l_count > 0 then
        raise_application_error(-20001, 'Probe names already exist; inspect before retrying.');
    end if;
end;
/
select user connected_user, sys_context('USERENV','SERVICE_NAME') service_name from dual;
create table pbd_env_probe (
    probe_id number constraint pbd_env_probe_pk primary key,
    label varchar2(100 char) not null,
    grade number(1) not null constraint pbd_env_grade_ck check (grade between 2 and 6)
);
create sequence pbd_env_seq start with 1 increment by 1 nocache;
create or replace trigger pbd_env_bi
before insert on pbd_env_probe for each row
begin
    if :new.probe_id is null then
        :new.probe_id := pbd_env_seq.nextval;
    end if;
end;
/
create view pbd_env_view as select probe_id, label, grade from pbd_env_probe;
create or replace procedure pbd_env_set_grade(p_grade in number) as
begin
    update pbd_env_probe set grade = p_grade where probe_id = 1;
end;
/
insert into pbd_env_probe (label,grade)
values (unistr('\0423\043D\0438\0432\0435\0440\0441\0438\0442\0435\0442'),4);
commit;
begin
    pbd_env_set_grade(5);
end;
/
rollback;
declare
    l_count number;
begin
    select count(*) into l_count from pbd_env_view
    where probe_id = 1 and grade = 4
      and label = unistr('\0423\043D\0438\0432\0435\0440\0441\0438\0442\0435\0442');
    if l_count <> 1 then
        raise_application_error(-20002, 'Unicode, trigger, view or rollback test failed.');
    end if;
    dbms_output.put_line('PASS: table, sequence, trigger, view, Unicode, INSERT, COMMIT and ROLLBACK');
end;
/
begin
    pbd_env_set_grade(5);
end;
/
commit;
declare
    l_count number := 0;
begin
    for r in (select probe_id,grade from pbd_env_view) loop
        if r.probe_id <> 1 or r.grade <> 5 then
            raise_application_error(-20003, 'Procedure or cursor test failed.');
        end if;
        l_count := l_count + 1;
    end loop;
    if l_count <> 1 then
        raise_application_error(-20004, 'Unexpected cursor row count.');
    end if;
    begin
        pbd_env_set_grade(7);
        raise_application_error(-20005, 'CHECK constraint did not reject grade 7.');
    exception
        when others then
            if sqlcode <> -2290 then raise; end if;
    end;
    select count(*) into l_count from user_errors
    where name in ('PBD_ENV_BI','PBD_ENV_SET_GRADE');
    if l_count <> 0 then
        raise_application_error(-20006, 'PL/SQL compilation errors found.');
    end if;
    dbms_output.put_line('PASS: procedure, UPDATE, cursor, CHECK constraint and PL/SQL compilation');
end;
/
drop procedure pbd_env_set_grade;
drop view pbd_env_view;
drop trigger pbd_env_bi;
drop sequence pbd_env_seq;
drop table pbd_env_probe purge;
declare
    l_count number;
begin
    select count(*) into l_count from user_objects
    where object_name in ('PBD_ENV_PROBE','PBD_ENV_SEQ','PBD_ENV_BI',
                          'PBD_ENV_VIEW','PBD_ENV_SET_GRADE');
    if l_count <> 0 then
        raise_application_error(-20007, 'Probe cleanup failed.');
    end if;
    dbms_output.put_line('PASS: probe objects removed');
end;
/
prompt ENVIRONMENT_SMOKE_TEST_OK
exit success
