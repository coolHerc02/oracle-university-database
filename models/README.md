# Oracle Data Modeler

Отвори university.dmd, като запазиш цялата папка university до него.
Двата native модела имат 11 обекта, 41 полета и 12 връзки, включително CURRICULUM и GRADES → DISCIPLINE_TEACHERS.
DISCIPLINES няма semester_no. DISCIPLINE_TEACHERS и GRADES използват curriculum_id.
PK на GRADES е (faculty_number,curriculum_id), а FK към назначението е (curriculum_id,teacher_id,academic_year).
Oracle физическите proxies, UID, registries и engineering maps са обновени.

Обновените файлове са проверени с 384 структурни проверки спрямо действителната Oracle схема. Нов визуален GUI преглед се потвърждава отделно.
Минимумите и коментарите са част от модела; две назначения в различни специалности по една дисциплина не изпълняват минимума две различни дисциплини.
university_import.sql съдържа текущия DDL за импорт. docs/diagrams съдържа визуализации, генерирани от записаните native данни и геометрия.
[Таблици](../docs/data-dictionary.md). [Връзки](../docs/relationship-matrix.md). [Учебен план](../docs/curriculum-change.md).

academic_year участва в PK на DISCIPLINE_TEACHERS и FK на GRADES.
