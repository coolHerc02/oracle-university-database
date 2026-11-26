# Разрешено разделяне на локалните комити - 26.11.2026

Потребителят изрично поиска всички промени да бъдат комитнати на максимално много смислени комити.
Планът разделя SQL, демонстрации, тестови резултати и документация по файлове.
Native XML моделът е една неделима група; всяка диаграма пази трите си формата заедно.
DDL и import DDL са съгласувана двойка; сглобяването пази генераторите и актуалния build заедно.
Групите образуват общ release; междинните комити не се представят като самостоятелно проверени версии.
Преди комитване: 468 основни Oracle проверки, 91 нови проверки на курсорите и 57 source проверки са успешни.
Няма разрешение за push в настоящата заявка. Реалните хешове и файлове се записват в commit-log.md.

Базов commit: `c58a947445bf88771e04324c0cd692411024083b`. Предвидени комити: **82**.

## 1. db: add academic year to appointment and grade keys

- `models/university_import.sql`
- `sql/01_schema.sql`

## 2. db: scope administrative assignments and grades by academic year

- `sql/02_programs.sql`

## 3. db: authorize teacher grading for the exact appointment year

- `sql/20_teacher_grading.sql`

## 4. migration: retain old appointments and grade authors across academic years

- `sql/26_migrate_academic_year.sql`

## 5. test: record academic year migration evidence

- `results/academic-year-migration.txt`

## 6. test: record academic year data preservation evidence

- `results/academic-year-data-preservation.txt`

## 7. test: record academic year migration rehearsal evidence

- `results/academic-year-migration-rehearsal.txt`

## 8. test: enforce year-specific appointments and historical grade integrity

- `sql/27_academic_year_validation.sql`

## 9. test: record academic year validation evidence

- `results/academic-year-validation.txt`

## 10. demo: show different teachers in successive academic years

- `sql/28_academic_year_demo.sql`

## 11. test: record academic year demo evidence

- `results/academic-year-demo.txt`

## 12. demo: display actual DDL and prove CRUD for all eleven tables

- `sql/29_defense_demo.sql`

## 13. test: record crud coverage audit evidence

- `results/crud-coverage-audit.txt`

## 14. test: record defense demo evidence

- `results/defense-demo.txt`

## 15. docs: explain year values migration and historical grade limits

- `docs/academic-year-change.md`

## 16. docs: prepare instructor demonstration with per-table CRUD matrix

- `docs/defense-guide.md`

## 17. test: record current validation summary evidence

- `results/current-validation-summary.txt`

## 18. report: filter grade searches by meaningful names and show full details

- `sql/05_search.sql`

## 19. test: record search evidence

- `results/search.txt`

## 20. report: apply instructor presentation rules to all five reports

- `sql/06_reports.sql`

## 21. test: record reports evidence

- `results/reports.txt`

## 22. demo: explain related-object keyword searches and cursor variants

- `sql/30_teacher_select_rules_demo.sql`

## 23. test: record teacher select demo evidence

- `results/teacher-select-demo.txt`

## 24. test: verify homonyms literal keywords full details and rollback

- `sql/31_teacher_select_rules_validation.sql`

## 25. test: record teacher select validation evidence

- `results/teacher-select-validation.txt`

## 26. test: audit all seven final SELECT projections filters and ordering

- `scripts/Validate-Teacher-Select-Rules.py`

## 27. test: record teacher select source audit evidence

- `results/teacher-select-source-audit.txt`

## 28. migration: update reporting programs without modifying table data

- `sql/32_update_reporting.sql`

## 29. test: record reporting update evidence

- `results/reporting-update.txt`

## 30. test: record teacher select data preservation evidence

- `results/teacher-select-data-preservation.txt`

## 31. docs: transcribe instructor rules and explain the university cursor example

- `docs/teacher-select-rules.md`

## 32. query: add complete filtered SELECT lists for all eleven tables

- `sql/33_select_each_table.sql`

## 33. test: record table selects evidence

- `results/table-selects.txt`

## 34. db: install eleven read-only declared cursor procedures

- `sql/34_cursor_procedures_each_table.sql`

## 35. test: record table cursor installation evidence

- `results/table-cursor-installation.txt`

## 36. demo: show all table cursors and meaningful filter examples

- `sql/35_cursor_procedures_demo.sql`

## 37. test: record table cursor demo evidence

- `results/table-cursor-demo.txt`

## 38. test: validate cursor cardinality filters inputs and full data restoration

- `sql/36_cursor_procedures_validation.sql`

## 39. test: record table cursor validation evidence

- `results/table-cursor-validation.txt`

## 40. build: generate standalone queries and cursor procedures from one catalogue

- `scripts/Build-Table-Cursor-SQL.py`

## 41. test: verify query cursor equivalence and presentation rules

- `scripts/Validate-Table-Cursor-SQL.py`

## 42. test: record table cursor source audit evidence

- `results/table-cursor-source-audit.txt`

## 43. test: record table cursor data preservation evidence

- `results/table-cursor-data-preservation.txt`

## 44. test: record table cursor privileges evidence

- `results/table-cursor-privileges.txt`

## 45. data: seed original appointments in academic year 2025

- `sql/03_seed_data.sql`

## 46. data: place SIT and KST sample assignments in academic year 2026

- `sql/25_curriculum_example.sql`

## 47. test: record validation evidence

- `results/validation.txt`

## 48. db: adapt standalone procedures and cursors

- `sql/10_standalone_programs.sql`

## 49. test: record lesson demo evidence

- `results/lesson-demo.txt`

## 50. test: record lesson validation evidence

- `results/lesson-validation.txt`

## 51. test: validate scoped many-to-many assignments

- `sql/16_many_teachers_validation.sql`

## 52. demo: execute all 44 CRUD operations and restore all eleven tables

- `sql/18_crud_all_tables.sql`

## 53. test: record crud all tables evidence

- `results/crud-all-tables.txt`

## 54. test: record crud validation evidence

- `results/crud-validation.txt`

## 55. test: validate specialty and semester rules

- `sql/23_curriculum_validation.sql`

## 56. test: record curriculum validation evidence

- `results/curriculum-validation.txt`

## 57. test: verify permissions using six real teacher logins

- `scripts/CheckTeacherGrading.java`

## 58. test: record teacher authorization evidence

- `results/teacher-authorization.txt`

## 59. build: assemble the academic-year and table-list cursor release

- `scripts/Assemble-Academic-Year-SQL.py`
- `scripts/Assemble-Curriculum-SQL.py`
- `scripts/Assemble-SQL.py`
- `sql/13_build.sql`

## 60. test: record full build validation evidence

- `results/full-build-validation.txt`

## 61. data: export current fictional sample records

- `sql/09_sample_data.sql`

## 62. test: record sample data evidence

- `results/sample-data.txt`

## 63. docs: extract current report data

- `sql/14_documentation_data.sql`

## 64. test: record documentation data evidence

- `results/documentation-data.txt`

## 65. test: validate native metadata against actual Oracle schema

- `scripts/Validate-DataModeler.py`

## 66. test: record model validation evidence

- `results/model-validation.txt`

## 67. test: record schema snapshot evidence

- `results/schema-snapshot.txt`

## 68. model: synchronize complete native logical relational and physical design

- `models/university/logical/entity/seg_0/08017D41-A7A4-49A6-8E6A-A64E3A314A23.xml`
- `models/university/logical/entity/seg_0/3C568D34-718B-1372-270D-6EF980979BE6.xml`
- `models/university/logical/relation/seg_0/B82190C7-7275-158B-EDF4-859F9B484280.xml`
- `models/university/logical/subviews/0E327345-A259-0025-22A5-5A923728FDE8.xml`
- `models/university/mapping/ExtendedMap_RM1CFB6451-B9AC-ED07-5D24-908CFC3FAB15.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/foreignkey/seg_0/E33EF9F8-9CFA-DE7D-4545-16AD6E3E773A.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/Table/seg_0/482E6F98-6F19-4959-94AC-F85C091ED33D.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/Table/seg_0/ED8E42E8-3AC9-7C2D-25D1-25483ECD2C16.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/subviews/5EF645B8-FD94-1BAE-8730-90A127B2F2E9.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/table/seg_0/482E6F98-6F19-4959-94AC-F85C091ED33D.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/table/seg_0/ED8E42E8-3AC9-7C2D-25D1-25483ECD2C16.xml`

## 69. diagram: refresh logical model visualization

- `docs/diagrams/logical.pdf`
- `docs/diagrams/logical.png`
- `docs/diagrams/logical.svg`

## 70. diagram: refresh relational model visualization

- `docs/diagrams/relational.pdf`
- `docs/diagrams/relational.png`
- `docs/diagrams/relational.svg`

## 71. docs: explain every table and normalization

- `docs/data-dictionary.md`

## 72. docs: explain specialty-specific teaching and semesters

- `docs/curriculum-change.md`

## 73. docs: explain authenticated grading boundaries

- `docs/grading-authorization.md`

## 74. docs: document CRUD coverage and rollback

- `docs/crud-coverage.md`

## 75. docs: explain current reports and table-list cursor usage

- `docs/usage-and-results.md`

## 76. docs: explain the saved academic-year model keys

- `models/README.md`

## 77. docs: refresh portfolio overview

- `README.md`

## 78. docs: record local commit authorization and project progress

- `docs/activity-log.md`

## 79. docs: record the authorized granular commit plan

- `docs/review-of-changes.md`

## 80. test: record pdf visual validation evidence

- `results/pdf-visual-validation.txt`

## 81. chore: refresh scripts/Render-DataModeler-Diagrams.py

- `scripts/Render-DataModeler-Diagrams.py`

## 82. docs: record granular local commit history

- `docs/commit-log.md`
