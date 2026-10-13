# Oracle University Database

An Oracle SQL / PL/SQL portfolio project by **Dimitar Atanasov**. It models students,
teachers, disciplines, grades and shared teaching assignments in a normalized schema.

![Relational database model](docs/diagrams/relational.png)

## What it demonstrates

- 10 tables, 35 columns, 10 foreign keys, composite keys and referential integrity.
- A many-to-many teacher/discipline relationship through `DISCIPLINE_TEACHERS`.
- Full CRUD for **every table**: 40 executed operations, not empty examples.
- Transactional PL/SQL operations with savepoints, rollback and business validation.
- Academic transcripts, averages, failed exams and student/teacher rankings.
- Sequences, BEFORE/AFTER triggers, explicit cursors and `%TYPE` procedures.
- Concurrent-session checks and a reproducible build tested in an isolated schema.
- Native Oracle Data Modeler logical and relational models.

The latest verification passed **209 Oracle checks** and **333 native model checks**.
All sample people, phone numbers and `university.example` addresses are fictional.

## Run locally

The project was executed on Oracle Database 11g XE (11.2.0.2).
Use an empty `UNIVERSITY_PROJECT` schema with `CREATE SESSION`, `CREATE TABLE`,
`CREATE VIEW`, `CREATE SEQUENCE`, `CREATE PROCEDURE`, `CREATE TRIGGER`, and enough
quota in `USERS`. Choose your own password locally.

1. Open `sql/13_build.sql` in Oracle SQL Developer and use **Run Script (F5)**.
   This self-contained script creates the schema, programs, sample data and checks.
   It refuses to overwrite an existing project schema.
2. Run `sql/06_reports.sql` for the parameterized reports.
3. Run `sql/18_crud_all_tables.sql` for all 40 CRUD operations.
4. Run `sql/19_crud_validation.sql` for the 20 DELETE safety checks.
5. Open `models/university.dmd` in Oracle Data Modeler. Keep the accompanying
   `models/university/` folder beside it.

The CRUD scripts roll back their own table changes. Oracle sequences still advance.
Direct DML against the five core tables is guarded; use `UNIVERSITY_API`.
`sql/15_migrate_many_teachers.sql` is only for the earlier single-teacher schema.

## CRUD coverage

| Tables | Create | Read | Update | Delete |
|---|---|---|---|---|
| SPECIALTIES, ACADEMIC_TITLES, STUDY_YEARS, SEMESTERS, GRADE_SCALE | INSERT | SELECT | UPDATE | DELETE |
| STUDENTS, TEACHERS, DISCIPLINES, GRADES | API / INSERT procedure | SELECT | API / UPDATE procedure | API DELETE method |
| DISCIPLINE_TEACHERS | assign_teacher | SELECT | replace_teacher | unassign_teacher |

Deleting a course or teaching assignment must preserve the minimum counts:
each student has at least two graded courses, each teacher teaches at least two
different courses, and each course has at least one teacher. Invalid operations
roll back atomically without discarding earlier changes made by the caller.

The five-value grade scale uses a temporary savepoint fixture to demonstrate an
actual INSERT; foreign keys and checks stay enabled throughout.

## Verification evidence

| Suite | Checks | Recorded output |
|---|---:|---|
| Core business rules | 47 | [validation.txt](results/validation.txt) |
| Procedures and cursors | 34 | [lesson-validation.txt](results/lesson-validation.txt) |
| Many-to-many teaching | 47 | [many-teachers-validation.txt](results/many-teachers-validation.txt) |
| Two concurrent Oracle sessions | 10 | [concurrency-validation.txt](results/concurrency-validation.txt) |
| CRUD operations and data restoration | 51 | [crud-all-tables.txt](results/crud-all-tables.txt) |
| DELETE safety and atomicity | 20 | [crud-validation.txt](results/crud-validation.txt) |
| Native model structure | 333 | [model-validation.txt](results/model-validation.txt) |

The [full build output](results/full-build-validation.txt) also records cleanup of
the isolated verification schema. Repeated checks during that build are not counted
again in the 209 total. Data-preservation and model-geometry checks are separate.

## Project documentation

- [CRUD explanation and operation matrix (Bulgarian)](docs/crud-coverage.md)
- [Data dictionary and normalization](docs/data-dictionary.md)
- [Relationship matrix](docs/relationship-matrix.md)
- [Usage and reports](docs/usage-and-results.md)
- [Many-to-many teaching design](docs/many-teachers-change.md)
- [Logical model](docs/diagrams/logical.pdf) / [relational model](docs/diagrams/relational.pdf)

The diagrams are rendered from the saved native model. The native project was also
opened and saved in Oracle Data Modeler. This is a coursework-scale design: core
writes use table locks with NOWAIT to preserve cross-row minimum counts.
