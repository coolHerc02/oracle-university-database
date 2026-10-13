# Oracle Data Modeler
Версия с M:N преподаване от 13.10.2026. Native проектът е `university.dmd` и цялата папка `university/` до него; те се отварят и копират заедно.

| Част | Проверен резултат |
| --- | --- |
| Релационен модел Relational_1 | 10 таблици, 35 колони, 10 FK |
| Логически модел | 10 entities, 35 attributes, 10 relations |
| Oracle физически модел | Oracle Database 11g, 10 table proxies |
| Съответствие с Oracle | 333 структурни проверки |
| Подредба | 10 кутии и 10 връзки във всяка диаграма |

Първоначалният импорт и Engineer to Logical Model са извършени в Data Modeler с помощта на потребителя на 6.10.2026. `university.dmd.log` е историческият журнал на тогавашните 35 внесени команди. Текущият `university_import.sql` е обновен DDL за десетте таблици.

На 13.10.2026, след успешен запис и затваряне на проекта от потребителя, native файловете са обновени: нова таблица/логическа entity DISCIPLINE_TEACHERS, съставен PK/UID, две идентифициращи връзки, physical proxies, registries и engineering mappings. Старите DISCIPLINES.teacher_id и пряката връзка към TEACHERS са премахнати. Преди редакцията е запазен пълен backup извън учебния пакет.

## Връзки и правила
- TEACHERS → DISCIPLINE_TEACHERS: преподавателят има 2..N назначения към различни дисциплини.
- DISCIPLINES → DISCIPLINE_TEACHERS: дисциплината има 1..N назначения към различни преподаватели.
- Всеки ред на DISCIPLINE_TEACHERS има точно един преподавател и една дисциплина; PK е (discipline_id, teacher_id).
- STUDENTS → GRADES: студентът има 2..N оценени дисциплини.
- GRADES запазва PK (faculty_number, discipline_id): една текуща оценка за двойката.
- Всички FK са задължителни. Минималните бройки се налагат чрез UNIVERSITY_API и пет защитни triggers.

Надписите 1..N/2..N и коментарите уточняват кардиналностите в native модела. Стандартна ERD нотация сама не изразява минимум две.

## Проверки и изображения
`scripts/Validate-DataModeler.py` сравнява модела с действителния `results/schema-snapshot.txt`. Проверява полета, типове, ключове, CHECK, FK, логически UID/отношения, registries, physical proxies и engineering maps.

`docs/diagrams/` съдържа logical и relational във PNG/SVG/PDF. Изображенията се генерират от actual native objects и geometry; не са GUI export. Потребителят потвърди двата обновени модела и успешния запис в Data Modeler. Прегледът е описан отделно в [лога](../docs/activity-log.md).

И двата пътя models/university.dmd и deliverables/University_Project/models/university.dmd съдържат обновения дизайн. Пакетирането синхронизира проверената подредба. Официалното описание е [Oracle Data Modeler guide](https://docs.oracle.com/database/sql-developer-data-modeler-17.4/DMDUG/data-modeler-concepts-usage.htm).
