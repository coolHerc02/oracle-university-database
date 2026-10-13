"""Assemble self-contained fresh-build and data-preserving migration scripts."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
def read(n):return (ROOT/'sql'/n).read_text(encoding='utf-8')
order=['01_schema.sql','02_programs.sql','10_standalone_programs.sql','03_seed_data.sql',
 '04_data_corrections.sql','05_search.sql','06_reports.sql','07_validation.sql','09_sample_data.sql',
 '11_lesson_demo.sql','12_lesson_validation.sql','16_many_teachers_validation.sql',
 '17_many_teachers_demo.sql','18_crud_all_tables.sql','19_crud_validation.sql','08_schema_snapshot.sql']
build='-- Self-contained fresh build. Run only in an empty UNIVERSITY_PROJECT.\n'
for n in order:build+='\n-- SOURCE: '+n+'\n'+read(n)+'\n'
build+='\nprompt FULL_BUILD_COMPLETED\n'
(ROOT/'sql/13_build.sql').write_text(build,encoding='utf-8')
junction=re.search(r'create table discipline_teachers \([\s\S]*?\n\);',read('01_schema.sql'),re.I).group(0)
migration="""-- Data-preserving 1:N to M:N migration for an existing UNIVERSITY_PROJECT.
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
"""
migration+=junction+"""
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
"""
migration+='\n-- Recreate dependent views, package, guards and procedures.\n'+read('02_programs.sql')+'\n'+read('10_standalone_programs.sql')
migration+="""
-- Add two shared teaching examples to the supplied seed data, when present.
declare d number; t number; n number;
begin
 select min(discipline_id) into d from disciplines where discipline_name=unistr('\\041c\\0430\\0442\\0435\\043c\\0430\\0442\\0438\\043a\\0430');
 select min(teacher_id) into t from teachers where email='teacher2@university.example';
 if d is not null and t is not null then
  select count(*) into n from discipline_teachers where discipline_id=d and teacher_id=t;
  if n=0 then university_api.assign_teacher(d,t); end if;
 end if;
 select min(discipline_id) into d from disciplines where discipline_name=unistr('\\0411\\0430\\0437\\0438 \\043e\\0442 \\0434\\0430\\043d\\043d\\0438');
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
"""
(ROOT/'sql/15_migrate_many_teachers.sql').write_text(migration,encoding='utf-8')
# Modeler import receives physical DDL without SQL*Plus commands/PLSQL programs.
schema=read('01_schema.sql');start=schema.index('create table specialties')
ddl=schema[start:schema.index('create or replace trigger specialties_bi')]
ddl+=schema[schema.index('comment on table specialties'):schema.index('prompt UNIVERSITY_SCHEMA_READY')]
(ROOT/'models/university_import.sql').write_text(ddl,encoding='utf-8')
print('ASSEMBLED: fresh build, migration and Data Modeler import DDL')

