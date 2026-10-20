# M:N преподаване - историческа стъпка и текущо състояние

Първата промяна изнесе преподавателя от DISCIPLINES в DISCIPLINE_TEACHERS.
Следващата добави автора на оценката и реални преподавателски входове.
Текущата версия уточнява назначението по специалност чрез CURRICULUM.
Сега ключът е (curriculum_id,teacher_id), а не (discipline_id,teacher_id).
[Актуално описание](curriculum-change.md). [Права](grading-authorization.md).
