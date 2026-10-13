# CRUD за всичките 10 таблици

CRUD означава Create (INSERT), Read (SELECT), Update (UPDATE), Delete (DELETE).

Преди това допълнение имаше INSERT във всички таблици чрез примерните данни, SELECT чрез справките и UPDATE за основните данни. Нямаше единен изпълним комплект от четирите операции за всяка таблица. DELETE за студент, преподавател, дисциплина и оценка нямаше самостоятелен API метод.

Сега [sql/18_crud_all_tables.sql](../sql/18_crud_all_tables.sql) изпълнява действително 40 операции: четирите операции за всяка таблица. Използва временни записи и SAVEPOINT; връща собствените промени и сравнява всички редове и полета на десетте таблици с началното състояние. Не прави COMMIT или DDL. Sequence стойностите се увеличават нормално и не се връщат при ROLLBACK.

| Таблица | Create | Read | Update | Delete |
|---|---|---|---|---|
| SPECIALTIES | INSERT | SELECT по specialty_id | UPDATE specialty_name | DELETE на временната специалност |
| ACADEMIC_TITLES | INSERT | SELECT по title_id | UPDATE title_name | DELETE на временната титла |
| STUDY_YEARS | INSERT | SELECT по study_year_no | UPDATE year_label | DELETE на временния курс |
| SEMESTERS | INSERT | SELECT по semester_no | UPDATE semester_no и term_no заедно | DELETE на временния семестър |
| GRADE_SCALE | INSERT на валидна оценка 6 | SELECT по grade_value | UPDATE grade_label | DELETE на временния ред |
| STUDENTS | create_student с две начални оценки | SELECT по faculty_number | update_student | delete_student |
| TEACHERS | create_teacher_for_disciplines | SELECT по teacher_id | update_teacher | delete_teacher |
| DISCIPLINES | add_discipline | SELECT по discipline_id | update_discipline | delete_discipline |
| DISCIPLINE_TEACHERS | assign_teacher | SELECT по съставния PK | replace_teacher | unassign_teacher |
| GRADES | GRADE_INS | SELECT по съставния PK | GRADE_UPD | delete_grade |

API методите са в UNIVERSITY_API. Те изпълняват съответния INSERT/UPDATE/DELETE. Четенето е обикновен SELECT. Защитните triggers остават включени; директен DML върху петте основни таблици се отказва.

## Правила при изтриване

- delete_student изтрива избрания студент и неговите оценки в една операция.
- delete_teacher изтрива преподавателя и неговите назначения; отказва, ако дисциплина остане без преподавател.
- delete_discipline изтрива избраната дисциплина, нейните назначения и оценки; отказва, ако оставащ студент или преподавател има под две дисциплини.
- delete_grade отказва, ако студентът остане с под две оценки.
- Справочен ред с използван FK не се изтрива; FK ограниченията остават активни.

Всички API операции използват заключване NOWAIT, SAVEPOINT и проверка на крайното състояние. При отказ връщат собствените промени и пазят предходните промени на клиента. COMMIT остава решение на клиента.

В GRADE_SCALE вече са заети всички разрешени стойности 2-6. За истински INSERT демонстрацията временно премества препратките от 6 към 5, освобождава 6 и показва CRUD върху нея. Отделен SAVEPOINT възстановява веднага и оригиналната скала, и всички засегнати оценки. Не се добавят невалидни оценки и не се изключват FK.

## Изпълнение и доказателства

В работната Oracle схема допълнението вече е инсталирано. Изпълни файла 18 с F5 в SQL Developer. Очакваният резултат е CRUD_ALL_TABLES_PASSED: 40 operations; 10 tables; 51 checks.

[sql/19_crud_validation.sql](../sql/19_crud_validation.sql) има още 20 проверки за липсващи ключове, минимални бройки, защитен директен DELETE, атомично връщане на зависимите редове и запазване на предходна клиентска промяна.

- [Действително изпълнение на 40-те CRUD операции и 10 сравнения след ROLLBACK](../results/crud-all-tables.txt)
- [Действителни 20 проверки на изтриването](../results/crud-validation.txt)

sql/13_build.sql включва новия API и двата CRUD файла. За обновяване на съществуваща M:N схема се изпълняват sql/02_programs.sql и sql/10_standalone_programs.sql; моделът и структурата на таблиците не се променят.
