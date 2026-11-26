# Project activity

- Normalized university schema, reports, PL/SQL procedures, triggers and cursors.
- Many-to-many teaching, full CRUD and separate authenticated teacher logins.
- 20 October 2026: CURRICULUM; SA in SIT semester 6 and KST semester 4.
- All original rows preserved; two fictional students added for the specialty example.
- Native models and physical metadata updated; owner opened and saved them successfully.
- 338 Oracle and 384 native structural checks passed, including six real teacher logins.
- Cold build verified in a separate schema, then cleaned up.
- 20 October 2026: pre-commit review fixed CURRICULUM physical UNIQUE/CHECK proxies;
  66 additional storage-metadata checks cover all eleven tables.
- Commits are authorized by the owner; see docs/commit-log.md for the completed commit groups.
- 3 November 2026: added academic-year appointment identities and matching grade FKs; original rows preserved.
- 338 Oracle checks, including 30 academic-year and 53 authenticated-teacher checks, passed.
- 3 November 2026: academic-year changes were prepared locally before commit authorization.
- 19 November 2026: reviewed instructor whiteboard notes; meaningful report filters, key-only grouping subqueries and full object details.
- Added title and specialty keyword cursors; 377 Oracle and 31 SELECT source checks passed; all eleven base tables preserved.
- 19 November 2026: the reporting update was prepared locally for review.
- 26 November 2026: eleven standalone SELECTs and matching read-only cursor procedures, with optional meaningful filters.
- 91 new Oracle checks and 57 query/procedure source checks passed; the current suite has 468 Oracle checks.

- 26 November 2026: the owner explicitly authorized granular local commits; the exact history and file membership are recorded in docs/commit-log.md.
