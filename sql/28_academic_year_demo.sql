-- Presentation: a different teacher in a later year, with history retained.
set define off
set serveroutput on
whenever sqlerror exit sql.sqlcode rollback
savepoint year_demo;
variable demo_curriculum number
begin
 select min(c.curriculum_id) into :demo_curriculum
 from curriculum c join discipline_teachers dt on dt.curriculum_id=c.curriculum_id
 where c.specialty_id=1 and dt.teacher_id=3 and dt.academic_year=2025;
 if :demo_curriculum is null then raise_application_error(-20190,'Load the supplied sample data.');end if;
 university_api.assign_curriculum_teacher(:demo_curriculum,4,2026);
end;
/
prompt HISTORICAL_AND_NEW_YEAR_APPOINTMENTS
select d.discipline_name,s.specialty_name,c.semester_no,dt.teacher_id,
 to_char(dt.academic_year,'FM0000')||'/'||to_char(dt.academic_year+1,'FM0000') academic_year
from discipline_teachers dt join curriculum c on c.curriculum_id=dt.curriculum_id
join disciplines d on d.discipline_id=c.discipline_id join specialties s on s.specialty_id=c.specialty_id
where c.curriculum_id=:demo_curriculum order by dt.academic_year,dt.teacher_id;
prompt HISTORICAL_GRADES_KEEP_THEIR_YEAR_AND_TEACHER
select faculty_number,discipline_name,grade_value,academic_year_label,grading_teacher_id
from v_academic_report where curriculum_id=:demo_curriculum order by faculty_number;
rollback to year_demo;
prompt ACADEMIC_YEAR_DEMO_ROLLED_BACK
