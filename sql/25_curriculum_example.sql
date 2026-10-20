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
