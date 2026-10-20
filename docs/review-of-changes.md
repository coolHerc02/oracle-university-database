# Предложени комити за непубликуваните промени

Рецензия и план по AGENTS.md. На 20.10.2026 потребителят изрично разреши комитване на всички промени след преглед.
Планът е записан преди изпълнението; действително създадените комити и точните им файлове са в docs/commit-log.md.
Списъкът е получен от действителния Git diff и новите файлове на локалното Portfolio_Project.
Пътищата по-долу са относителни към това хранилище. Предложенията обхващат и непубликуваната предходна промяна за преподавателски права.
Schema/API/build/migration групите са зависими и трябва да се разглеждат като съгласуван release.
Native XML файловете се запазват в един неделим commit, за да не се разкъсат registries, UID и връзки.
Няма включени пароли, реален факултетен номер, академичен отчет, backup или .local данни.

## 1. db: add specialty curriculum and scoped grade keys

- `models/university_import.sql`
- `sql/01_schema.sql`

## 2. db: enforce curriculum rules in transactional admin API

- `sql/02_programs.sql`

## 3. db: authorize grading by login and specialty

- `sql/20_teacher_grading.sql`

## 4. setup: initialize and verify individual teacher accounts with minimal grants

- `results/teacher-account-privileges.txt`
- `scripts/Initialize-TeacherAccounts.ps1`

## 5. test: validate all Oracle physical constraint proxies

- `results/physical-model-validation.txt`
- `scripts/Validate-PhysicalModel.py`

## 6. style: normalize text line endings for reproducible diffs

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

## 7. data: populate curricula for original specialties

- `sql/03_seed_data.sql`

## 8. data: demonstrate SA in SIT semester 6 and KST semester 4

- `results/curriculum-example.txt`
- `sql/25_curriculum_example.sql`

## 9. migration: upgrade existing grading schema without discarding data

- `results/curriculum-migration.txt`
- `sql/24_migrate_curriculum.sql`

## 10. test: rehearse curriculum migration in isolated schema

- `results/curriculum-migration-rehearsal.txt`

## 11. test: prove original rows and fields survive curriculum migration

- `results/curriculum-data-preservation.txt`

## 12. migration: preserve earlier grading release upgrade

- `results/grade-teacher-data-preservation.txt`
- `results/grade-teacher-migration-rehearsal.txt`
- `results/grade-teacher-migration.txt`
- `sql/21_migrate_grade_teacher.sql`

## 13. migration: retain historical single-teacher upgrade

- `sql/15_migrate_many_teachers.sql`

## 14. test: validate core business rules

- `results/validation.txt`
- `sql/07_validation.sql`

## 15. db: adapt standalone procedures and cursors

- `sql/10_standalone_programs.sql`

## 16. demo: update lesson procedure examples

- `results/lesson-demo.txt`
- `sql/11_lesson_demo.sql`

## 17. test: validate procedures and cursor output

- `results/lesson-validation.txt`
- `sql/12_lesson_validation.sql`

## 18. test: validate scoped many-to-many assignments

- `results/many-teachers-validation.txt`
- `sql/16_many_teachers_validation.sql`

## 19. demo: show curriculum-specific teacher lists

- `results/many-teachers-demo.txt`

## 20. demo: execute all 44 CRUD operations and restore all eleven tables

- `results/crud-all-tables.txt`
- `sql/18_crud_all_tables.sql`

## 21. test: retain DELETE atomicity and minimum counts

- `results/crud-validation.txt`
- `sql/19_crud_validation.sql`

## 22. test: validate composite grade assignment FK

- `results/grade-teacher-validation.txt`
- `sql/22_grade_teacher_validation.sql`

## 23. test: validate specialty and semester rules

- `results/curriculum-validation.txt`
- `sql/23_curriculum_validation.sql`

## 24. test: verify permissions using six real teacher logins

- `results/teacher-authorization.txt`
- `scripts/CheckTeacherGrading.java`

## 25. test: verify two-session writer isolation

- `scripts/CheckConcurrentWrites.java`

## 26. build: assemble and verify current release from an empty schema

- `results/full-build-validation.txt`
- `scripts/Assemble-Curriculum-SQL.py`
- `scripts/Assemble-SQL.py`
- `sql/13_build.sql`

## 27. query: show curriculum context in reports

- `results/reports.txt`
- `sql/06_reports.sql`

## 28. data: export current fictional sample records

- `results/sample-data.txt`
- `sql/09_sample_data.sql`

## 29. docs: extract current report data

- `results/documentation-data.txt`
- `sql/14_documentation_data.sql`

## 30. test: validate native metadata against actual Oracle schema

- `results/model-validation.txt`
- `results/native-layout-validation.txt`
- `results/schema-snapshot.txt`
- `scripts/Validate-DataModeler.py`

## 31. model: synchronize complete native logical relational and physical design

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

## 32. diagram: refresh logical model visualization

- `docs/diagrams/logical.pdf`
- `docs/diagrams/logical.png`
- `docs/diagrams/logical.svg`

## 33. diagram: refresh relational model visualization

- `docs/diagrams/relational.pdf`
- `docs/diagrams/relational.png`
- `docs/diagrams/relational.svg`

## 34. docs: explain every table and normalization

- `docs/data-dictionary.md`

## 35. docs: map all twelve direct relationships

- `docs/relationship-matrix.md`

## 36. docs: explain specialty-specific teaching and semesters

- `docs/curriculum-change.md`
- `docs/many-teachers-change.md`

## 37. docs: explain authenticated grading boundaries

- `docs/grading-authorization.md`

## 38. docs: document CRUD coverage and rollback

- `docs/crud-coverage.md`

## 39. docs: update usage and model opening instructions

- `docs/usage-and-results.md`
- `models/README.md`

## 40. docs: refresh portfolio overview

- `README.md`

## 41. docs: record review results and authorized commit plan

- `docs/activity-log.md`
- `docs/pre-commit-review.md`
- `docs/review-of-changes.md`

## 42. chore: refresh results/data-corrections.txt

- `results/data-corrections.txt`

## 43. chore: refresh results/pdf-visual-validation.txt

- `results/pdf-visual-validation.txt`

## 44. chore: refresh scripts/Render-DataModeler-Diagrams.py

- `scripts/Render-DataModeler-Diagrams.py`

## 45. chore: refresh scripts/Validate-Model-Geometry.py

- `scripts/Validate-Model-Geometry.py`

## 46. style: remove trailing blank lines from exported text

- `models/university_import.sql`
- `results/lesson-programs-compilation.txt`
- `results/migration-rehearsal.txt`
- `results/search.txt`

## 47. docs: record completed commit groups

- `docs/commit-log.md`
