-- All eleven lists, followed by filtered examples. F5 as UNIVERSITY_PROJECT.
set define off
set serveroutput on size unlimited
set linesize 420
whenever sqlerror exit sql.sqlcode rollback
begin
 if user<>'UNIVERSITY_PROJECT' then raise_application_error(-20000,'Use UNIVERSITY_PROJECT.');end if;
end;
/

prompt ALL_SPECIALTIES
exec list_specialties;

prompt ALL_ACADEMIC_TITLES
exec list_academic_titles;

prompt ALL_STUDY_YEARS
exec list_study_years;

prompt ALL_SEMESTERS
exec list_semesters;

prompt ALL_GRADE_SCALE
exec list_grade_scale;

prompt ALL_STUDENTS
exec list_students;

prompt ALL_TEACHERS
exec list_teachers;

prompt ALL_DISCIPLINES
exec list_disciplines;

prompt ALL_CURRICULUM
exec list_curriculum;

prompt ALL_DISCIPLINE_TEACHERS
exec list_teaching_assignments;

prompt ALL_GRADES
exec list_grades;

prompt FILTERED_SPECIALTIES
exec list_specialties('комп');

prompt FILTERED_ACADEMIC_TITLES
exec list_academic_titles('проф');

prompt FILTERED_SEMESTERS
exec list_semesters(p_term_no=>1);

prompt FILTERED_GRADE_SCALE
exec list_grade_scale(p_is_passing=>0);

prompt FILTERED_STUDENTS
exec list_students(p_specialty_keyword=>'комп');

prompt FILTERED_TEACHERS
exec list_teachers(p_title_keyword=>'професор');

prompt FILTERED_DISCIPLINES
exec list_disciplines('бази');

prompt FILTERED_CURRICULUM
exec list_curriculum(p_discipline_keyword=>'СА');

prompt FILTERED_DISCIPLINE_TEACHERS
exec list_teaching_assignments(p_academic_year=>2026);

prompt FILTERED_GRADES
exec list_grades(p_faculty_number=>'00010001',p_academic_year=>2025);

prompt TABLE_CURSOR_DEMO_COMPLETED
