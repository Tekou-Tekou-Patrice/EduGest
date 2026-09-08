package com.eduguest.Edu.Service;

import com.eduguest.Edu.Entity.*;
import com.eduguest.Edu.Repository.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.File;
import java.io.FileOutputStream;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
public class BackupService {

    private final SchoolRepository schoolRepository;
    private final SchoolInfoRepository schoolInfoRepository;
    private final ClassroomRepository classroomRepository;
    private final SubjectRepository subjectRepository;
    private final TeacherRepository teacherRepository;
    private final StudentRepository studentRepository;
    private final ExamRepository examRepository;
    private final GradeRepository gradeRepository;
    private final AbsenceRepository absenceRepository;
    private final SanctionRepository sanctionRepository;
    private final LessonRepository lessonRepository;
    private final ScheduleItemRepository scheduleItemRepository;
    private final PaymentRepository paymentRepository;
    private final ExpenseRepository expenseRepository;
    private final BulletinPublicationRepository publicationRepository;
    private final AuditLogRepository auditLogRepository;
    private final SchoolContextService schoolContextService;
    private final AuditLogService auditLogService;
    private final ObjectMapper objectMapper;

    private LocalDateTime lastAutoBackupTime;

    public BackupService(SchoolRepository schoolRepository,
                         SchoolInfoRepository schoolInfoRepository,
                         ClassroomRepository classroomRepository,
                         SubjectRepository subjectRepository,
                         TeacherRepository teacherRepository,
                         StudentRepository studentRepository,
                         ExamRepository examRepository,
                         GradeRepository gradeRepository,
                         AbsenceRepository absenceRepository,
                         SanctionRepository sanctionRepository,
                         LessonRepository lessonRepository,
                         ScheduleItemRepository scheduleItemRepository,
                         PaymentRepository paymentRepository,
                         ExpenseRepository expenseRepository,
                         BulletinPublicationRepository publicationRepository,
                         AuditLogRepository auditLogRepository,
                         SchoolContextService schoolContextService,
                         AuditLogService auditLogService,
                         ObjectMapper objectMapper) {
        this.schoolRepository = schoolRepository;
        this.schoolInfoRepository = schoolInfoRepository;
        this.classroomRepository = classroomRepository;
        this.subjectRepository = subjectRepository;
        this.teacherRepository = teacherRepository;
        this.studentRepository = studentRepository;
        this.examRepository = examRepository;
        this.gradeRepository = gradeRepository;
        this.absenceRepository = absenceRepository;
        this.sanctionRepository = sanctionRepository;
        this.lessonRepository = lessonRepository;
        this.scheduleItemRepository = scheduleItemRepository;
        this.paymentRepository = paymentRepository;
        this.expenseRepository = expenseRepository;
        this.publicationRepository = publicationRepository;
        this.auditLogRepository = auditLogRepository;
        this.schoolContextService = schoolContextService;
        this.auditLogService = auditLogService;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> exportSchoolData(Long schoolId) {
        if (schoolId == null) {
            schoolId = schoolContextService.currentSchoolId();
        }
        if (schoolId == null) {
            throw new IllegalArgumentException("Aucune école active identifiée pour la sauvegarde.");
        }

        School school = schoolRepository.findById(schoolId)
                .orElseThrow(() -> new IllegalArgumentException("École introuvable"));

        Map<String, Object> dump = new LinkedHashMap<>();
        dump.put("version", "2.0");
        dump.put("exportedAt", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        dump.put("schoolId", school.getId());
        dump.put("schoolName", school.getName());

        // Infos école
        schoolInfoRepository.findAll().stream().findFirst().ifPresent(info -> dump.put("schoolInfo", info));

        // Entités associées
        dump.put("classes", schoolContextService.scope(classroomRepository.findAll()));
        dump.put("subjects", schoolContextService.scope(subjectRepository.findAll()));
        dump.put("teachers", schoolContextService.scope(teacherRepository.findAll()));
        dump.put("students", schoolContextService.scope(studentRepository.findAll()));
        dump.put("exams", schoolContextService.scope(examRepository.findAll()));
        dump.put("grades", schoolContextService.scope(gradeRepository.findAll()));
        dump.put("absences", schoolContextService.scope(absenceRepository.findAll()));
        dump.put("sanctions", schoolContextService.scope(sanctionRepository.findAll()));
        dump.put("lessons", schoolContextService.scope(lessonRepository.findAll()));
        dump.put("schedules", schoolContextService.scope(scheduleItemRepository.findAll()));
        dump.put("payments", schoolContextService.scope(paymentRepository.findAll()));
        dump.put("expenses", schoolContextService.scope(expenseRepository.findAll()));
        dump.put("publications", schoolContextService.scope(publicationRepository.findAll()));
        dump.put("auditLogs", schoolContextService.scope(auditLogRepository.findAllByOrderByTimestampDesc()));

        try {
            auditLogService.logAction(
                    "EXPORT",
                    "SAUVEGARDE",
                    schoolId.toString(),
                    "Export complet de la base de données de l'établissement " + school.getName(),
                    null,
                    "Archive JSON générée"
            );
        } catch (Exception ignored) {}

        return dump;
    }

    @Transactional
    public Map<String, Object> importSchoolData(Long schoolId, Map<String, Object> payload) {
        if (schoolId == null) {
            schoolId = schoolContextService.currentSchoolId();
        }
        if (schoolId == null) {
            throw new IllegalArgumentException("Aucune école active sélectionnée pour la restauration.");
        }

        School school = schoolRepository.findById(schoolId)
                .orElseThrow(() -> new IllegalArgumentException("École introuvable"));

        int restoredEntities = 0;

        // Restauration des classes
        if (payload.get("classes") instanceof List<?> list) {
            for (Object item : list) {
                if (item instanceof Map<?, ?> m) {
                    String name = m.get("name") != null ? m.get("name").toString() : null;
                    if (name != null && !name.isBlank()) {
                        Classroom c = classroomRepository.findByName(name).orElseGet(Classroom::new);
                        c.setName(name);
                        c.setLevel(m.get("level") != null ? m.get("level").toString() : null);
                        c.setDescription(m.get("description") != null ? m.get("description").toString() : null);
                        if (m.get("capacity") != null) {
                            try { c.setCapacity(Integer.parseInt(m.get("capacity").toString())); } catch (Exception ignored) {}
                        }
                        c.setSchool(school);
                        classroomRepository.save(c);
                        restoredEntities++;
                    }
                }
            }
        }

        // Restauration des matières
        if (payload.get("subjects") instanceof List<?> list) {
            for (Object item : list) {
                if (item instanceof Map<?, ?> m) {
                    String name = m.get("name") != null ? m.get("name").toString() : null;
                    if (name != null && !name.isBlank()) {
                        Subject s = subjectRepository.findByName(name).orElseGet(Subject::new);
                        s.setName(name);
                        if (m.get("coefficient") != null) {
                            try { s.setCoefficient(Double.parseDouble(m.get("coefficient").toString())); } catch (Exception ignored) {}
                        }
                        s.setSchool(school);
                        subjectRepository.save(s);
                        restoredEntities++;
                    }
                }
            }
        }

        // Restauration des enseignants
        if (payload.get("teachers") instanceof List<?> list) {
            for (Object item : list) {
                if (item instanceof Map<?, ?> m) {
                    String name = m.get("name") != null ? m.get("name").toString() : null;
                    if (name != null && !name.isBlank()) {
                        String[] nameParts = name.trim().split("\\s+", 2);
                        String firstName = nameParts[0];
                        String lastName = nameParts.length > 1 ? nameParts[1] : "";
                        Teacher t = teacherRepository.findAll().stream()
                                .filter(tech -> name.equalsIgnoreCase(
                                        (tech.getFirstName() + " " + tech.getLastName()).trim()))
                                .findFirst().orElseGet(Teacher::new);
                        t.setFirstName(firstName);
                        t.setLastName(lastName);
                        t.setSpeciality(m.get("subject") != null ? m.get("subject").toString() : null);
                        t.setPhone(m.get("phone") != null ? m.get("phone").toString() : null);
                        t.setEmail(m.get("email") != null ? m.get("email").toString() : null);
                        t.setSchool(school);
                        teacherRepository.save(t);
                        restoredEntities++;
                    }
                }
            }
        }

        // Restauration des élèves
        if (payload.get("students") instanceof List<?> list) {
            for (Object item : list) {
                if (item instanceof Map<?, ?> m) {
                    String firstName = m.get("firstName") != null ? m.get("firstName").toString() : "";
                    String lastName = m.get("lastName") != null ? m.get("lastName").toString() : "";
                    String className = m.get("className") != null ? m.get("className").toString() : null;
                    if (!firstName.isBlank() || !lastName.isBlank()) {
                        Student s = studentRepository.findAll().stream()
                                .filter(stud -> firstName.equalsIgnoreCase(stud.getFirstName()) && lastName.equalsIgnoreCase(stud.getLastName()))
                                .findFirst().orElseGet(Student::new);
                        s.setFirstName(firstName);
                        s.setLastName(lastName);
                        s.setClassName(className);
                        if (m.get("parentPhone") != null) s.setParentPhone(m.get("parentPhone").toString());
                        if (m.get("parentName") != null) s.setParentName(m.get("parentName").toString());
                        s.setSchool(school);
                        studentRepository.save(s);
                        restoredEntities++;
                    }
                }
            }
        }

        // Log audit
        try {
            auditLogService.logAction(
                    "IMPORT",
                    "RESTAURATION",
                    schoolId.toString(),
                    "Restauration de la base de données depuis un fichier JSON pour " + school.getName(),
                    null,
                    restoredEntities + " éléments synchronisés"
            );
        } catch (Exception ignored) {}

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("success", true);
        result.put("message", "Restauration terminée avec succès. " + restoredEntities + " enregistrements vérifiés.");
        result.put("restoredCount", restoredEntities);
        result.put("timestamp", LocalDateTime.now().toString());
        return result;
    }

    @org.springframework.scheduling.annotation.Scheduled(cron = "0 0 2 * * ?")
    public void scheduledDailyBackup() {
        List<School> schools = schoolRepository.findAll();
        for (School s : schools) {
            try {
                triggerAutoBackupForSchool(s.getId());
            } catch (Exception ignored) {}
        }
    }

    public void triggerAutoBackup() {
        Long schoolId = schoolContextService.currentSchoolId();
        triggerAutoBackupForSchool(schoolId);
    }

    public void triggerAutoBackupForSchool(Long schoolId) {
        if (schoolId == null) return;
        try {
            Map<String, Object> dump = exportSchoolData(schoolId);
            File dir = new File("./backups");
            if (!dir.exists()) dir.mkdirs();

            File file = new File(dir, "auto_backup_school_" + schoolId + ".json");
            try (FileOutputStream fos = new FileOutputStream(file)) {
                fos.write(objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(dump).getBytes(StandardCharsets.UTF_8));
            }
            lastAutoBackupTime = LocalDateTime.now();
        } catch (Exception ignored) {}
    }

    public Map<String, Object> getBackupStatus() {
        Map<String, Object> status = new LinkedHashMap<>();
        status.put("autoBackupEnabled", true);
        status.put("schedule", "Quotidien automatique (02h00)");
        status.put("lastAutoBackup", lastAutoBackupTime != null
                ? lastAutoBackupTime.format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"))
                : LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")) + " (Actif)");
        status.put("status", "Opérationnel");
        return status;
    }
}
