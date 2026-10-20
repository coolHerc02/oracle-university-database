"""Assemble 11-table build and the one-time migration from release 2."""
from pathlib import Path
import re
R=Path(__file__).resolve().parents[1]
def read(n):return (R/'sql'/n).read_text(encoding='utf-8')
order=['01_schema.sql','02_programs.sql','10_standalone_programs.sql','20_teacher_grading.sql',
 '03_seed_data.sql','25_curriculum_example.sql','07_validation.sql','11_lesson_demo.sql',
 '12_lesson_validation.sql','16_many_teachers_validation.sql','17_many_teachers_demo.sql',
 '18_crud_all_tables.sql','19_crud_validation.sql','22_grade_teacher_validation.sql',
 '23_curriculum_validation.sql','08_schema_snapshot.sql']
(R/'sql/13_build.sql').write_text('\n'.join('-- SOURCE: '+n+'\n'+read(n) for n in order)+'\nprompt FULL_BUILD_COMPLETED\n',encoding='utf-8')
schema=read('01_schema.sql');curr=re.search(r'create table curriculum \([\s\S]*?\n\);',schema,re.I).group(0)
trigger=re.search(r'create or replace trigger curriculum_bi[\s\S]*?\n/',schema,re.I).group(0)
programs='\n'.join(read(n) for n in ['02_programs.sql','10_standalone_programs.sql','20_teacher_grading.sql'])
migration='''-- One-time migration from the 10-table grading schema. Maintenance window.
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
'''+curr+'''
create sequence curriculum_seq start with 1 increment by 1 nocache;
'''+trigger+'''
alter table discipline_teachers add(curriculum_id number);
alter table grades add(curriculum_id number);
alter table grades drop constraint grades_assignment_fk;
alter table discipline_teachers drop constraint discipline_teachers_pk;
'''+programs+'''
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
'''
(R/'sql/24_migrate_curriculum.sql').write_text(migration,encoding='utf-8')
ddl=schema[schema.index('create table specialties'):schema.index('create or replace trigger curriculum_bi')]
ddl+=schema[schema.index('comment on table specialties'):schema.index('prompt UNIVERSITY_SCHEMA_READY')]
(R/'models/university_import.sql').write_text(ddl,encoding='utf-8')
print('ASSEMBLED_CURRENT_CURRICULUM_BUILD_AND_MIGRATION')
