# Дванадесет преки отношения

| Родител | Дете | Външен ключ в детето | Деца за един родител |
| --- | --- | --- | --- |
| SPECIALTIES | STUDENTS | specialty_id | 0..N |
| STUDY_YEARS | STUDENTS | study_year_no | 0..N |
| STUDY_YEARS | SEMESTERS | study_year_no | 0..2 |
| ACADEMIC_TITLES | TEACHERS | title_id | 0..N |
| SPECIALTIES | CURRICULUM | specialty_id | 0..N |
| DISCIPLINES | CURRICULUM | discipline_id | 0..N |
| SEMESTERS | CURRICULUM | semester_no | 0..N |
| CURRICULUM | DISCIPLINE_TEACHERS | curriculum_id | 1..N |
| TEACHERS | DISCIPLINE_TEACHERS | teacher_id | 2..N* |
| STUDENTS | GRADES | faculty_number | 2..N |
| DISCIPLINE_TEACHERS | GRADES | curriculum_id,teacher_id | 0..N |
| GRADE_SCALE | GRADES | grade_value | 0..N |

Всеки детски FK сочи точно един родител и е задължителен. *Минимумът за преподавател е две различни дисциплини, а не просто две назначения.
