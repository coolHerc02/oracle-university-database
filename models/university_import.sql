create table specialties (
    specialty_id number not null,
    specialty_name varchar2(120 char) not null,
    constraint specialties_pk primary key (specialty_id),
    constraint specialties_name_uq unique (specialty_name),
    constraint specialties_id_ck check (specialty_id > 0 and specialty_id = trunc(specialty_id)),
    constraint specialties_name_ck check (trim(specialty_name) is not null)
);

create table academic_titles (
    title_id number not null,
    title_name varchar2(80 char) not null,
    constraint academic_titles_pk primary key (title_id),
    constraint academic_titles_name_uq unique (title_name),
    constraint academic_titles_id_ck check (title_id > 0 and title_id = trunc(title_id)),
    constraint academic_titles_name_ck check (trim(title_name) is not null)
);

create table study_years (
    study_year_no number not null,
    year_label varchar2(30 char) not null,
    constraint study_years_pk primary key (study_year_no),
    constraint study_years_label_uq unique (year_label),
    constraint study_years_no_ck check (study_year_no > 0 and study_year_no = trunc(study_year_no)),
    constraint study_years_label_ck check (trim(year_label) is not null)
);

create table semesters (
    semester_no number not null,
    study_year_no number not null,
    term_no number not null,
    constraint semesters_pk primary key (semester_no),
    constraint semesters_year_fk foreign key (study_year_no) references study_years (study_year_no),
    constraint semesters_year_term_uq unique (study_year_no, term_no),
    constraint semesters_no_ck check (semester_no > 0 and semester_no = trunc(semester_no)),
    constraint semesters_term_ck check (term_no in (1, 2)),
    constraint semesters_order_ck check (semester_no = 2 * (study_year_no - 1) + term_no)
);

create table grade_scale (
    grade_value number not null,
    grade_label varchar2(30 char) not null,
    is_passing number not null,
    constraint grade_scale_pk primary key (grade_value),
    constraint grade_scale_label_uq unique (grade_label),
    constraint grade_scale_value_ck check (
        grade_value between 2 and 6 and grade_value = trunc(grade_value)
    ),
    constraint grade_scale_passing_ck check (
        (grade_value = 2 and is_passing = 0)
        or (grade_value between 3 and 6 and is_passing = 1)
    ),
    constraint grade_scale_label_ck check (trim(grade_label) is not null)
);

create table students (
    faculty_number varchar2(20 char) not null,
    first_name varchar2(60 char) not null,
    middle_name varchar2(60 char),
    last_name varchar2(60 char) not null,
    specialty_id number not null,
    study_year_no number not null,
    email varchar2(254 char) not null,
    constraint students_pk primary key (faculty_number),
    constraint students_specialty_fk foreign key (specialty_id) references specialties (specialty_id),
    constraint students_year_fk foreign key (study_year_no) references study_years (study_year_no),
    constraint students_number_ck check (trim(faculty_number) is not null),
    constraint students_first_name_ck check (trim(first_name) is not null),
    constraint students_last_name_ck check (trim(last_name) is not null),
    constraint students_email_ck check (email like '%_@_%._%')
);

create table teachers (
    teacher_id number not null,
    first_name varchar2(60 char) not null,
    middle_name varchar2(60 char),
    last_name varchar2(60 char) not null,
    title_id number not null,
    phone varchar2(30 char) not null,
    email varchar2(254 char) not null,
    constraint teachers_pk primary key (teacher_id),
    constraint teachers_title_fk foreign key (title_id) references academic_titles (title_id),
    constraint teachers_id_ck check (teacher_id > 0 and teacher_id = trunc(teacher_id)),
    constraint teachers_first_name_ck check (trim(first_name) is not null),
    constraint teachers_last_name_ck check (trim(last_name) is not null),
    constraint teachers_phone_ck check (trim(phone) is not null),
    constraint teachers_email_ck check (email like '%_@_%._%')
);

create table disciplines (
    discipline_id number not null,
    discipline_name varchar2(150 char) not null,
    constraint disciplines_pk primary key (discipline_id),
    constraint disciplines_id_ck check (discipline_id > 0 and discipline_id = trunc(discipline_id)),
    constraint disciplines_name_ck check (trim(discipline_name) is not null)
);

create table curriculum (
    curriculum_id number not null,
    specialty_id number not null,
    discipline_id number not null,
    semester_no number not null,
    constraint curriculum_pk primary key (curriculum_id),
    constraint curriculum_course_uq unique (specialty_id, discipline_id),
    constraint curriculum_id_ck check (curriculum_id > 0 and curriculum_id = trunc(curriculum_id)),
    constraint curriculum_specialty_fk foreign key (specialty_id) references specialties(specialty_id),
    constraint curriculum_discipline_fk foreign key (discipline_id) references disciplines(discipline_id),
    constraint curriculum_semester_fk foreign key (semester_no) references semesters(semester_no)
);

create table discipline_teachers (
    curriculum_id number not null,
    teacher_id number not null,
    constraint discipline_teachers_pk primary key (curriculum_id, teacher_id),
    constraint dt_curriculum_fk foreign key (curriculum_id) references curriculum (curriculum_id),
    constraint dt_teacher_fk foreign key (teacher_id) references teachers (teacher_id)
);

create table grades (
    faculty_number varchar2(20 char) not null,
    curriculum_id number not null,
    grade_value number not null,
    grade_date date not null,
    teacher_id number not null,
    constraint grades_pk primary key (faculty_number, curriculum_id),
    constraint grades_student_fk foreign key (faculty_number) references students (faculty_number),
    constraint grades_assignment_fk foreign key (curriculum_id, teacher_id)
        references discipline_teachers (curriculum_id, teacher_id),
    constraint grades_value_fk foreign key (grade_value) references grade_scale (grade_value)
);

create index students_specialty_ix on students (specialty_id);
create index students_year_ix on students (study_year_no);
create index teachers_title_ix on teachers (title_id);
create index curriculum_discipline_ix on curriculum(discipline_id);
create index curriculum_semester_ix on curriculum(semester_no);
create index dt_teacher_ix on discipline_teachers (teacher_id);
create index grades_assignment_ix on grades (curriculum_id, teacher_id);
create index grades_value_ix on grades (grade_value);
-- grades_pk covers the student FK; semesters_year_term_uq covers the year FK.

create sequence curriculum_seq start with 1 increment by 1 nocache;
create sequence specialties_seq start with 100 increment by 1 nocache;
create sequence academic_titles_seq start with 100 increment by 1 nocache;
create sequence teachers_seq start with 1 increment by 1 nocache;
create sequence disciplines_seq start with 1 increment by 1 nocache;

comment on table specialties is 'Specialty reference data. Names are stored once.';
comment on table academic_titles is 'Academic title reference data for teachers.';
comment on table study_years is 'Permitted current study years and their display labels.';
comment on table semesters is 'Global semester number and its study year/term mapping.';
comment on table grade_scale is 'Bulgarian integer grade scale 2-6 with labels and passing status.';
comment on table students is 'Students. Each must have grades in at least two distinct disciplines after a completed operation.';
comment on table teachers is 'Teachers. Each must lead at least two distinct disciplines after a completed operation.';
comment on table disciplines is 'Course catalogue. Semester belongs to the specialty curriculum, not to this catalogue.';
comment on table curriculum is 'One course in a specialty curriculum and its semester. Each entry has one or more assigned teachers.';
comment on table discipline_teachers is 'Teaching assignments per specialty curriculum entry. Composite PK prevents duplicate pairs. Each curriculum entry has a teacher; each teacher leads at least two distinct catalogue disciplines.';
comment on table grades is 'One mandatory grade and date for every recorded student-discipline pair. Corrections use UPDATE.';

comment on column students.faculty_number is 'Text identifier preserving leading zeroes and letters.';
comment on column students.middle_name is 'Optional middle or patronymic name.';
comment on column teachers.phone is 'Text phone number preserving prefix, plus sign and leading zeroes.';
comment on column semesters.term_no is 'First or second semester within the study year.';
comment on column grades.grade_date is 'Date of the examination/grade.';
comment on column grades.teacher_id is 'Responsible grading teacher. Must be assigned to the same discipline. Teacher sessions derive this identity from SESSION_USER.';
comment on column grade_scale.is_passing is '0 for grade 2; 1 for grades 3 through 6.';

