"""Current build; older migration scripts remain frozen release artifacts."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def read(n):return (R/'sql'/n).read_text(encoding='utf-8')
order=['01_schema.sql','02_programs.sql','10_standalone_programs.sql','20_teacher_grading.sql','03_seed_data.sql','25_curriculum_example.sql','07_validation.sql','11_lesson_demo.sql','12_lesson_validation.sql','16_many_teachers_validation.sql','17_many_teachers_demo.sql','18_crud_all_tables.sql','19_crud_validation.sql','22_grade_teacher_validation.sql','23_curriculum_validation.sql']
if (R/'sql/34_cursor_procedures_each_table.sql').exists():order.insert(order.index('03_seed_data.sql'),'34_cursor_procedures_each_table.sql')
if (R/'sql/27_academic_year_validation.sql').exists():order.append('27_academic_year_validation.sql')
if (R/'sql/31_teacher_select_rules_validation.sql').exists():order.append('31_teacher_select_rules_validation.sql')
if (R/'sql/36_cursor_procedures_validation.sql').exists():order.append('36_cursor_procedures_validation.sql')
order.append('08_schema_snapshot.sql')
(R/'sql/13_build.sql').write_text('\n'.join('-- SOURCE: '+n+'\n'+read(n) for n in order)+'\nprompt FULL_BUILD_COMPLETED\n',encoding='utf-8',newline='\n')
sql='''-- One-time upgrade from the eleven-table curriculum release.
-- Back up first: Oracle DDL commits implicitly. Existing data are preserved.
set define off
set serveroutput on
whenever sqlerror exit sql.sqlcode rollback
declare n number;
begin
 if user<>'UNIVERSITY_PROJECT' then raise_application_error(-20000,'Use UNIVERSITY_PROJECT.');end if;
 select count(*) into n from user_tab_columns where table_name='DISCIPLINE_TEACHERS' and column_name='ACADEMIC_YEAR';
 if n<>0 then raise_application_error(-20170,'Academic-year migration already applied.');end if;
 select count(*) into n from user_tables where table_name='CURRICULUM';
 if n<>1 then raise_application_error(-20170,'Apply the curriculum release first.');end if;
end;
/
alter table discipline_teachers add(academic_year number);
alter table grades add(academic_year number);
alter table grades drop constraint grades_assignment_fk;
alter table discipline_teachers drop constraint discipline_teachers_pk;
'''+ '\n'.join(read(n) for n in ['02_programs.sql','10_standalone_programs.sql','20_teacher_grading.sql'])+'''
begin university_api.migrate_academic_years;end;
/
alter table discipline_teachers modify(academic_year not null);
alter table grades modify(academic_year not null);
alter table discipline_teachers add constraint dt_academic_year_ck check(academic_year between 1900 and 9998 and academic_year=trunc(academic_year));
alter table discipline_teachers add constraint discipline_teachers_pk primary key(curriculum_id,teacher_id,academic_year);
alter table grades add constraint grades_assignment_fk foreign key(curriculum_id,teacher_id,academic_year) references discipline_teachers(curriculum_id,teacher_id,academic_year);
drop index grades_assignment_ix;
create index grades_assignment_ix on grades(curriculum_id,teacher_id,academic_year);
begin dbms_utility.compile_schema(schema=>user,compile_all=>false);end;
/
begin dbms_session.reset_package;end;
/
declare n number;
begin
 select count(*) into n from user_errors;
 if n<>0 then raise_application_error(-20179,'Compilation errors after academic-year migration.');end if;
 university_api.validate_rules;
end;
/
commit;
prompt ACADEMIC_YEAR_MIGRATION_COMPLETED
'''
# Preserve released one-time migrations when reporting is upgraded later.
if not (R/'sql/26_migrate_academic_year.sql').exists():
 (R/'sql/26_migrate_academic_year.sql').write_text(sql,encoding='utf-8',newline='\n')
if (R/'sql/31_teacher_select_rules_validation.sql').exists():
 update='''-- Reporting-only update for the current eleven-table academic-year release.
-- Oracle CREATE OR REPLACE commits DDL; run after finishing your own transaction.
set define off
set serveroutput on
whenever sqlerror exit sql.sqlcode rollback
declare n number;
begin
 if user<>'UNIVERSITY_PROJECT' then raise_application_error(-20000,'Use UNIVERSITY_PROJECT.');end if;
 select count(*) into n from user_tab_columns where table_name in('GRADES','DISCIPLINE_TEACHERS') and column_name='ACADEMIC_YEAR';
 if n<>2 then raise_application_error(-20980,'Install the academic-year release first.');end if;
end;
/
'''+ '\n'.join(read(n) for n in ['02_programs.sql','20_teacher_grading.sql','10_standalone_programs.sql'])+'''
begin dbms_utility.compile_schema(schema=>user,compile_all=>false);end;
/
declare n number;
begin
 select count(*) into n from user_objects where status<>'VALID';
 if n<>0 then raise_application_error(-20980,'Invalid objects after reporting update.');end if;
 university_api.validate_rules;
end;
/
prompt REPORTING_UPDATE_COMPLETED
'''
 (R/'sql/32_update_reporting.sql').write_text(update,encoding='utf-8',newline='\n')
s=read('01_schema.sql');ddl=s[s.index('create table specialties'):s.index('create sequence curriculum_seq')]
ddl+=s[s.index('comment on table specialties'):s.index('prompt UNIVERSITY_SCHEMA_READY')]
(R/'models/university_import.sql').write_text(ddl,encoding='utf-8',newline='\n')
print('ACADEMIC_YEAR_BUILD_AND_MIGRATION_ASSEMBLED')
