# CRUD за всички 11 таблици

sql/18_crud_all_tables.sql изпълнява 44 действителни операции и общо 56 проверки.
Всяка таблица има поне един INSERT, SELECT, UPDATE и DELETE; шестте защитени таблици се променят чрез административния API.
Операциите завършват с ROLLBACK до собствен SAVEPOINT и пълно сравнение на редовете и полетата на всичките 11 таблици.
Sequences продължават да се увеличават при ROLLBACK; пропуснатите ID са нормални.

| Таблици | Create | Read | Update | Delete |
| --- | --- | --- | --- | --- |
| SPECIALTIES, ACADEMIC_TITLES, STUDY_YEARS, SEMESTERS, GRADE_SCALE | INSERT | SELECT | UPDATE | DELETE |
| STUDENTS, TEACHERS, DISCIPLINES | API create/add | SELECT | API update | API delete |
| CURRICULUM | add_curriculum | SELECT | update_curriculum | delete_curriculum |
| DISCIPLINE_TEACHERS | assign_curriculum_teacher | SELECT | replace_curriculum_teacher | unassign_curriculum_teacher |
| GRADES | grade_ins / set_curriculum_grade | SELECT | grade_upd | delete_grade |

Старите учебни помощници за назначения са ограничени до първия учебен план; CRUD демонстрацията използва този контекст за временните си fixtures.
За GRADE_SCALE временен savepoint освобождава стойност 6, показва реален INSERT/UPDATE/DELETE и веднага възстановява и оценките, и скалата.
Ограниченията и защитните triggers остават включени. sql/19_crud_validation.sql има 20 допълнителни проверки за откази и атомарност.
[Изпълнен CRUD](../results/crud-all-tables.txt). [Безопасност на изтриването](../results/crud-validation.txt).
