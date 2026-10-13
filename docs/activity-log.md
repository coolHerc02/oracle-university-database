# Public project activity log

## 13 October 2026: many-to-many teaching
Introduced DISCIPLINE_TEACHERS with a composite primary key and two foreign keys.
Preserved the previous teaching assignments and all original student/grade data.
Updated both native Data Modeler models; the owner opened and saved them.
333 structural checks and separate diagram geometry checks passed.

## 13 October 2026: complete CRUD
Added four atomic DELETE methods to UNIVERSITY_API. Executed 40 CRUD operations
across all ten tables, followed by exact row/field comparisons after rollback.
51 CRUD checks and 20 DELETE safety checks passed. Existing suites were repeated:
47 core, 34 lesson, 47 many-to-many and 10 concurrency checks. Total: 209.
The self-contained build was executed in a fresh isolated schema, then that
verification schema was removed. The original project schema remains available.

The public export contains fictional sample data, source SQL, native models,
diagrams and recorded verification output. Private credentials, original course
materials and the academic report containing a real faculty number are excluded.
