# Автентикирано оценяване

GRADES има PK(faculty_number,curriculum_id) и FK(curriculum_id,teacher_id) към DISCIPLINE_TEACHERS.
Преподавателят трябва да е назначен към конкретната дисциплина В СЪОТВЕТНАТА СПЕЦИАЛНОСТ.
UNIVERSITY_API проверява и равенството между специалността на студента и учебния план.

TEACHER_GRADING определя самоличността от SYS_CONTEXT('USERENV','SESSION_USER'). UP_TEACHER_<teacher_id> е отделен Oracle вход за всеки преподавател.
Преподавателските акаунти имат само CREATE SESSION и EXECUTE върху UNIVERSITY_PROJECT.TEACHER_GRADING.
Нямат достъп до базовите таблици или административния UNIVERSITY_API. CURRENT_SCHEMA и CLIENT_IDENTIFIER не могат да подменят SESSION_USER.
UNIVERSITY_PROJECT остава довереният административен собственик на схемата.

```sql
variable teacher_result refcursor
exec university_project.teacher_grading.read_grades(:teacher_result);
print teacher_result
exec university_project.teacher_grading.update_grade('00010001',1,5,date '2026-10-20');
rollback;
```

Има insert_grade и delete_grade със същите граници на достъп. INSERT отказва дублирана оценка; UPDATE отказва липсваща.
DELETE пази минимума две дисциплини. За чужд учебен план се връща ORA-20102; за липсващ студент/учебен план - ORA-20141.
Редакцията записва действителния преподавател, направил текущата корекция; това не е пълна история на промените.
Назначение, използвано от оценка, не може да се премахне поради FK (ORA-02292).

49 проверки с шестте реални акаунта са успешни, включително СА/КСТ разрешено и СА/СИТ отказано за преподавател 2.
Две конкурентни сесии преминават още 10 проверки. Използват се table locks NOWAIT: конкурентният запис получава ORA-00054 и се повтаря след освобождаване.
Това е подход за учебен проект; при голямо натоварване е необходим по-фин механизъм за заключване.

Локалните случайни пароли са защитени чрез Windows DPAPI и не са включени в ZIP/публичното портфолио.
scripts/Initialize-TeacherAccounts.ps1 е отделна административна стъпка, която се изпълнява само с разрешение за създаване на акаунти.
[Промяна на учебния план](curriculum-change.md). [Резултат от проверките](../results/teacher-authorization.txt).
