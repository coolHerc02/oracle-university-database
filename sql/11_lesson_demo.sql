set define off
set serveroutput on
whenever sqlerror exit sql.sqlcode rollback
prompt LESSON DEMONSTRATION: changes will be rolled back

declare
 l_teacher number; l_d1 number; l_d2 number; l_d3 number;
 l_title number; l_specialty number; l_year number;
begin
 select min(title_id) into l_title from academic_titles;
 select min(specialty_id) into l_specialty from specialties;
 select min(study_year_no) into l_year from study_years;
 teacher_ins('Demo',null,'Teacher',l_title,'+359000000099','demo.teacher@university.example',
  'Demo modelling',1,'Demo databases',2,l_teacher,l_d1,l_d2);
 student_ins('DEMO-LESSON','Demo',null,'Student',l_specialty,l_year,'demo.student@university.example',
  l_d1,4,date '2026-06-10',l_d2,5,date '2026-06-11');
 student_upd('DEMO-LESSON','Demo',null,'Student',l_specialty,l_year,'updated.student@university.example');
 teacher_upd(l_teacher,'Demo',null,'Teacher',l_title,'+359000000098','updated.teacher@university.example');
 discipline_ins('Demo SQL',3,l_teacher,l_d3);
 discipline_upd(l_d3,'Demo SQL and PL/SQL');
 grade_ins('DEMO-LESSON',l_d3,6,date '2026-06-12');
 grade_upd('DEMO-LESSON',l_d1,5,date '2026-06-13');
 dbms_output.put_line('EXPLICIT OPEN/FETCH/CLOSE CURSOR:');
 academic_report('DEMO-LESSON');
 dbms_output.put_line('FOR CURSOR - TEACHER DISCIPLINES:');
 teacher_disciplines(l_teacher);
 dbms_output.put_line('LIKE CURSOR - STUDENT KEYWORD:');
 find_student('Demo');
 dbms_output.put_line('LIKE CURSOR - DISCIPLINE KEYWORD:');
 find_discipline('PL/SQL');
end;
/
rollback;
prompt LESSON_DEMO_ROLLED_BACK

prompt SEEDED ACADEMIC REPORT - EXPLICIT CURSOR
begin academic_report('00010001'); end;
/
prompt CYRILLIC KEYWORD SEARCH
begin find_student(unistr('\0410\043b\0435\043a\0441\0430\043d\0434\044a\0440')); end;
/
begin find_discipline(unistr('\0431\0430\0437\0438')); end;
/
