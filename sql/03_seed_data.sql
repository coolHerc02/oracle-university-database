-- Fictional educational data. Run once after 01_schema.sql and 02_programs.sql.
set define off
set serveroutput on
whenever sqlerror exit sql.sqlcode rollback

declare
 l_count number;
begin
 if user <> 'UNIVERSITY_PROJECT' then raise_application_error(-20000,'Use UNIVERSITY_PROJECT.'); end if;
 select (select count(*) from students)+(select count(*) from teachers)+(select count(*) from specialties)+(select count(*) from academic_titles)+(select count(*) from study_years)+(select count(*) from grade_scale) into l_count from dual;
 if l_count <> 0 then raise_application_error(-20060,'Seed data requires an empty project schema. No data is removed.'); end if;
end;
/
insert into specialties values (1,unistr('\041a\043e\043c\043f\044e\0442\044a\0440\043d\0438 \043d\0430\0443\043a\0438'));
insert into specialties values (2,unistr('\0421\043e\0444\0442\0443\0435\0440\043d\043e \0438\043d\0436\0435\043d\0435\0440\0441\0442\0432\043e'));
insert into specialties values (3,unistr('\0418\043a\043e\043d\043e\043c\0438\043a\0430'));
insert into academic_titles values (1,unistr('\0430\0441\0438\0441\0442\0435\043d\0442'));
insert into academic_titles values (2,unistr('\0433\043b\0430\0432\0435\043d \0430\0441\0438\0441\0442\0435\043d\0442'));
insert into academic_titles values (3,unistr('\0434\043e\0446\0435\043d\0442'));
insert into academic_titles values (4,unistr('\043f\0440\043e\0444\0435\0441\043e\0440'));
insert into study_years values (1,unistr('I \043a\0443\0440\0441'));
insert into study_years values (2,unistr('II \043a\0443\0440\0441'));
insert into study_years values (3,unistr('III \043a\0443\0440\0441'));
insert into study_years values (4,unistr('IV \043a\0443\0440\0441'));
insert into study_years values (5,unistr('V \043a\0443\0440\0441'));
insert into study_years values (6,unistr('VI \043a\0443\0440\0441'));
insert into semesters values (1,1,1);
insert into semesters values (2,1,2);
insert into semesters values (3,2,1);
insert into semesters values (4,2,2);
insert into semesters values (5,3,1);
insert into semesters values (6,3,2);
insert into semesters values (7,4,1);
insert into semesters values (8,4,2);
insert into semesters values (9,5,1);
insert into semesters values (10,5,2);
insert into semesters values (11,6,1);
insert into semesters values (12,6,2);
insert into grade_scale values (2,unistr('\0421\043b\0430\0431'),0);
insert into grade_scale values (3,unistr('\0421\0440\0435\0434\0435\043d'),1);
insert into grade_scale values (4,unistr('\0414\043e\0431\044a\0440'),1);
insert into grade_scale values (5,unistr('\041c\043d\043e\0433\043e \0434\043e\0431\044a\0440'),1);
insert into grade_scale values (6,unistr('\041e\0442\043b\0438\0447\0435\043d'),1);

declare
 l_disciplines university_api.t_discipline_list;
 l_grades university_api.t_grade_list;
 l_teacher_id number;
 l_created_ids sys.odcinumberlist;
 type t_ids is table of number index by pls_integer;
 l_ids t_ids;
begin
 l_disciplines.delete;
 l_disciplines(1).discipline_name := unistr('\041c\0430\0442\0435\043c\0430\0442\0438\043a\0430'); l_disciplines(1).semester_no := 1;
 l_disciplines(2).discipline_name := unistr('\0410\043b\0433\043e\0440\0438\0442\043c\0438'); l_disciplines(2).semester_no := 2;
 l_disciplines(3).discipline_name := unistr('\0414\0438\0441\043a\0440\0435\0442\043d\0430 \043c\0430\0442\0435\043c\0430\0442\0438\043a\0430'); l_disciplines(3).semester_no := 2;
 university_api.create_teacher(unistr('\041f\0435\0442\044a\0440'),unistr('\0418\0432\0430\043d\043e\0432'),unistr('\041d\0438\043a\043e\043b\043e\0432'),4,'+359000000001','teacher1@university.example',l_disciplines,l_teacher_id,l_created_ids);
 l_ids(1) := l_created_ids(1);
 l_ids(2) := l_created_ids(2);
 l_ids(3) := l_created_ids(3);
 l_disciplines.delete;
 l_disciplines(1).discipline_name := unistr('\0411\0430\0437\0438 \043e\0442 \0434\0430\043d\043d\0438'); l_disciplines(1).semester_no := 3;
 l_disciplines(2).discipline_name := unistr('SQL \043f\0440\043e\0433\0440\0430\043c\0438\0440\0430\043d\0435'); l_disciplines(2).semester_no := 4;
 l_disciplines(3).discipline_name := unistr('\041c\043e\0434\0435\043b\0438\0440\0430\043d\0435 \043d\0430 \0434\0430\043d\043d\0438'); l_disciplines(3).semester_no := 3;
 university_api.create_teacher(unistr('\041c\0430\0440\0438\044f'),unistr('\041f\0435\0442\0440\043e\0432\0430'),unistr('\0413\0435\043e\0440\0433\0438\0435\0432\0430'),3,'+359000000002','teacher2@university.example',l_disciplines,l_teacher_id,l_created_ids);
 l_ids(4) := l_created_ids(1);
 l_ids(5) := l_created_ids(2);
 l_ids(6) := l_created_ids(3);
 l_disciplines.delete;
 l_disciplines(1).discipline_name := unistr('\041e\043f\0435\0440\0430\0446\0438\043e\043d\043d\0438 \0441\0438\0441\0442\0435\043c\0438'); l_disciplines(1).semester_no := 3;
 l_disciplines(2).discipline_name := unistr('\041a\043e\043c\043f\044e\0442\044a\0440\043d\0438 \043c\0440\0435\0436\0438'); l_disciplines(2).semester_no := 4;
 university_api.create_teacher(unistr('\0418\0432\0430\043d'),unistr('\041a\043e\043b\0435\0432'),unistr('\0414\0438\043c\0438\0442\0440\043e\0432'),2,'+359000000003','teacher3@university.example',l_disciplines,l_teacher_id,l_created_ids);
 l_ids(7) := l_created_ids(1);
 l_ids(8) := l_created_ids(2);
 l_disciplines.delete;
 l_disciplines(1).discipline_name := unistr('\041e\0441\043d\043e\0432\0438 \043d\0430 \0438\043a\043e\043d\043e\043c\0438\043a\0430\0442\0430'); l_disciplines(1).semester_no := 1;
 l_disciplines(2).discipline_name := unistr('\0421\0442\0430\0442\0438\0441\0442\0438\043a\0430'); l_disciplines(2).semester_no := 2;
 university_api.create_teacher(unistr('\0415\043b\0435\043d\0430'),unistr('\041d\0438\043a\043e\043b\043e\0432\0430'),unistr('\0421\0442\043e\044f\043d\043e\0432\0430'),3,'+359000000004','teacher4@university.example',l_disciplines,l_teacher_id,l_created_ids);
 l_ids(9) := l_created_ids(1);
 l_ids(10) := l_created_ids(2);
 l_disciplines.delete;
 l_disciplines(1).discipline_name := unistr('\0421\043e\0444\0442\0443\0435\0440\043d\043e \0438\043d\0436\0435\043d\0435\0440\0441\0442\0432\043e'); l_disciplines(1).semester_no := 5;
 l_disciplines(2).discipline_name := unistr('\0423\0435\0431 \0442\0435\0445\043d\043e\043b\043e\0433\0438\0438'); l_disciplines(2).semester_no := 6;
 university_api.create_teacher(unistr('\0413\0435\043e\0440\0433\0438'),unistr('\0422\043e\0434\043e\0440\043e\0432'),unistr('\041f\0435\0442\0440\043e\0432'),4,'+359000000005','teacher5@university.example',l_disciplines,l_teacher_id,l_created_ids);
 l_ids(11) := l_created_ids(1);
 l_ids(12) := l_created_ids(2);
 l_disciplines.delete;
 l_disciplines(1).discipline_name := unistr('\0410\043d\0433\043b\0438\0439\0441\043a\0438 \0435\0437\0438\043a'); l_disciplines(1).semester_no := 1;
 l_disciplines(2).discipline_name := unistr('\0410\043a\0430\0434\0435\043c\0438\0447\0435\043d \0430\043d\0433\043b\0438\0439\0441\043a\0438'); l_disciplines(2).semester_no := 2;
 university_api.create_teacher(unistr('\0410\043d\043d\0430'),unistr('\0414\0438\043c\0438\0442\0440\043e\0432\0430'),unistr('\041a\043e\043b\0435\0432\0430'),1,'+359000000006','teacher6@university.example',l_disciplines,l_teacher_id,l_created_ids);
 l_ids(13) := l_created_ids(1);
 l_ids(14) := l_created_ids(2);
 select teacher_id into l_teacher_id from teachers where email='teacher2@university.example';
 university_api.assign_teacher(l_ids(1),l_teacher_id);
 select teacher_id into l_teacher_id from teachers where email='teacher1@university.example';
 university_api.assign_teacher(l_ids(4),l_teacher_id);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(1); l_grades(1).grade_value := 6; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(2); l_grades(2).grade_value := 6; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(13); l_grades(3).grade_value := 6; l_grades(3).grade_date := date '2026-06-12';
 l_grades(4).discipline_id := l_ids(3); l_grades(4).grade_value := 6; l_grades(4).grade_date := date '2026-06-13';
 university_api.create_student('00010001',unistr('\0410\043b\0435\043a\0441\0430\043d\0434\044a\0440'),unistr('\0418\0432\0430\043d\043e\0432'),unistr('\041f\0435\0442\0440\043e\0432'),1,1,'student1@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(1); l_grades(1).grade_value := 5; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(2); l_grades(2).grade_value := 4; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(13); l_grades(3).grade_value := 5; l_grades(3).grade_date := date '2026-06-12';
 l_grades(4).discipline_id := l_ids(9); l_grades(4).grade_value := 4; l_grades(4).grade_date := date '2026-06-13';
 university_api.create_student('00010002',unistr('\041c\0430\0440\0438\044f'),unistr('\0413\0435\043e\0440\0433\0438\0435\0432\0430'),unistr('\0414\0438\043c\0438\0442\0440\043e\0432\0430'),2,1,'student2@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(1); l_grades(1).grade_value := 2; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(2); l_grades(2).grade_value := 3; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(13); l_grades(3).grade_value := 4; l_grades(3).grade_date := date '2026-06-12';
 l_grades(4).discipline_id := l_ids(10); l_grades(4).grade_value := 3; l_grades(4).grade_date := date '2026-06-13';
 university_api.create_student('00010003',unistr('\0418\0432\0430\043d'),unistr('\041f\0435\0442\0440\043e\0432'),unistr('\0421\0442\043e\044f\043d\043e\0432'),3,1,'student3@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(1); l_grades(1).grade_value := 6; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(2); l_grades(2).grade_value := 6; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(13); l_grades(3).grade_value := 6; l_grades(3).grade_date := date '2026-06-12';
 l_grades(4).discipline_id := l_ids(3); l_grades(4).grade_value := 6; l_grades(4).grade_date := date '2026-06-13';
 university_api.create_student('00010004',unistr('\0415\043b\0435\043d\0430'),unistr('\041d\0438\043a\043e\043b\043e\0432\0430'),unistr('\0413\0435\043e\0440\0433\0438\0435\0432\0430'),1,1,'student4@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(1); l_grades(1).grade_value := 4; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(2); l_grades(2).grade_value := 5; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(13); l_grades(3).grade_value := 5; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010005',unistr('\0413\0435\043e\0440\0433\0438'),unistr('\0414\0438\043c\0438\0442\0440\043e\0432'),unistr('\0418\0432\0430\043d\043e\0432'),2,1,'student5@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(1); l_grades(1).grade_value := 2; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(2); l_grades(2).grade_value := 2; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(13); l_grades(3).grade_value := 3; l_grades(3).grade_date := date '2026-06-12';
 l_grades(4).discipline_id := l_ids(14); l_grades(4).grade_value := 3; l_grades(4).grade_date := date '2026-06-13';
 university_api.create_student('00010006',unistr('\0410\043d\043d\0430'),unistr('\0421\0442\043e\044f\043d\043e\0432\0430'),unistr('\041f\0435\0442\0440\043e\0432\0430'),3,1,'student6@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(4); l_grades(1).grade_value := 5; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(5); l_grades(2).grade_value := 5; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(7); l_grades(3).grade_value := 5; l_grades(3).grade_date := date '2026-06-12';
 l_grades(4).discipline_id := l_ids(6); l_grades(4).grade_value := 5; l_grades(4).grade_date := date '2026-06-13';
 university_api.create_student('00010007',unistr('\041d\0438\043a\043e\043b\0430\0439'),unistr('\0410\043b\0435\043a\0441\0430\043d\0434\0440\043e\0432'),unistr('\041a\043e\043b\0435\0432'),1,2,'student7@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(4); l_grades(1).grade_value := 6; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(5); l_grades(2).grade_value := 5; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(7); l_grades(3).grade_value := 5; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010008',unistr('\0412\0438\043a\0442\043e\0440\0438\044f'),unistr('\0418\0432\0430\043d\043e\0432\0430'),unistr('\041d\0438\043a\043e\043b\043e\0432\0430'),2,2,'student8@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(4); l_grades(1).grade_value := 3; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(5); l_grades(2).grade_value := 4; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(7); l_grades(3).grade_value := 2; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010009',unistr('\0414\0438\043c\0438\0442\044a\0440'),unistr('\0413\0435\043e\0440\0433\0438\0435\0432'),unistr('\0422\043e\0434\043e\0440\043e\0432'),3,2,'student9@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(4); l_grades(1).grade_value := 4; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(5); l_grades(2).grade_value := 4; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(7); l_grades(3).grade_value := 5; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010010',unistr('\041f\0435\0442\044f'),unistr('\041f\0435\0442\0440\043e\0432\0430'),unistr('\041a\043e\0441\0442\043e\0432\0430'),1,2,'student10@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(4); l_grades(1).grade_value := 6; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(5); l_grades(2).grade_value := 6; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(7); l_grades(3).grade_value := 5; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010011',unistr('\0411\043e\0440\0438\0441'),unistr('\041d\0438\043a\043e\043b\043e\0432'),unistr('\0414\0438\043c\0438\0442\0440\043e\0432'),2,2,'student11@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(4); l_grades(1).grade_value := 2; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(5); l_grades(2).grade_value := 3; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(7); l_grades(3).grade_value := 3; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010012',unistr('\0421\043e\0444\0438\044f'),unistr('\0422\043e\0434\043e\0440\043e\0432\0430'),unistr('\0418\0432\0430\043d\043e\0432\0430'),3,2,'student12@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(11); l_grades(1).grade_value := 5; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(12); l_grades(2).grade_value := 5; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(8); l_grades(3).grade_value := 4; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010013',unistr('\041c\0430\0440\0442\0438\043d'),unistr('\041a\043e\043b\0435\0432'),unistr('\041f\0435\0442\0440\043e\0432'),1,3,'student13@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(11); l_grades(1).grade_value := 4; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(12); l_grades(2).grade_value := 6; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(8); l_grades(3).grade_value := 5; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010014',unistr('\0414\0435\0441\0438\0441\043b\0430\0432\0430'),unistr('\0414\0438\043c\0438\0442\0440\043e\0432\0430'),unistr('\0421\0442\043e\044f\043d\043e\0432\0430'),2,3,'student14@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(11); l_grades(1).grade_value := 3; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(12); l_grades(2).grade_value := 2; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(8); l_grades(3).grade_value := 4; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010015',unistr('\0425\0440\0438\0441\0442\043e'),unistr('\0418\0432\0430\043d\043e\0432'),unistr('\041d\0438\043a\043e\043b\043e\0432'),3,3,'student15@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(11); l_grades(1).grade_value := 6; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(12); l_grades(2).grade_value := 5; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(8); l_grades(3).grade_value := 6; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010016',unistr('\0420\0430\043b\0438\0446\0430'),unistr('\0413\0435\043e\0440\0433\0438\0435\0432\0430'),unistr('\041a\043e\0441\0442\043e\0432\0430'),1,3,'student16@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(11); l_grades(1).grade_value := 5; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(12); l_grades(2).grade_value := 5; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(8); l_grades(3).grade_value := 5; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010017',unistr('\041f\0430\0432\0435\043b'),unistr('\0421\0442\043e\044f\043d\043e\0432'),unistr('\041a\043e\043b\0435\0432'),2,3,'student17@university.example',l_grades);
 l_grades.delete;
 l_grades(1).discipline_id := l_ids(11); l_grades(1).grade_value := 2; l_grades(1).grade_date := date '2026-06-10';
 l_grades(2).discipline_id := l_ids(12); l_grades(2).grade_value := 3; l_grades(2).grade_date := date '2026-06-11';
 l_grades(3).discipline_id := l_ids(8); l_grades(3).grade_value := 4; l_grades(3).grade_date := date '2026-06-12';
 university_api.create_student('00010018',unistr('\0419\043e\0430\043d\0430'),unistr('\041f\0435\0442\0440\043e\0432\0430'),unistr('\0414\0438\043c\0438\0442\0440\043e\0432\0430'),3,3,'student18@university.example',l_grades);
 university_api.validate_rules;
 dbms_output.put_line('SEED_DATA_CREATED_OK');
end;
/
commit;
select 'SPECIALTIES' table_name,count(*) row_count from specialties
union all select 'ACADEMIC_TITLES',count(*) from academic_titles
union all select 'STUDY_YEARS',count(*) from study_years
union all select 'SEMESTERS',count(*) from semesters
union all select 'GRADE_SCALE',count(*) from grade_scale
union all select 'STUDENTS',count(*) from students
union all select 'TEACHERS',count(*) from teachers
union all select 'DISCIPLINES',count(*) from disciplines
union all select 'GRADES',count(*) from grades
union all select 'DISCIPLINE_TEACHERS',count(*) from discipline_teachers;
prompt SEED_COMMITTED_OK
