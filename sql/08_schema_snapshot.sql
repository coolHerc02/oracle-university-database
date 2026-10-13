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
