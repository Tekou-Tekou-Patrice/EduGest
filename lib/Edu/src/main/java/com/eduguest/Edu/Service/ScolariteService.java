package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.ClassroomDto;
import com.eduguest.Edu.DTO.StudentDto;
import com.eduguest.Edu.DTO.TeacherDto;
import com.eduguest.Edu.Entity.Classroom;
import com.eduguest.Edu.Entity.Student;
import com.eduguest.Edu.Entity.School;
import com.eduguest.Edu.Entity.Teacher;
import com.eduguest.Edu.Entity.User;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Repository.ClassroomRepository;
import com.eduguest.Edu.Repository.StudentRepository;
import com.eduguest.Edu.Repository.SchoolMembershipRepository;
import com.eduguest.Edu.Repository.TeacherRepository;
import com.eduguest.Edu.Repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class ScolariteService {

    private final TeacherRepository teacherRepository;
    private final ClassroomRepository classroomRepository;
    private final StudentRepository studentRepository;
    private final UserRepository userRepository;
    private final SchoolMembershipRepository membershipRepository;
    private final PasswordEncoder passwordEncoder;
    private final SchoolService schoolService;
    private final SchoolContextService schoolContextService;


    public ScolariteService(TeacherRepository teacherRepository,
                            ClassroomRepository classroomRepository,
                            StudentRepository studentRepository,
                            UserRepository userRepository,
                            SchoolMembershipRepository membershipRepository,
                            PasswordEncoder passwordEncoder,
                            SchoolContextService schoolContextService,
                            SchoolService schoolService) {
        this.schoolContextService = schoolContextService;
        this.teacherRepository = teacherRepository;
        this.classroomRepository = classroomRepository;
        this.studentRepository = studentRepository;
        this.userRepository = userRepository;
        this.membershipRepository = membershipRepository;
        this.passwordEncoder = passwordEncoder;
        this.schoolService = schoolService;
    }

    // --- ENSEIGNANTS ---
    @Transactional(readOnly = true)
    public List<TeacherDto> getTeachers(String query) {
        if (query != null && !query.isEmpty()) {
            return schoolContextService.scope(teacherRepository.searchTeachers(query)).stream().map(this::toTeacherDto).collect(Collectors.toList());
        }
        return schoolContextService.scope(teacherRepository.findAllSortedBySpeciality()).stream().map(this::toTeacherDto).collect(Collectors.toList());
    }

    @Transactional
    public TeacherDto createTeacher(TeacherDto dto) {
        if (dto.getPhone() == null || dto.getPhone().isBlank()) {
            throw new IllegalArgumentException(
                    "Le numéro de téléphone est obligatoire pour un enseignant.");
        }
        Teacher teacher;
        boolean isNew = false;
        if (dto.getId() != null) {
            teacher = teacherRepository.findById(dto.getId())
                    .orElse(new Teacher());
        } else {
            teacher = new Teacher();
            isNew = true;
        }
        teacher.setFirstName(dto.getFirstName());
        teacher.setLastName(dto.getLastName());
        teacher.setSpeciality(dto.getSpeciality());
        teacher.setEmail(dto.getEmail());
        teacher.setPhone(dto.getPhone());
        
        schoolContextService.verifyAndAssign(teacher);
        Teacher savedTeacher = teacherRepository.save(teacher);

        if (isNew && dto.getEmail() != null && !dto.getEmail().isEmpty()) {
            User staffUser = userRepository.findByEmailIgnoreCase(dto.getEmail()).orElse(null);
            if (staffUser == null) {
                User user = new User();
                user.setUsername(dto.getEmail());
                user.setEmail(dto.getEmail());
                user.setFullName(dto.getFirstName() + " " + dto.getLastName());
                user.setPhone(dto.getPhone());
                user.setRole(UserRole.ENSEIGNANT);
                // The teacher must activate the account through password reset
                // before being allowed to log in and select a school.
                user.setActive(false);
                String rawPassword = (dto.getPassword() != null && !dto.getPassword().isEmpty()) 
                                     ? dto.getPassword() 
                                     : "Edugest2024";
                user.setPassword(passwordEncoder.encode(rawPassword));
                staffUser = userRepository.save(user);
            }
            staffUser.setRole(UserRole.ENSEIGNANT);
            userRepository.save(staffUser);
            schoolService.addMembership(
                    staffUser,
                    schoolContextService.currentSchool(),
                    UserRole.ENSEIGNANT
            );
        }
        
        return toTeacherDto(savedTeacher);
    }

    @Transactional
    public void deleteTeacher(Long id) {
        teacherRepository.findById(id).ifPresent(teacher -> {
            schoolContextService.verifyAndAssign(teacher);
            School currentSchool = schoolContextService.currentSchool();
            if (currentSchool != null && teacher.getEmail() != null) {
                userRepository.findByEmailIgnoreCase(teacher.getEmail())
                        .flatMap(user -> membershipRepository.findByUserIdAndSchoolId(
                                user.getId(), currentSchool.getId()))
                        .ifPresent(membership -> {
                            membership.setActive(false);
                            membershipRepository.save(membership);
                        });
            }
            for (Classroom classroom : schoolContextService.scope(classroomRepository.findAll())) {
                boolean changed = classroom.getTeachers().removeIf(item -> item.getId().equals(id));
                if (classroom.getTeacher() != null && classroom.getTeacher().getId().equals(id)) {
                    classroom.setTeacher(classroom.getTeachers().stream().findFirst().orElse(null));
                    changed = true;
                }
                if (changed) {
                    classroomRepository.save(classroom);
                }
            }
            teacherRepository.delete(teacher);
        });
    }

    // --- ÉLÈVES ---
    @Transactional(readOnly = true)
    public List<StudentDto> getStudents(String className, String query) {
        if (query != null && !query.isEmpty()) {
            return schoolContextService.scope(studentRepository.searchStudents(query)).stream().map(this::toStudentDto).collect(Collectors.toList());
        }
        if (className != null && !className.equals("Toutes") && !className.isBlank()) {
            Map<Long, Student> students = new LinkedHashMap<>();
            schoolContextService.scope(studentRepository.findByClassName(className))
                    .forEach(student -> students.put(student.getId(), student));
            schoolContextService.scope(studentRepository.findByClassroomName(className))
                    .forEach(student -> students.put(student.getId(), student));
            return students.values().stream().map(this::toStudentDto).collect(Collectors.toList());
        }
        return schoolContextService.scope(studentRepository.findAllSortedByName()).stream().map(this::toStudentDto).collect(Collectors.toList());
    }

    @Transactional
    public StudentDto createStudent(StudentDto dto) {
        School currentSchool = schoolContextService.currentSchool();
        Student student;
        if (dto.getId() != null) {
            student = studentRepository.findById(dto.getId()).orElse(new Student());
        } else {
            student = new Student();
            student.setRegistrationDate(LocalDateTime.now());
            student.setRegistrationStatus(
                    currentSchool != null && "PRIMARY".equalsIgnoreCase(currentSchool.getSchoolLevel())
                            ? "PENDING"
                            : "VALIDATED"
            );
            if (dto.getRegisteredById() != null) {
                userRepository.findById(dto.getRegisteredById()).ifPresent(student::setRegisteredBy);
            }
        }
        student.setFirstName(dto.getFirstName());
        student.setLastName(dto.getLastName());
        student.setClassName(dto.getClassName());
        student.setBirthDate(dto.getBirthDate());
        student.setParentName(dto.getParentName());
        student.setParentPhone(dto.getParentPhone());
        student.setParentEmail(dto.getParentEmail());
        student.setPhotoUrl(dto.getPhotoUrl());

        boolean pendingPrimary = "PENDING".equalsIgnoreCase(student.getRegistrationStatus());
        if (!pendingPrimary && dto.getClassroomId() != null) {
            classroomRepository.findById(dto.getClassroomId()).ifPresent(student::setClassroom);
        } else if (!pendingPrimary && dto.getClassName() != null && !dto.getClassName().isBlank()) {
            classroomRepository.findByName(dto.getClassName()).ifPresent(student::setClassroom);
        }

        schoolContextService.verifyAndAssign(student);
        Student savedStudent = studentRepository.save(student);
        createOrUpdateParentAccount(savedStudent, dto.getParentPassword());
        return toStudentDto(savedStudent);
    }

    @Transactional
    public StudentDto validateStudent(Long studentId, Long classroomId, Long validatorId) {
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("Élève non trouvé"));
        schoolContextService.verifyAndAssign(student);
        Classroom classroom = classroomRepository.findById(classroomId)
                .orElseThrow(() -> new RuntimeException("Classe non trouvée"));
        schoolContextService.verifyAndAssign(classroom);
        User validator = userRepository.findById(validatorId)
                .orElseThrow(() -> new RuntimeException("Directeur non trouvé"));

        student.setClassroom(classroom);
        student.setClassName(classroom.getName());
        student.setRegistrationStatus("VALIDATED");
        student.setValidatedBy(validator);
        student.setValidatedAt(LocalDateTime.now());
        return toStudentDto(studentRepository.save(student));
    }

    @Transactional
    public void deleteStudent(Long id) {
        if (!studentRepository.existsById(id)) {
            throw new RuntimeException("Élève non trouvé");
        }
        studentRepository.findById(id).ifPresent(student -> {
            schoolContextService.verifyAndAssign(student);
            Optional<User> parentAccount = findParentAccount(student);
            School currentSchool = schoolContextService.currentSchool();
            String parentPhone = normalized(student.getParentPhone());
            String parentEmail = normalized(student.getParentEmail());
            studentRepository.delete(student);

            // Le compte parent est conservé. Son accès n'est retiré que si ce
            // dernier élève est le seul encore inscrit dans l'établissement.
            if (currentSchool != null && parentAccount.isPresent()
                    && !hasOtherStudentForParent(id, parentPhone, parentEmail)) {
                membershipRepository.findByUserIdAndSchoolId(
                                parentAccount.get().getId(), currentSchool.getId())
                        .filter(membership -> membership.getRole() == UserRole.PARENT)
                        .ifPresent(membership -> {
                            membership.setActive(false);
                            membershipRepository.save(membership);
                        });
            }
        });
    }

    // --- CLASSES ---
    private Optional<User> findParentAccount(Student student) {
        String phone = normalized(student.getParentPhone());
        if (!phone.isBlank()) {
            return userRepository.findFirstByPhone(phone)
                    .or(() -> userRepository.findByUsername(phone));
        }
        String email = normalized(student.getParentEmail());
        return email.isBlank() ? Optional.empty() : userRepository.findByEmailIgnoreCase(email);
    }

    private boolean hasOtherStudentForParent(Long deletedStudentId, String phone, String email) {
        if (phone.isBlank() && email.isBlank()) return false;
        return schoolContextService.scope(studentRepository.findByParentContact(phone, email)).stream()
                .anyMatch(student -> !student.getId().equals(deletedStudentId));
    }

    private String normalized(String value) {
        return value == null ? "" : value.trim();
    }

    @Transactional(readOnly = true)
    public List<ClassroomDto> getClassrooms() {
        return schoolContextService.scope(classroomRepository.findAll()).stream().map(this::toClassroomDto).collect(Collectors.toList());
    }

    @Transactional
    public ClassroomDto createClassroom(ClassroomDto dto) {
        Classroom c;
        if (dto.getId() != null) {
            c = classroomRepository.findById(dto.getId()).orElse(new Classroom());
        } else {
            c = new Classroom();
        }
        c.setName(dto.getName());
        c.setLevel(dto.getLevel());
        c.setExamClass(Boolean.TRUE.equals(dto.getExamClass()));
        c.setCapacity(dto.getCapacity() != null ? dto.getCapacity() : 40);
        c.setDescription(dto.getDescription());
        c.setTuitionFee(dto.getTuitionFee() != null ? dto.getTuitionFee() : 0d);
        Set<Teacher> assignedTeachers = new LinkedHashSet<>();
        if (dto.getTeacherIds() != null && !dto.getTeacherIds().isEmpty()) {
            for (Long id : dto.getTeacherIds()) {
                teacherRepository.findById(id).ifPresent(teacher -> {
                    schoolContextService.verifyAndAssign(teacher);
                    assignedTeachers.add(teacher);
                });
            }
        } else if (dto.getTeacherId() != null) {
            teacherRepository.findById(dto.getTeacherId()).ifPresent(teacher -> {
                schoolContextService.verifyAndAssign(teacher);
                assignedTeachers.add(teacher);
            });
        }
        if (!c.isExamClass() && assignedTeachers.size() > 1) {
            Teacher firstTeacher = assignedTeachers.iterator().next();
            assignedTeachers.clear();
            assignedTeachers.add(firstTeacher);
        }
        c.setTeachers(assignedTeachers);
        c.setTeacher(assignedTeachers.stream().findFirst().orElse(null));
        schoolContextService.verifyAndAssign(c);
        return toClassroomDto(classroomRepository.save(c));
    }

    @Transactional
    public ClassroomDto savePromotionSettings(Long classroomId, ClassroomDto dto) {
        Classroom classroom = classroomRepository.findById(classroomId)
                .orElseThrow(() -> new IllegalArgumentException("Classe non trouvée"));
        schoolContextService.verifyAndAssign(classroom);

        Double threshold = dto.getPromotionThreshold();
        if (threshold == null || !Double.isFinite(threshold) || threshold < 0 || threshold > 20) {
            throw new IllegalArgumentException("La moyenne de passage doit être comprise entre 0 et 20.");
        }

        Long targetId = dto.getPromotionTargetClassId();
        if (targetId != null) {
            Classroom target = classroomRepository.findById(targetId)
                    .orElseThrow(() -> new IllegalArgumentException("Classe suivante non trouvée"));
            schoolContextService.verifyAndAssign(target);
            if (classroom.getId().equals(target.getId())) {
                throw new IllegalArgumentException("Une classe ne peut pas être sa propre classe suivante.");
            }
        }

        classroom.setPromotionThreshold(threshold);
        if (targetId != null) {
            classroom.setPromotionTargetClassId(targetId);
        }
        return toClassroomDto(classroomRepository.save(classroom));
    }

    @Transactional
    public void deleteClassroom(Long id) {
        if (!classroomRepository.existsById(id)) {
            throw new RuntimeException("Classe non trouvée");
        }
        classroomRepository.findById(id).ifPresent(classroom -> {
            schoolContextService.verifyAndAssign(classroom);
            schoolContextService.scope(classroomRepository.findAll()).stream()
                    .filter(item -> id.equals(item.getPromotionTargetClassId()))
                    .forEach(item -> {
                        item.setPromotionTargetClassId(null);
                        classroomRepository.save(item);
                    });
            classroomRepository.delete(classroom);
        });
    }

    private TeacherDto toTeacherDto(Teacher t) {
        TeacherDto dto = new TeacherDto();
        dto.setId(t.getId());
        dto.setFirstName(t.getFirstName());
        dto.setLastName(t.getLastName());
        dto.setSpeciality(t.getSpeciality());
        dto.setEmail(t.getEmail());
        dto.setPhone(t.getPhone());
        return dto;
    }

    private StudentDto toStudentDto(Student s) {
        StudentDto dto = new StudentDto();
        dto.setId(s.getId());
        dto.setFirstName(s.getFirstName());
        dto.setLastName(s.getLastName());
        dto.setClassName(s.getClassName());
        dto.setBirthDate(s.getBirthDate());
        dto.setParentName(s.getParentName());
        dto.setParentPhone(s.getParentPhone());
        dto.setParentEmail(s.getParentEmail());
        dto.setPhotoUrl(s.getPhotoUrl());
        if (s.getClassroom() != null) {
            dto.setClassroomId(s.getClassroom().getId());
        }
        if (s.getRegisteredBy() != null) {
            dto.setRegisteredById(s.getRegisteredBy().getId());
            dto.setRegisteredByName(s.getRegisteredBy().getFullName());
        }
        dto.setRegistrationDate(s.getRegistrationDate());
        dto.setRegistrationStatus(s.getRegistrationStatus());
        dto.setValidatedAt(s.getValidatedAt());
        if (s.getValidatedBy() != null) {
            dto.setValidatedById(s.getValidatedBy().getId());
            dto.setValidatedByName(s.getValidatedBy().getFullName());
        }
        return dto;
    }

    private ClassroomDto toClassroomDto(Classroom c) {
        ClassroomDto dto = new ClassroomDto();
        dto.setId(c.getId());
        dto.setName(c.getName());
        dto.setLevel(c.getLevel());
        dto.setExamClass(c.isExamClass());
        dto.setPromotionThreshold(c.getPromotionThreshold() != null ? c.getPromotionThreshold() : 10.0);
        dto.setPromotionTargetClassId(c.getPromotionTargetClassId());
        dto.setCapacity(c.getCapacity());
        dto.setDescription(c.getDescription());
        dto.setTuitionFee(c.getTuitionFee() != null ? c.getTuitionFee() : 0d);
        if (c.getTeacher() != null) {
            dto.setTeacherId(c.getTeacher().getId());
            dto.setTeacherName(c.getTeacher().getFirstName() + " " + c.getTeacher().getLastName());
        }
        c.getTeachers().forEach(teacher -> {
            dto.getTeacherIds().add(teacher.getId());
            dto.getTeacherNames().add(teacher.getFirstName() + " " + teacher.getLastName());
        });
        String className = c.getName() != null ? c.getName() : "";
        Map<Long, Student> students = new LinkedHashMap<>();
        schoolContextService.scope(studentRepository.findByClassName(className))
                .forEach(student -> students.put(student.getId(), student));
        schoolContextService.scope(studentRepository.findByClassroomName(className))
                .forEach(student -> students.put(student.getId(), student));
        dto.setStudentCount(students.size());
        return dto;
    }

    private void createOrUpdateParentAccount(Student student, String rawPassword) {
        String phone = student.getParentPhone() == null ? "" : student.getParentPhone().trim();
        String email = student.getParentEmail() == null ? "" : student.getParentEmail().trim();
        if (phone.isBlank() && email.isBlank()) return;

        String username = !phone.isBlank() ? phone : email;
        User user = userRepository.findByUsername(username)
                .or(() -> email.isBlank() ? java.util.Optional.empty() : userRepository.findByEmail(email))
                .orElseGet(User::new);
        if (user.getId() == null) {
            user.setUsername(username);
            user.setEmail(!email.isBlank() ? email : "parent." + phone.replaceAll("[^0-9]", "") + "@edugest.local");
            user.setRole(UserRole.PARENT);
            user.setActive(true);
        }
        user.setFullName(student.getParentName() == null || student.getParentName().isBlank()
                ? "Parent de " + student.getFirstName() + " " + student.getLastName()
                : student.getParentName());
        user.setPhone(phone);
        // Le téléphone est un identifiant déjà communiqué au parent et sert de
        // mot de passe temporaire si aucun mot de passe personnalisé n'est saisi.
        String temporaryPassword = rawPassword == null || rawPassword.isBlank()
                ? (!phone.isBlank() ? phone : "Edugest2024")
                : rawPassword;
        user.setPassword(passwordEncoder.encode(temporaryPassword));
        User saved = userRepository.save(user);
        schoolService.addMembership(saved, schoolContextService.currentSchool(), UserRole.PARENT);
    }

    @Transactional(readOnly = true)
    public List<StudentDto> getStudentsForParent(Long parentUserId) {
        User parent = userRepository.findById(parentUserId)
                .orElseThrow(() -> new RuntimeException("Compte Parent introuvable"));
        if (parent.getRole() != UserRole.PARENT) throw new RuntimeException("Accès réservé au parent");
        String phone = parent.getPhone() == null ? "" : parent.getPhone();
        String email = parent.getEmail() == null || parent.getEmail().endsWith("@edugest.local") ? "" : parent.getEmail();
        return schoolContextService.scope(studentRepository.findByParentContact(phone, email)).stream()
                .filter(student -> !"PENDING".equalsIgnoreCase(student.getRegistrationStatus()))
                .map(this::toStudentDto).collect(Collectors.toList());
    }
}
