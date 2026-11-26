# Изпълнени комити - 20.10.2026

Потребителят изрично разреши всички промени да бъдат комитнати след преглед.
Преди комитване са успешни 304 Oracle, 371 native структурни, пет групи геометрични и 66 физически проверки.
Отстранените неточности са описани в pre-commit-review.md. Не е извършван push.
Точните файлове на функционалните комити са изброени по-долу.
Последният комит добавя само този дневник; неговият хеш се вижда с git log -1.

## 0d105d6980 - db: add specialty curriculum and scoped grade keys

- `models/university_import.sql`
- `sql/01_schema.sql`

## 80a6d8a498 - db: enforce curriculum rules in transactional admin API

- `sql/02_programs.sql`

## 565d3b8007 - db: authorize grading by login and specialty

- `sql/20_teacher_grading.sql`

## fc759de342 - setup: initialize and verify individual teacher accounts with minimal grants

- `results/teacher-account-privileges.txt`
- `scripts/Initialize-TeacherAccounts.ps1`

## 74d59b7a90 - test: validate all Oracle physical constraint proxies

- `results/physical-model-validation.txt`
- `scripts/Validate-PhysicalModel.py`

## 425a889199 - style: normalize text line endings for reproducible diffs

- `.gitattributes`
- `.gitignore`
- `models/university.dmd`
- `results/concurrency-validation.txt`
- `results/lesson-programs-compilation.txt`
- `results/migration-data-preservation.txt`
- `results/migration-many-teachers.txt`
- `results/migration-rehearsal.txt`
- `results/search.txt`
- `sql/00_environment_smoke_test.sql`
- `sql/04_data_corrections.sql`
- `sql/05_search.sql`
- `sql/08_schema_snapshot.sql`
- `sql/17_many_teachers_demo.sql`

## 4a61574b6a - data: populate curricula for original specialties

- `sql/03_seed_data.sql`

## 95864b035e - data: demonstrate SA in SIT semester 6 and KST semester 4

- `results/curriculum-example.txt`
- `sql/25_curriculum_example.sql`

## c098cdf3f3 - migration: upgrade existing grading schema without discarding data

- `results/curriculum-migration.txt`
- `sql/24_migrate_curriculum.sql`

## 354fb5e50a - test: rehearse curriculum migration in isolated schema

- `results/curriculum-migration-rehearsal.txt`

## f1b7fe12f1 - test: prove original rows and fields survive curriculum migration

- `results/curriculum-data-preservation.txt`

## a86db0df4b - migration: preserve earlier grading release upgrade

- `results/grade-teacher-data-preservation.txt`
- `results/grade-teacher-migration-rehearsal.txt`
- `results/grade-teacher-migration.txt`
- `sql/21_migrate_grade_teacher.sql`

## 48b7f7c826 - migration: retain historical single-teacher upgrade

- `sql/15_migrate_many_teachers.sql`

## ed79c9e294 - test: validate core business rules

- `results/validation.txt`
- `sql/07_validation.sql`

## 39b8b76961 - db: adapt standalone procedures and cursors

- `sql/10_standalone_programs.sql`

## a2ea33fff7 - demo: update lesson procedure examples

- `results/lesson-demo.txt`
- `sql/11_lesson_demo.sql`

## b9261b1a12 - test: validate procedures and cursor output

- `results/lesson-validation.txt`
- `sql/12_lesson_validation.sql`

## 4979c74e7b - test: validate scoped many-to-many assignments

- `results/many-teachers-validation.txt`
- `sql/16_many_teachers_validation.sql`

## 4b9d5c01db - demo: show curriculum-specific teacher lists

- `results/many-teachers-demo.txt`

## 1ac90a1e1a - demo: execute all 44 CRUD operations and restore all eleven tables

- `results/crud-all-tables.txt`
- `sql/18_crud_all_tables.sql`

## 0e570797d5 - test: retain DELETE atomicity and minimum counts

- `results/crud-validation.txt`
- `sql/19_crud_validation.sql`

## ea8756df7b - test: validate composite grade assignment FK

- `results/grade-teacher-validation.txt`
- `sql/22_grade_teacher_validation.sql`

## 46d30a8cd0 - test: validate specialty and semester rules

- `results/curriculum-validation.txt`
- `sql/23_curriculum_validation.sql`

## 950d730cd0 - test: verify permissions using six real teacher logins

- `results/teacher-authorization.txt`
- `scripts/CheckTeacherGrading.java`

## 60a2e5679e - test: verify two-session writer isolation

- `scripts/CheckConcurrentWrites.java`

## d4fd2af2de - build: assemble and verify current release from an empty schema

- `results/full-build-validation.txt`
- `scripts/Assemble-Curriculum-SQL.py`
- `scripts/Assemble-SQL.py`
- `sql/13_build.sql`

## 06230dbe85 - query: show curriculum context in reports

- `results/reports.txt`
- `sql/06_reports.sql`

## 90b23c2f08 - data: export current fictional sample records

- `results/sample-data.txt`
- `sql/09_sample_data.sql`

## 821d7ac7aa - docs: extract current report data

- `results/documentation-data.txt`
- `sql/14_documentation_data.sql`

## 79532ef333 - test: validate native metadata against actual Oracle schema

- `results/model-validation.txt`
- `results/native-layout-validation.txt`
- `results/schema-snapshot.txt`
- `scripts/Validate-DataModeler.py`

## e90bcf9b03 - model: synchronize complete native logical relational and physical design

- `models/university/businessinfo/Business Information.xml`
- `models/university/datatypes/DataTypes.xml`
- `models/university/datatypes/Diagrams.local`
- `models/university/datatypes/structuredtype/seg_0/47E390DE-0671-C4B1-8428-0F45CBEE18F8.xml`
- `models/university/datatypes/structuredtype/seg_0/F72C39E0-D1CA-8821-2AD7-A1E95A37D3D1.xml`
- `models/university/datatypes/subviews/2F45A1F2-3695-76F4-2D7D-619B477B4234.xml`
- `models/university/dl_settings.xml`
- `models/university/dmd_open.local`
- `models/university/logical/Logical.xml`
- `models/university/logical/Objects.local`
- `models/university/logical/entity/seg_0/08017D41-A7A4-49A6-8E6A-A64E3A314A23.xml`
- `models/university/logical/entity/seg_0/0B3DAEBC-2CB0-FDBF-C57D-6384D99C0561.xml`
- `models/university/logical/entity/seg_0/1574A96A-145A-9FC7-49D8-D1FA33460426.xml`
- `models/university/logical/entity/seg_0/15CF4E98-FE7D-2159-2F09-F2DCF1499ADB.xml`
- `models/university/logical/entity/seg_0/3863CE93-7777-24ED-4876-75F66315FBF2.xml`
- `models/university/logical/entity/seg_0/3C568D34-718B-1372-270D-6EF980979BE6.xml`
- `models/university/logical/entity/seg_0/4A94C426-876D-4437-B066-DAA84E9B3241.xml`
- `models/university/logical/entity/seg_0/A08F57AD-DE97-A646-8978-268D88D7089F.xml`
- `models/university/logical/entity/seg_0/A7788236-1D66-7223-651F-26E754E7C746.xml`
- `models/university/logical/entity/seg_0/E9465718-8DE7-918F-3D6B-AC7B9ED198AA.xml`
- `models/university/logical/entity/seg_0/E9A93E80-2E46-FB44-E645-C373BB5656E6.xml`
- `models/university/logical/relation/seg_0/07933D0C-3571-48DC-8B78-79364B7DA8A7.xml`
- `models/university/logical/relation/seg_0/24762094-EF98-4B57-AC91-2C1EE2755913.xml`
- `models/university/logical/relation/seg_0/3577DB05-ADEC-176E-3338-C5E3E672DF3D.xml`
- `models/university/logical/relation/seg_0/5DFAB363-8DB6-4CBF-BDD3-882C2F294993.xml`
- `models/university/logical/relation/seg_0/88E10790-25B3-9921-DF09-AD33B4FD30E6.xml`
- `models/university/logical/relation/seg_0/9BD4137A-A875-13AA-DE2A-E6D275EDF1CD.xml`
- `models/university/logical/relation/seg_0/B07022AA-657B-EC8E-F8E3-526106E82A52.xml`
- `models/university/logical/relation/seg_0/B82190C7-7275-158B-EDF4-859F9B484280.xml`
- `models/university/logical/relation/seg_0/BE38F1D8-FC6F-38A1-C3E6-0E22841ABA1A.xml`
- `models/university/logical/relation/seg_0/D84E43B7-73F4-4731-A483-3403A0B30A3D.xml`
- `models/university/logical/relation/seg_0/E8172360-9BD4-90E6-F53E-F88BCC9FDBC5.xml`
- `models/university/logical/relation/seg_0/F89677A3-DDB2-4A06-A955-FA8210B0FC50.xml`
- `models/university/logical/subviews/0E327345-A259-0025-22A5-5A923728FDE8.xml`
- `models/university/mapping/DeletedMap_RM1CFB6451-B9AC-ED07-5D24-908CFC3FAB15.xml`
- `models/university/mapping/ExtendedMap.xml`
- `models/university/mapping/ExtendedMap_RM1CFB6451-B9AC-ED07-5D24-908CFC3FAB15.xml`
- `models/university/pm/Process Model.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/Objects.local`
- `models/university/rel/1CFB6451-908CFC3FAB15/foreignkey/seg_0/397AFC19-5D12-150C-4245-BE4EDE398898.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/foreignkey/seg_0/3A61B0F6-214E-8A65-5739-1CBFDBF92842.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/foreignkey/seg_0/91D783E7-1D22-F3C7-D65B-413489EF3863.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/foreignkey/seg_0/B2C6DA89-4843-472D-874C-1BE0788B15FD.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/foreignkey/seg_0/B5F77DD9-F15B-ABFE-E150-5FCF49A30CD7.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/foreignkey/seg_0/CC294951-1B2E-4A1A-980D-618E08EAE313.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/foreignkey/seg_0/CF287B3D-981A-2806-F8F7-6774E8BE7A65.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/foreignkey/seg_0/D3D35D7C-A2F2-4A5F-8471-EE55779122BC.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/foreignkey/seg_0/DCEC6D86-F9DF-D6BD-3F1B-FB514E361B18.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/foreignkey/seg_0/DF80BE23-6E40-4899-BF3C-162F5DF4509D.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/foreignkey/seg_0/E149ED2A-2FEA-C0E7-8D31-F9E70AD5462E.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/foreignkey/seg_0/E33EF9F8-9CFA-DE7D-4545-16AD6E3E773A.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/32076570-BF29817DFF70.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/Objects.local`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/SType/seg_0/47E390DE-0671-C4B1-8428-0F45CBEE18F8.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/SType/seg_0/F72C39E0-D1CA-8821-2AD7-A1E95A37D3D1.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/Sequence/seg_0/A1340E1A-A355-8263-8BC5-AE89AB192000.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/Sequence/seg_0/A49461E7-8BFE-6D8A-7894-2EA14E2EFBBD.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/Sequence/seg_0/C3651A62-F797-FC72-8D52-C6292B5EED24.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/Sequence/seg_0/DB11DA23-9DA8-8AB8-285A-DAAA65FEBF54.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/Table/seg_0/0DCD2481-E061-2D83-1706-CEF19F14DFD0.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/Table/seg_0/10AC015B-BD51-26AB-723A-E1DF6E978424.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/Table/seg_0/482E6F98-6F19-4959-94AC-F85C091ED33D.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/Table/seg_0/56025D48-265A-7504-9A8D-A232A14A5D1A.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/Table/seg_0/85CC84A1-642B-978D-0182-4AABF4A1E555.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/Table/seg_0/8AD0092F-24C2-5F11-AC75-1E3921AF8B6B.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/Table/seg_0/963E6A4B-F718-4085-25CA-686E4C4DCCE2.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/Table/seg_0/C5BA3C56-4C8B-0EF6-80E5-684EB15C1E3D.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/Table/seg_0/D9C955F5-06C8-4E18-AEBC-FB9A63CC760C.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/Table/seg_0/DF24936E-BD5C-637F-9EA7-B579796B8071.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/Table/seg_0/ED8E42E8-3AC9-7C2D-25D1-25483ECD2C16.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/User/seg_0/MDSYS.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/phys/32076570-BF29817DFF70/User/seg_0/PUBLIC.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/subviews/5EF645B8-FD94-1BAE-8730-90A127B2F2E9.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/table/seg_0/0DCD2481-E061-2D83-1706-CEF19F14DFD0.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/table/seg_0/10AC015B-BD51-26AB-723A-E1DF6E978424.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/table/seg_0/482E6F98-6F19-4959-94AC-F85C091ED33D.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/table/seg_0/56025D48-265A-7504-9A8D-A232A14A5D1A.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/table/seg_0/85CC84A1-642B-978D-0182-4AABF4A1E555.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/table/seg_0/8AD0092F-24C2-5F11-AC75-1E3921AF8B6B.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/table/seg_0/963E6A4B-F718-4085-25CA-686E4C4DCCE2.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/table/seg_0/C5BA3C56-4C8B-0EF6-80E5-684EB15C1E3D.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/table/seg_0/D9C955F5-06C8-4E18-AEBC-FB9A63CC760C.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/table/seg_0/DF24936E-BD5C-637F-9EA7-B579796B8071.xml`
- `models/university/rel/1CFB6451-908CFC3FAB15/table/seg_0/ED8E42E8-3AC9-7C2D-25D1-25483ECD2C16.xml`

## 624b0b1198 - diagram: refresh logical model visualization

- `docs/diagrams/logical.pdf`
- `docs/diagrams/logical.png`
- `docs/diagrams/logical.svg`

## f5c6259f42 - diagram: refresh relational model visualization

- `docs/diagrams/relational.pdf`
- `docs/diagrams/relational.png`
- `docs/diagrams/relational.svg`

## 47a58a5f17 - docs: explain every table and normalization

- `docs/data-dictionary.md`

## da0996f2d6 - docs: map all twelve direct relationships

- `docs/relationship-matrix.md`

## a0b762ca5c - docs: explain specialty-specific teaching and semesters

- `docs/curriculum-change.md`
- `docs/many-teachers-change.md`

## 2e2d67a4f5 - docs: explain authenticated grading boundaries

- `docs/grading-authorization.md`

## 846c9d91c2 - docs: document CRUD coverage and rollback

- `docs/crud-coverage.md`

## b60baf0984 - docs: update usage and model opening instructions

- `docs/usage-and-results.md`
- `models/README.md`

## e31699fbfd - docs: refresh portfolio overview

- `README.md`

## 66bc584e27 - docs: record review results and authorized commit plan

- `docs/activity-log.md`
- `docs/pre-commit-review.md`
- `docs/review-of-changes.md`

## 46a64f9d4a - chore: refresh results/data-corrections.txt

- `results/data-corrections.txt`

## 26e3cfad97 - chore: refresh results/pdf-visual-validation.txt

- `results/pdf-visual-validation.txt`

## fc3ff42a72 - chore: refresh scripts/Render-DataModeler-Diagrams.py

- `scripts/Render-DataModeler-Diagrams.py`

## f4ce7a5a92 - chore: refresh scripts/Validate-Model-Geometry.py

- `scripts/Validate-Model-Geometry.py`

## aa2bd486dc - style: remove trailing blank lines from exported text

- `models/university_import.sql`
- `results/lesson-programs-compilation.txt`
- `results/migration-rehearsal.txt`
- `results/search.txt`

# Локални комити от 26.11.2026

Потребителят изрично разреши максимално подробно разделяне на промените.
Тази серия съдържа 82 комита. Провереният release има 468 основни Oracle проверки,
91 нови проверки на списъчните курсори и 57 проверки на query/cursor съответствието.
Пълната серия е локална; push не е изпълняван в тази операция.
Базов commit: `c58a947445bf88771e04324c0cd692411024083b`.

## 1. 96dedc329883 - db: add academic year to appointment and grade keys

- `models/university_import.sql`
- `sql/01_schema.sql`

## 2. 92208eace2ba - db: scope administrative assignments and grades by academic year

- `sql/02_programs.sql`

## 3. 4e9333090bbc - db: authorize teacher grading for the exact appointment year

- `sql/20_teacher_grading.sql`

## 4. e20a526fd9c8 - migration: retain old appointments and grade authors across academic years

- `sql/26_migrate_academic_year.sql`

## 5. ea4055ffc419 - test: record academic year migration evidence

- `results/academic-year-migration.txt`

## 6. 24c43b76d10f - test: record academic year data preservation evidence

- `results/academic-year-data-preservation.txt`

## 7. 9c1602cb27a6 - test: record academic year migration rehearsal evidence

- `results/academic-year-migration-rehearsal.txt`

## 8. a0fdf9ad6c75 - test: enforce year-specific appointments and historical grade integrity

- `sql/27_academic_year_validation.sql`

## 9. 8f9071e5064a - test: record academic year validation evidence

- `results/academic-year-validation.txt`

## 10. 87cc621fc83f - demo: show different teachers in successive academic years

- `sql/28_academic_year_demo.sql`

## 11. c1f246dc815c - test: record academic year demo evidence

- `results/academic-year-demo.txt`

## 12. 28c8b1f7f996 - demo: display actual DDL and prove CRUD for all eleven tables

- `sql/29_defense_demo.sql`

## 13. a69dc27ff8e3 - test: record crud coverage audit evidence

- `results/crud-coverage-audit.txt`

## 14. 8a746c01ccef - test: record defense demo evidence

- `results/defense-demo.txt`

## 15. 3c92cbcd7714 - docs: explain year values migration and historical grade limits

- `docs/academic-year-change.md`

## 16. aec79faa8f03 - docs: prepare instructor demonstration with per-table CRUD matrix

- `docs/defense-guide.md`

## 17. a6f533aae06d - test: record current validation summary evidence

- `results/current-validation-summary.txt`

## 18. 77a812b4d1e6 - report: filter grade searches by meaningful names and show full details

- `sql/05_search.sql`

## 19. c0aa4855837f - test: record search evidence

- `results/search.txt`

## 20. ccc1f5f24c26 - report: apply instructor presentation rules to all five reports

- `sql/06_reports.sql`

## 21. 953ccde4cabc - test: record reports evidence

- `results/reports.txt`

## 22. 077a9a2ae454 - demo: explain related-object keyword searches and cursor variants

- `sql/30_teacher_select_rules_demo.sql`

## 23. bae8fcd0011c - test: record teacher select demo evidence

- `results/teacher-select-demo.txt`

## 24. 3684239df613 - test: verify homonyms literal keywords full details and rollback

- `sql/31_teacher_select_rules_validation.sql`

## 25. 40151873275f - test: record teacher select validation evidence

- `results/teacher-select-validation.txt`

## 26. b32fd2fec657 - test: audit all seven final SELECT projections filters and ordering

- `scripts/Validate-Teacher-Select-Rules.py`

## 27. 659d8377e02a - test: record teacher select source audit evidence

- `results/teacher-select-source-audit.txt`

## 28. eea492b800ba - migration: update reporting programs without modifying table data

- `sql/32_update_reporting.sql`

## 29. 8347e75ee15d - test: record reporting update evidence

- `results/reporting-update.txt`

## 30. 4bc91905cecd - test: record teacher select data preservation evidence

- `results/teacher-select-data-preservation.txt`

## 31. 5dd98ad4cf1d - docs: transcribe instructor rules and explain the university cursor example

- `docs/teacher-select-rules.md`

## 32. a227115ad009 - query: add complete filtered SELECT lists for all eleven tables

- `sql/33_select_each_table.sql`

## 33. 99a14bb4109b - test: record table selects evidence

- `results/table-selects.txt`

## 34. 39905668d253 - db: install eleven read-only declared cursor procedures

- `sql/34_cursor_procedures_each_table.sql`

## 35. e6687858e94d - test: record table cursor installation evidence

- `results/table-cursor-installation.txt`

## 36. f7c0142231c9 - demo: show all table cursors and meaningful filter examples

- `sql/35_cursor_procedures_demo.sql`

## 37. 49f9634846a9 - test: record table cursor demo evidence

- `results/table-cursor-demo.txt`

## 38. ab17577daaaf - test: validate cursor cardinality filters inputs and full data restoration

- `sql/36_cursor_procedures_validation.sql`

## 39. 727551be5b88 - test: record table cursor validation evidence

- `results/table-cursor-validation.txt`

## 40. 2704b29a7b9e - build: generate standalone queries and cursor procedures from one catalogue

- `scripts/Build-Table-Cursor-SQL.py`

## 41. 8d8cf40ec855 - test: verify query cursor equivalence and presentation rules

- `scripts/Validate-Table-Cursor-SQL.py`

## 42. 0b3f7570ab77 - test: record table cursor source audit evidence

- `results/table-cursor-source-audit.txt`

## 43. 9a860725b2a1 - test: record table cursor data preservation evidence

- `results/table-cursor-data-preservation.txt`

## 44. a0fd7cc190e0 - test: record table cursor privileges evidence

- `results/table-cursor-privileges.txt`

## 45. 13ae5085110c - data: seed original appointments in academic year 2025

- `sql/03_seed_data.sql`

## 46. 5a5a91bebb7f - data: place SIT and KST sample assignments in academic year 2026

- `sql/25_curriculum_example.sql`

## 47. 5d222146f0d2 - test: record validation evidence

- `results/validation.txt`

## 48. 489fd05aae95 - db: adapt standalone procedures and cursors

- `sql/10_standalone_programs.sql`

## 49. 9bc3e3926706 - test: record lesson demo evidence

- `results/lesson-demo.txt`

## 50. 0aec2b93c4eb - test: record lesson validation evidence

- `results/lesson-validation.txt`

## 51. 43811ce5b93f - test: validate scoped many-to-many assignments

- `sql/16_many_teachers_validation.sql`

## 52. 90314d18e1bc - demo: execute all 44 CRUD operations and restore all eleven tables

- `sql/18_crud_all_tables.sql`

## 53. 083486674217 - test: record crud all tables evidence

- `results/crud-all-tables.txt`

## 54. 8bdefb8785a5 - test: record crud validation evidence

- `results/crud-validation.txt`

## 55. edaaeb8e08ca - test: validate specialty and semester rules

- `sql/23_curriculum_validation.sql`

## 56. e83fb0176c26 - test: record curriculum validation evidence

- `results/curriculum-validation.txt`

## 57. 0901ebc39602 - test: verify permissions using six real teacher logins

- `scripts/CheckTeacherGrading.java`

## 58. 063f9ae10d2e - test: record teacher authorization evidence

- `results/teacher-authorization.txt`

## 59. b2f577f6ff65 - build: assemble the academic-year and table-list cursor release

- `scripts/Assemble-Academic-Year-SQL.py`
- `scripts/Assemble-Curriculum-SQL.py`
- `scripts/Assemble-SQL.py`
- `sql/13_build.sql`

## 60. 8f36b357b198 - test: record full build validation evidence

- `results/full-build-validation.txt`

## 61. effdbc29f87c - data: export current fictional sample records

- `sql/09_sample_data.sql`

## 62. d82a7248e409 - test: record sample data evidence

- `results/sample-data.txt`

## 63. 851046de5b46 - docs: extract current report data

- `sql/14_documentation_data.sql`

## 64. 2a36a4f25e6b - test: record documentation data evidence

- `results/documentation-data.txt`

## 65. 49e13581c58f - test: validate native metadata against actual Oracle schema

- `scripts/Validate-DataModeler.py`

## 66. 607218c3b870 - test: record model validation evidence

- `results/model-validation.txt`

## 67. ce0fbb725a79 - test: record schema snapshot evidence

- `results/schema-snapshot.txt`

## 68. c2a9145d4165 - model: synchronize complete native logical relational and physical design

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

## 69. 67df3f141520 - diagram: refresh logical model visualization

- `docs/diagrams/logical.pdf`
- `docs/diagrams/logical.png`
- `docs/diagrams/logical.svg`

## 70. fe850f44b034 - diagram: refresh relational model visualization

- `docs/diagrams/relational.pdf`
- `docs/diagrams/relational.png`
- `docs/diagrams/relational.svg`

## 71. fa95294c12df - docs: explain every table and normalization

- `docs/data-dictionary.md`

## 72. 2a282f46f530 - docs: explain specialty-specific teaching and semesters

- `docs/curriculum-change.md`

## 73. 35bfe86cd62b - docs: explain authenticated grading boundaries

- `docs/grading-authorization.md`

## 74. 8d7b232600b3 - docs: document CRUD coverage and rollback

- `docs/crud-coverage.md`

## 75. 67087bbdf29a - docs: explain current reports and table-list cursor usage

- `docs/usage-and-results.md`

## 76. ede3adf8a867 - docs: explain the saved academic-year model keys

- `models/README.md`

## 77. 539641ee33d8 - docs: refresh portfolio overview

- `README.md`

## 78. 9a85bd71bdbf - docs: record local commit authorization and project progress

- `docs/activity-log.md`

## 79. 52a621e3070e - docs: record the authorized granular commit plan

- `docs/review-of-changes.md`

## 80. b093e0b15693 - test: record pdf visual validation evidence

- `results/pdf-visual-validation.txt`

## 81. 14ce04d253f5 - chore: refresh scripts/Render-DataModeler-Diagrams.py

- `scripts/Render-DataModeler-Diagrams.py`

## 82. docs: record granular local commit history

- `docs/commit-log.md`

Последният commit записва този дневник. Неговият хеш се вижда с `git log -1`; не се вгражда в собствения му текст.
