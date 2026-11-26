# Представяне пред преподавателя: CREATE TABLE и CRUD

CREATE TABLE е DDL за създаване на структурата. В CRUD буквата C означава създаване на запис чрез INSERT.
Проектът има и 11 CREATE TABLE дефиниции, и INSERT/SELECT/UPDATE/DELETE за всички 11 таблици.
Наличните таблици не се създават повторно при демонстрацията.

1. Отвори SQL Developer и връзката UNIVERSITY_PROJECT. Приключи собствените непотвърдени редакции с COMMIT или ROLLBACK.
2. Покажи models/university.dmd: Relational_1, после Logical. Обясни CURRICULUM и учебната година в назначенията.
3. Отвори sql/01_schema.sql, намери CREATE TABLE за избрана таблица и покажи полетата, PK, FK, UNIQUE и CHECK. Не изпълнявай целия schema файл върху готовата база.
4. Отвори sql/29_defense_demo.sql и натисни F5. PART_1 извежда действителния CREATE TABLE на всяка таблица чрез DBMS_METADATA.GET_DDL. PART_2 изпълнява 44 реални CRUD операции и 56 проверки.
5. В Script Output намери PASS: <таблица> C, R, U и D. В sql/18_crud_all_tables.sql намери съответния коментиран блок, за да покажеш точния код.
6. Покажи 11-те съобщения за възстановени редове/полета след ROLLBACK и CRUD_ALL_TABLES_PASSED.
7. Изпълни sql/28_academic_year_demo.sql с F5. Покажи стария преподавател през 2025/2026 и друг преподавател през 2026/2027, без пренаписване на историческите оценки.
8. За въпроси по защитата покажи results/teacher-authorization.txt и sql/27_academic_year_validation.sql. При преподавателски вход използвай само TEACHER_GRADING.

## Покритие по таблици

| Таблица | CREATE TABLE | INSERT / Create | SELECT / Read | UPDATE | DELETE |
|---|---|---|---|---|---|
| SPECIALTIES | [DDL](../sql/01_schema.sql#L27) | INSERT | SELECT | UPDATE | DELETE |
| ACADEMIC_TITLES | [DDL](../sql/01_schema.sql#L36) | INSERT | SELECT | UPDATE | DELETE |
| STUDY_YEARS | [DDL](../sql/01_schema.sql#L45) | INSERT | SELECT | UPDATE | DELETE |
| SEMESTERS | [DDL](../sql/01_schema.sql#L54) | INSERT | SELECT | UPDATE | DELETE |
| GRADE_SCALE | [DDL](../sql/01_schema.sql#L66) | INSERT | SELECT | UPDATE | DELETE |
| STUDENTS | [DDL](../sql/01_schema.sql#L82) | create_student / student_ins | SELECT | update_student / student_upd | delete_student |
| TEACHERS | [DDL](../sql/01_schema.sql#L99) | create_teacher_for_disciplines | SELECT | update_teacher / teacher_upd | delete_teacher |
| DISCIPLINES | [DDL](../sql/01_schema.sql#L116) | add_discipline | SELECT | update_discipline | delete_discipline |
| CURRICULUM | [DDL](../sql/01_schema.sql#L124) | add_curriculum | SELECT | update_curriculum | delete_curriculum |
| DISCIPLINE_TEACHERS | [DDL](../sql/01_schema.sql#L137) | assign_teacher → assign_curriculum_teacher | SELECT | replace_teacher → replace_curriculum_teacher | unassign_teacher → unassign_curriculum_teacher |
| GRADES | [DDL](../sql/01_schema.sql#L147) | grade_ins → set_grade | SELECT | grade_upd → set_grade | delete_grade |

При петте справочника CRUD е директен DML. При шестте основни таблици се използват процедури/пакет, защото те пазят бизнес правилата. Извикването на процедурата води до действителен INSERT/UPDATE/DELETE в пакета; този SQL се вижда в sql/02_programs.sql.

За GRADE_SCALE всички допустими стойности 2-6 вече съществуват. Демонстрацията временно освобождава 6 чрез savepoint, изпълнява четирите операции и възстановява скалата и оценките; ограниченията не се изключват.
Създаването на студент включва две оценки; създаването на преподавател - поне две дисциплини. Изтриването на трета оценка е показано така, че да останат необходимите две.

## Какво да обясниш

„Първо показвам DDL за структурата. След това доказвам CRUD чрез реални операции и SELECT проверки. Основните таблици се променят през PL/SQL API, което спазва ограниченията и връща собствените промени при грешка. Накрая ROLLBACK възстановява тестовите данни. Учебната година е част от преподавателското назначение и от външния ключ на оценката, затова смяната на преподавател през нова година запазва старите оценки.“

В демонстрационните скриптове ROLLBACK е умишлен. Oracle sequences могат да оставят пропуснати ID.
Миграция 26 вече е приложена и не се изпълнява повторно. Нова празна схема се изгражда чрез 13_build.sql.

Допълнение от 19.11.2026: изпълни sql/30_teacher_select_rules_demo.sql за примера на преподавателя с keyword, LIKE, FOR cursor и DBMS_OUTPUT. В sql/06_reports.sql вече се задават p_specialty_name, p_study_year_label и p_discipline_name. [Подробни правила и обяснение](teacher-select-rules.md).


## По една SELECT заявка и процедура за всяка таблица - 26.11.2026

Файловете са в sql/ на готовия University_Project. Новите процедури са част от 13_build.sql за празна схема и вече са създадени в работната база. 34 е отделният инсталационен файл за текуща съществуваща база; изпълнението на CREATE OR REPLACE е DDL и приключва текущата транзакция.

| Таблица | Процедура | Незадължителни параметри, в реда на декларацията |
|---|---|---|
| SPECIALTIES | list_specialties | p_keyword |
| ACADEMIC_TITLES | list_academic_titles | p_keyword |
| STUDY_YEARS | list_study_years | p_keyword |
| SEMESTERS | list_semesters | p_year_keyword, p_term_no |
| GRADE_SCALE | list_grade_scale | p_min_grade, p_is_passing |
| STUDENTS | list_students | p_keyword, p_specialty_keyword, p_year_keyword |
| TEACHERS | list_teachers | p_keyword, p_title_keyword |
| DISCIPLINES | list_disciplines | p_keyword |
| CURRICULUM | list_curriculum | p_discipline_keyword, p_specialty_keyword, p_semester_no |
| DISCIPLINE_TEACHERS | list_teaching_assignments | p_discipline_keyword, p_teacher_keyword, p_specialty_keyword, p_academic_year |
| GRADES | list_grades | p_faculty_number, p_discipline_keyword, p_specialty_keyword, p_academic_year, p_min_grade |

```sql
set serveroutput on

exec list_students;
exec list_students(p_specialty_keyword=>'комп');
exec list_teachers(p_title_keyword=>'професор');
exec list_teaching_assignments(p_academic_year=>2026);
exec list_grades(p_faculty_number=>'00010001',p_academic_year=>2025);
```

За демонстрация първо отвори [33](../sql/33_select_each_table.sql): всяка секция има параметри с начална стойност NULL и самостоятелен SELECT. Промени стойността на параметъра в съответната секция преди F5, ако искаш филтър. Изпълнението на целия файл отново задава всички параметри по неговите начални стойности.

След това отвори [34](../sql/34_cursor_procedures_each_table.sql) за кода: същият SELECT е поставен в CURSOR c_rows, а FOR r IN c_rows LOOP извежда записите. [35](../sql/35_cursor_procedures_demo.sql) извиква всичките 11 процедури и дава примери с филтри. Използвай F5 и Script Output; резултатът е LIST|таблица, ROW|характеристики и ROWS|таблица|брой. Нулев резултат има изрично ROWS|...|0. NULL поле се показва като <NULL>.

Празен/NULL keyword означава всички записи. Текстовите филтри търсят част от наименование без разлика между главни и малки букви; %, _ и обратната наклонена черта се третират буквално. Факултетният номер е точно съвпадение след премахване на крайни интервали. Keyword за STUDENTS/TEACHERS означава името на човека. Параметрите могат да се комбинират с AND. Учебната година 2025 означава 2025/2026; p_year_keyword е означение на курса, например I курс.

Процедурите проверяват размера на аргументите и допустимите числови стойности; -20200 означава прекалено дълъг текст, -20201 - невалиден числов филтър. Числовите граници са оценка 2-6, term_no 1/2, is_passing 0/1, положителен цял номер на семестър и цяла учебна година 1900-9998.

Всяка заявка запазва по един резултатен ред за всеки запис от основната таблица при липса на филтри. Идентични имена не се сливат чрез DISTINCT или GROUP BY. DISCIPLINES е каталог само с име; подробностите за специалност, семестър и преподавател са в CURRICULUM и DISCIPLINE_TEACHERS. GRADES показва действителния оценяващ преподавател, без да умножава редовете по броя водещи преподаватели.

Има 91 нови Oracle проверки, 57 проверки за съответствие на заявка и курсор и отделна проверка на преподавателските права. Списъците са за UNIVERSITY_PROJECT; ограничените преподавателски входове продължават да използват TEACHER_GRADING. Примерните извиквания и SELECT заявките не променят данните. 36 използва временен справочен запис за тест и го връща с ROLLBACK.

Точните заявки се поддържат на едно място в scripts/Build-Table-Cursor-SQL.py, който генерира 33-36. Validate-Table-Cursor-SQL.py сравнява колоните, JOIN, WHERE и ORDER BY на всяка двойка. Резултатите са в [проверки](../results/table-cursor-validation.txt), [изход от процедурите](../results/table-cursor-demo.txt) и [сравнение на данните](../results/table-cursor-data-preservation.txt).
