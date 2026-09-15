CREATE DATABASE IF NOT EXISTS edugest;
USE edugest;

CREATE TABLE IF NOT EXISTS users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(150) UNIQUE,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(120),
    phone VARCHAR(20),
    role VARCHAR(30) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS schools (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(160) NOT NULL,
    code VARCHAR(80) UNIQUE,
    school_level VARCHAR(20) NOT NULL DEFAULT 'COLLEGE',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS school_memberships (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    school_id BIGINT NOT NULL,
    role VARCHAR(30) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_school_membership_user_school UNIQUE (user_id, school_id),
    CONSTRAINT fk_membership_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_membership_school FOREIGN KEY (school_id) REFERENCES schools(id)
);

CREATE TABLE IF NOT EXISTS teachers (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    speciality VARCHAR(120),
    email VARCHAR(150),
    phone VARCHAR(20),
    school_id BIGINT NULL
);

CREATE TABLE IF NOT EXISTS classrooms (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(60) NOT NULL,
    level VARCHAR(40),
    exam_class BOOLEAN NOT NULL DEFAULT FALSE,
    capacity INT NOT NULL,
    description VARCHAR(255),
    teacher_id BIGINT,
    school_id BIGINT NULL,
    CONSTRAINT fk_classroom_teacher FOREIGN KEY (teacher_id) REFERENCES teachers(id)
);

CREATE TABLE IF NOT EXISTS classroom_teachers (
    classroom_id BIGINT NOT NULL,
    teacher_id BIGINT NOT NULL,
    PRIMARY KEY (classroom_id, teacher_id),
    CONSTRAINT fk_classroom_teachers_classroom FOREIGN KEY (classroom_id) REFERENCES classrooms(id),
    CONSTRAINT fk_classroom_teachers_teacher FOREIGN KEY (teacher_id) REFERENCES teachers(id)
);

CREATE TABLE IF NOT EXISTS teacher_attendance (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    school_id BIGINT NOT NULL,
    teacher_id BIGINT NOT NULL,
    attendance_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL,
    recorded_by_id BIGINT NOT NULL,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_teacher_attendance_school_teacher_date
        UNIQUE (school_id, teacher_id, attendance_date),
    CONSTRAINT fk_teacher_attendance_school FOREIGN KEY (school_id) REFERENCES schools(id),
    CONSTRAINT fk_teacher_attendance_teacher FOREIGN KEY (teacher_id) REFERENCES teachers(id),
    CONSTRAINT fk_teacher_attendance_user FOREIGN KEY (recorded_by_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS students (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    class_name VARCHAR(60),
    parent_name VARCHAR(120),
    parent_phone VARCHAR(20),
    classroom_id BIGINT,
    school_id BIGINT NULL,
    registration_status VARCHAR(20) NOT NULL DEFAULT 'VALIDATED',
    validated_by_id BIGINT NULL,
    validated_at TIMESTAMP NULL,
    CONSTRAINT fk_student_classroom FOREIGN KEY (classroom_id) REFERENCES classrooms(id)
);

CREATE TABLE IF NOT EXISTS exam_class_configs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    school_id BIGINT NOT NULL,
    classroom_id BIGINT NOT NULL,
    exam_name VARCHAR(120) NOT NULL,
    official_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT uk_exam_config_school_class UNIQUE (school_id, classroom_id),
    CONSTRAINT fk_exam_config_school FOREIGN KEY (school_id) REFERENCES schools(id),
    CONSTRAINT fk_exam_config_classroom FOREIGN KEY (classroom_id) REFERENCES classrooms(id)
);

CREATE TABLE IF NOT EXISTS exam_document_requirements (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    config_id BIGINT NOT NULL,
    name VARCHAR(120) NOT NULL,
    required BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uk_exam_document_config_name UNIQUE (config_id, name),
    CONSTRAINT fk_exam_document_config FOREIGN KEY (config_id) REFERENCES exam_class_configs(id)
);

CREATE TABLE IF NOT EXISTS student_exam_records (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    config_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL,
    paid_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT uk_exam_record_config_student UNIQUE (config_id, student_id),
    CONSTRAINT fk_exam_record_config FOREIGN KEY (config_id) REFERENCES exam_class_configs(id),
    CONSTRAINT fk_exam_record_student FOREIGN KEY (student_id) REFERENCES students(id)
);

CREATE TABLE IF NOT EXISTS student_exam_documents (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    record_id BIGINT NOT NULL,
    requirement_id BIGINT NOT NULL,
    submitted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uk_student_exam_document UNIQUE (record_id, requirement_id),
    CONSTRAINT fk_student_exam_document_record FOREIGN KEY (record_id) REFERENCES student_exam_records(id),
    CONSTRAINT fk_student_exam_document_requirement FOREIGN KEY (requirement_id) REFERENCES exam_document_requirements(id)
);
