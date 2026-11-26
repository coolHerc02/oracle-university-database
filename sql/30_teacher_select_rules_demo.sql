-- Read-only classroom demonstration. F5 as UNIVERSITY_PROJECT.
set define off
set serveroutput on size unlimited
set linesize 420
whenever sqlerror exit sql.sqlcode rollback

prompt KEYWORD_IN_RELATED_OBJECT_TITLE
-- Professor is a title, just as Manager is a position on the board.
exec university_api.find_teachers_by_title(unistr('\043f\0440\043e\0444\0435\0441\043e\0440'));

prompt KEYWORD_IN_RELATED_OBJECT_SPECIALTY
exec university_api.find_students_by_specialty(unistr('\043a\043e\043c\043f'));

prompt KEYWORD_IN_STUDENT_NAME
exec find_student(unistr('\0410\043b\0435\043a\0441\0430\043d\0434\044a\0440'));

prompt KEYWORD_IN_DISCIPLINE_NAME_WITH_ALL_TEACHING_CONTEXTS
exec find_discipline(unistr('\0431\0430\0437\0438'));

prompt EXPLICIT_OPEN_FETCH_CLOSE_CURSOR
exec academic_report('00010001');

prompt DECLARED_CURSOR_FOR_LOOP
exec university_api.print_academic_report('00010001');

prompt TEACHER_SELECT_RULES_DEMO_COMPLETED
