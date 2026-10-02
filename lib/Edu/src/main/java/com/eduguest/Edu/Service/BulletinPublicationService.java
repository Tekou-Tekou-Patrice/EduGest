package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.BulletinPublicationDto;
import com.eduguest.Edu.Entity.BulletinPublication;
import com.eduguest.Edu.Entity.Classroom;
import com.eduguest.Edu.Entity.Exam;
import com.eduguest.Edu.Entity.Grade;
import com.eduguest.Edu.Entity.Student;
import com.eduguest.Edu.Entity.Subject;
import com.eduguest.Edu.Repository.BulletinPublicationRepository;
import com.eduguest.Edu.Repository.ClassroomRepository;
import com.eduguest.Edu.Repository.ExamRepository;
import com.eduguest.Edu.Repository.GradeRepository;
import com.eduguest.Edu.Repository.StudentRepository;
import com.eduguest.Edu.Repository.SubjectRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class BulletinPublicationService {

    private final BulletinPublicationRepository repository;
    private final StudentRepository studentRepository;
    private final ExamRepository examRepository;
    private final GradeRepository gradeRepository;
    private final AppNotificationService notificationService;
    private final AcademicYearService academicYearService;
    private final SchoolContextService schoolContextService;
    private final AuditLogService auditLogService;
    private final SubjectRepository subjectRepository;
    private final ClassroomRepository classroomRepository;

    public BulletinPublicationService(BulletinPublicationRepository repository,
                                    StudentRepository studentRepository,
                                    ExamRepository examRepository,
                                    GradeRepository gradeRepository,
                                    AppNotificationService notificationService,
                                    AcademicYearService academicYearService,
                                    SchoolContextService schoolContextService,
                                    AuditLogService auditLogService,
                                    SubjectRepository subjectRepository,
                                    ClassroomRepository classroomRepository) {
        this.repository = repository;
        this.studentRepository = studentRepository;
        this.examRepository = examRepository;
        this.gradeRepository = gradeRepository;
        this.notificationService = notificationService;
        this.academicYearService = academicYearService;
        this.schoolContextService = schoolContextService;
        this.auditLogService = auditLogService;
        this.subjectRepository = subjectRepository;
        this.classroomRepository = classroomRepository;
    }

    @Transactional
    public BulletinPublicationDto publish(String className, String period, String studentId,
                                         String publishedBy, String publishedByRole,
                                         String languageCode) {
        academicYearService.autoCloseIfDue();
        Map<String, Object> readiness = getReadiness(className, period, studentId);
        if (!Boolean.TRUE.equals(readiness.get("ready"))) {
            String reason = readiness.get("message") != null
                    ? readiness.get("message").toString()
                    : "Publication impossible : validation non satisfaite (notes manquantes ou coefficients nuls).";
            throw new IllegalStateException(reason);
        }

        Long yearId;
        try {
            yearId = academicYearService.stampCurrentYear();
        } catch (RuntimeException e) {
            yearId = academicYearService.getOrAutoCreateActiveYear().getId();
        }

        List<BulletinPublication> currentYearPublications = academicYearService.filterCurrentYear(
                schoolContextService.scope(repository.findAll()),
                BulletinPublication::getAcademicYearId);
        BulletinPublication pub;
        if (studentId != null && !studentId.isBlank()) {
            pub = currentYearPublications.stream()
                    .filter(p -> className.equalsIgnoreCase(p.getClassName())
                            && period.equalsIgnoreCase(p.getPeriod())
                            && studentId.equals(p.getStudentId()))
                    .findFirst()
                    .orElseGet(BulletinPublication::new);
            pub.setStudentId(studentId);
        } else {
            pub = currentYearPublications.stream()
                    .filter(p -> className.equalsIgnoreCase(p.getClassName())
                            && period.equalsIgnoreCase(p.getPeriod())
                            && (p.getStudentId() == null || p.getStudentId().isBlank()))
                    .findFirst()
                    .orElseGet(BulletinPublication::new);
            pub.setStudentId(null);
        }

        pub.setClassName(className);
        pub.setPeriod(period);
        pub.setPublishedBy(publishedBy != null && !publishedBy.isBlank() ? publishedBy : "Direction");
        pub.setPublishedByRole(publishedByRole != null && !publishedByRole.isBlank() ? publishedByRole : "Direction");
        pub.setLanguageCode("en".equalsIgnoreCase(languageCode) ? "en" : "fr");
        pub.setPublishedAt(LocalDateTime.now());
        pub.setPublished(true);
        pub.setAcademicYearId(yearId);

        if ((studentId == null || studentId.isBlank())
                && "Bilan Annuel".equalsIgnoreCase(period.trim())) {
            Classroom sourceClass = findClassroom(className);
            double threshold = sourceClass.getPromotionThreshold() != null
                    ? sourceClass.getPromotionThreshold()
                    : 10.0;
            pub.setPromotionThreshold(threshold);
            pub.setPromotionSourceClassId(sourceClass.getId());
            if (sourceClass.getPromotionTargetClassId() != null) {
                Classroom targetClass = findClassroom(sourceClass.getPromotionTargetClassId());
                pub.setPromotionTargetClassName(targetClass.getName());
            }
        }

        schoolContextService.verifyAndAssign(pub);
        BulletinPublication saved = repository.save(pub);

        // Audit Log
        try {
            auditLogService.logAction(
                    "PUBLISH",
                    "BULLETIN",
                    className + " - " + period + (studentId != null ? " - Élève " + studentId : ""),
                    "Publication des bulletins pour la classe " + className + " (" + period + ")",
                    "Non publié",
                    "Publié par " + pub.getPublishedBy() + " (" + pub.getPublishedByRole() + ")",
                    pub.getPublishedBy(),
                    pub.getPublishedByRole()
            );
        } catch (Exception ignored) {}

        // Envoyer les notifications ciblées aux parents
        try {
            if (studentId != null && !studentId.isBlank()) {
                notificationService.notifyBulletinPublished(studentId, period, pub.getPublishedBy());
            } else {
                List<Student> students = schoolContextService.scope(studentRepository.findByClassName(className));
                for (Student s : students) {
                    notificationService.notifyBulletinPublished(String.valueOf(s.getId()), period, pub.getPublishedBy());
                }
            }
        } catch (Exception ignored) {}

        if ((studentId == null || studentId.isBlank())
                && "Bilan Annuel".equalsIgnoreCase(period.trim())) {
            deliberateAndPromote(className, yearId);
        }

        return mapToDto(saved);
    }

    void deliberateAndPromote(String className, Long yearId) {
        Classroom sourceClass = findClassroom(className);

        Classroom targetClass = null;
        if (sourceClass.getPromotionTargetClassId() != null) {
            targetClass = findClassroom(sourceClass.getPromotionTargetClassId());
        }

        List<Exam> exams = academicYearService.filterCurrentYear(
                schoolContextService.scope(examRepository.findByClassName(className)),
                Exam::getAcademicYearId);
        List<Subject> subjects = schoolContextService.scope(subjectRepository.findAll());
        Map<String, Double> subjectCoefficients = subjects.stream()
                .filter(subject -> subject.getName() != null)
                .collect(Collectors.toMap(
                        subject -> subject.getName().trim().toLowerCase(Locale.ROOT),
                        subject -> subject.getCoefficient() == null ? 0.0 : subject.getCoefficient(),
                        (first, ignored) -> first));

        Map<Long, Student> students = new LinkedHashMap<>();
        schoolContextService.scope(studentRepository.findByClassName(className))
                .forEach(student -> students.put(student.getId(), student));
        schoolContextService.scope(studentRepository.findByClassroomName(className))
                .forEach(student -> students.put(student.getId(), student));

        Map<String, Map<String, Grade>> gradesByExam = new HashMap<>();
        for (Exam exam : exams) {
            Map<String, Grade> gradesByStudent = schoolContextService.scope(
                            gradeRepository.findByExamId(String.valueOf(exam.getId())))
                    .stream()
                    .collect(Collectors.toMap(Grade::getStudentId, grade -> grade, (first, ignored) -> first));
            gradesByExam.put(String.valueOf(exam.getId()), gradesByStudent);
        }

        for (Student student : students.values()) {
            if (yearId.equals(student.getLastAnnualDeliberationYearId())) continue;

            double weightedScore = 0;
            double totalCoefficient = 0;
            boolean complete = !exams.isEmpty();
            for (Exam exam : exams) {
                Grade grade = gradesByExam.getOrDefault(String.valueOf(exam.getId()), Map.of())
                        .get(String.valueOf(student.getId()));
                if (grade == null || grade.getScore() == null) {
                    complete = false;
                    break;
                }
                String subjectKey = exam.getSubject() == null
                        ? ""
                        : exam.getSubject().trim().toLowerCase(Locale.ROOT);
                double coefficient = subjectCoefficients.getOrDefault(subjectKey, 0.0);
                if (coefficient <= 0) {
                    coefficient = exam.getCoefficient() != null && exam.getCoefficient() > 0
                            ? exam.getCoefficient()
                            : 0.0;
                }
                if (coefficient <= 0) {
                    complete = false;
                    break;
                }
                weightedScore += grade.getScore() * coefficient;
                totalCoefficient += coefficient;
            }

            if (!complete || totalCoefficient <= 0) continue;
            double average = weightedScore / totalCoefficient;
            double passingThreshold = sourceClass.getPromotionThreshold() != null
                    ? sourceClass.getPromotionThreshold()
                    : 10.0;

            student.setLastAnnualDeliberationYearId(yearId);
            student.setLastAnnualDeliberationClassId(sourceClass.getId());
            if (targetClass != null && average >= passingThreshold) {
                student.setClassroom(targetClass);
                student.setClassName(targetClass.getName());
                student.setAnnualPromotionFromClassId(sourceClass.getId());
                student.setAnnualPromotionToClassId(targetClass.getId());
            }
            studentRepository.save(student);
        }
    }

    private Classroom findClassroom(String className) {
        return schoolContextService.scope(classroomRepository.findAll()).stream()
                .filter(classroom -> classroom.getName() != null
                        && classroom.getName().equalsIgnoreCase(className))
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("Classe de délibération introuvable."));
    }

    private Classroom findClassroom(Long classroomId) {
        return schoolContextService.scope(classroomRepository.findAll()).stream()
                .filter(classroom -> classroomId.equals(classroom.getId()))
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("La classe suivante configurée est introuvable."));
    }

    public Map<String, Object> getReadiness(String className, String studentId) {
        return getReadiness(className, null, studentId);
    }

    /**
     * Vérifie la complétude des notes et des coefficients avant publication :
     * 1. Tous les élèves concernés doivent avoir une note pour chaque évaluation.
     * 2. Aucun coefficient ne doit être nul ou manquant (<= 0).
     * 3. Des évaluations doivent exister pour la classe.
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getReadiness(String className, String period, String studentId) {
        List<com.eduguest.Edu.Entity.Exam> allClassExams = academicYearService.filterCurrentYear(
                schoolContextService.scope(examRepository.findByClassName(className)),
                com.eduguest.Edu.Entity.Exam::getAcademicYearId);

        List<com.eduguest.Edu.Entity.Exam> exams = allClassExams;
        if (period != null && !period.isBlank()) {
            String pNorm = period.trim().toLowerCase();
            List<com.eduguest.Edu.Entity.Exam> filtered = allClassExams.stream()
                    .filter(e -> e.getTitle() != null && e.getTitle().toLowerCase().contains(pNorm))
                    .toList();
            if (!filtered.isEmpty()) {
                exams = filtered;
            }
        }

        List<Student> students = schoolContextService.scope(studentRepository.findByClassName(className));
        if (studentId != null && !studentId.isBlank()) {
            students = students.stream().filter(s -> studentId.equals(String.valueOf(s.getId()))).toList();
        }

        List<Map<String, String>> missing = new ArrayList<>();
        List<String> zeroCoefficients = new ArrayList<>();

        // Vérification des coefficients nuls
        for (com.eduguest.Edu.Entity.Exam exam : exams) {
            if (exam.getCoefficient() == null || exam.getCoefficient() <= 0) {
                zeroCoefficients.add(exam.getSubject() + " (Évaluation: " + exam.getTitle() + ")");
            }
        }

        // Vérification des matières globales de l'école
        List<Subject> schoolSubjects = schoolContextService.scope(subjectRepository.findAll());
        for (Subject subject : schoolSubjects) {
            if (subject.getCoefficient() == null || subject.getCoefficient() <= 0) {
                String subDesc = subject.getName() + " (Coefficient nul ou manquant)";
                if (!zeroCoefficients.contains(subDesc)) {
                    zeroCoefficients.add(subDesc);
                }
            }
        }

        // Vérification des notes manquantes
        for (Student student : students) {
            for (com.eduguest.Edu.Entity.Exam exam : exams) {
                boolean hasGrade = schoolContextService.scope(gradeRepository.findByExamId(String.valueOf(exam.getId())))
                        .stream().anyMatch(grade -> String.valueOf(student.getId()).equals(grade.getStudentId()));
                if (!hasGrade) {
                    Map<String, String> item = new LinkedHashMap<>();
                    item.put("studentId", String.valueOf(student.getId()));
                    item.put("studentName", student.getFirstName() + " " + student.getLastName());
                    item.put("examId", String.valueOf(exam.getId()));
                    item.put("subject", exam.getSubject());
                    item.put("examTitle", exam.getTitle());
                    missing.add(item);
                }
            }
        }

        boolean isReady = !exams.isEmpty() && !students.isEmpty() && missing.isEmpty() && zeroCoefficients.isEmpty();

        String message;
        if (exams.isEmpty()) {
            message = "Aucune évaluation enregistrée pour cette classe.";
        } else if (students.isEmpty()) {
            message = "Aucun élève trouvé dans cette classe.";
        } else if (!missing.isEmpty()) {
            message = missing.size() + " note(s) manquante(s) détectée(s). Tous les élèves doivent être notés.";
        } else if (!zeroCoefficients.isEmpty()) {
            message = zeroCoefficients.size() + " matière(s)/évaluation(s) avec un coefficient nul ou manquant.";
        } else {
            message = "Tous les critères sont validés. Les bulletins peuvent être publiés.";
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("ready", isReady);
        result.put("examCount", exams.size());
        result.put("studentCount", students.size());
        result.put("missing", missing);
        result.put("missingCount", missing.size());
        result.put("zeroCoefficients", zeroCoefficients);
        result.put("zeroCoefficientCount", zeroCoefficients.size());
        result.put("message", message);
        return result;
    }

    @Transactional
    public BulletinPublicationDto unpublish(String className, String period, String studentId) {
        List<BulletinPublication> currentYearPublications = academicYearService.filterCurrentYear(
                schoolContextService.scope(repository.findAll()),
                BulletinPublication::getAcademicYearId);
        BulletinPublication pub;
        if (studentId != null && !studentId.isBlank()) {
            pub = currentYearPublications.stream()
                    .filter(p -> className.equalsIgnoreCase(p.getClassName())
                            && period.equalsIgnoreCase(p.getPeriod())
                            && studentId.equals(p.getStudentId()))
                    .findFirst()
                    .orElse(null);
        } else {
            pub = currentYearPublications.stream()
                    .filter(p -> className.equalsIgnoreCase(p.getClassName())
                            && period.equalsIgnoreCase(p.getPeriod())
                            && (p.getStudentId() == null || p.getStudentId().isBlank()))
                    .findFirst()
                    .orElse(null);
        }

        if (pub != null) {
            if (pub.isPublished()) revertAnnualPromotions(pub);
            pub.setPublished(false);
            BulletinPublication saved = repository.save(pub);

            // Audit log
            try {
                auditLogService.logAction(
                        "UNPUBLISH",
                        "BULLETIN",
                        className + " - " + period,
                        "Dépublication des bulletins pour la classe " + className + " (" + period + ")",
                        "Publié",
                        "Retiré / Non publié"
                );
            } catch (Exception ignored) {}

            return mapToDto(saved);
        }
        return null;
    }

    private void revertAnnualPromotions(BulletinPublication publication) {
        if ((publication.getStudentId() != null
                && !publication.getStudentId().isBlank())
                || !"Bilan Annuel".equalsIgnoreCase(publication.getPeriod())
                || publication.getAcademicYearId() == null) {
            return;
        }
        boolean activePublicationYear = academicYearService.findActive()
                .map(year -> publication.getAcademicYearId().equals(year.getId()))
                .orElse(false);
        if (!activePublicationYear) return;

        Classroom sourceClass;
        try {
            sourceClass = publication.getPromotionSourceClassId() == null
                    ? findClassroom(publication.getClassName())
                    : findClassroom(publication.getPromotionSourceClassId());
        } catch (IllegalStateException ignored) {
            return;
        }

        for (Student student : schoolContextService.scope(studentRepository.findAll())) {
            if (!publication.getAcademicYearId().equals(student.getLastAnnualDeliberationYearId())
                    || !sourceClass.getId().equals(student.getLastAnnualDeliberationClassId())) {
                continue;
            }
            if (sourceClass.getId().equals(student.getAnnualPromotionFromClassId())
                    && student.getClassroom() != null
                    && student.getClassroom().getId().equals(student.getAnnualPromotionToClassId())) {
                student.setClassroom(sourceClass);
                student.setClassName(sourceClass.getName());
            }
            student.setLastAnnualDeliberationYearId(null);
            student.setLastAnnualDeliberationClassId(null);
            student.setAnnualPromotionFromClassId(null);
            student.setAnnualPromotionToClassId(null);
            studentRepository.save(student);
        }
    }

    @Transactional(readOnly = true)
    public BulletinPublicationDto checkStatus(String className, String period, String studentId) {
        academicYearService.autoCloseIfDue();
        List<BulletinPublication> all = academicYearService.filterCurrentYear(
                schoolContextService.scope(repository.findAll()),
                BulletinPublication::getAcademicYearId
        );

        Optional<BulletinPublication> classPub = all.stream()
                .filter(p -> className.equalsIgnoreCase(p.getClassName())
                        && period.equalsIgnoreCase(p.getPeriod())
                        && (p.getStudentId() == null || p.getStudentId().isBlank()))
                .findFirst();

        if (classPub.isPresent()) {
            return mapToDto(classPub.get());
        }

        if (studentId != null && !studentId.isBlank()) {
            Optional<BulletinPublication> studentPub = all.stream()
                    .filter(p -> className.equalsIgnoreCase(p.getClassName())
                            && period.equalsIgnoreCase(p.getPeriod())
                            && studentId.equals(p.getStudentId()))
                    .findFirst();
            if (studentPub.isPresent()) {
                return mapToDto(studentPub.get());
            }
        }

        return null;
    }

    @Transactional(readOnly = true)
    public List<BulletinPublicationDto> getPublications(String className, String period) {
        academicYearService.autoCloseIfDue();
        List<BulletinPublication> all = academicYearService.filterCurrentYear(
                schoolContextService.scope(repository.findAll()),
                BulletinPublication::getAcademicYearId
        );

        return all.stream()
                .filter(p -> className == null || className.isBlank() || className.equalsIgnoreCase(p.getClassName()))
                .filter(p -> period == null || period.isBlank() || period.equalsIgnoreCase(p.getPeriod()))
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<BulletinPublicationDto> getPublications(
            String className,
            String period,
            String studentId) {
        if (studentId == null || studentId.isBlank()) {
            return getPublications(className, period);
        }

        academicYearService.autoCloseIfDue();
        Student student = schoolContextService.scope(studentRepository.findAll()).stream()
                .filter(item -> studentId.equals(String.valueOf(item.getId())))
                .findFirst()
                .orElse(null);
        if (student == null) return List.of();

        Long activeYearId = academicYearService.findActive()
                .map(year -> year.getId())
                .orElse(null);
        List<BulletinPublication> publications = schoolContextService.scope(repository.findAll());
        return publications.stream()
                .filter(BulletinPublication::isPublished)
                .filter(publication -> publication.getStudentId() == null
                        || publication.getStudentId().isBlank()
                        || studentId.equals(publication.getStudentId()))
                .filter(publication -> period == null || period.isBlank()
                        || period.equalsIgnoreCase(publication.getPeriod()))
                .filter(publication -> {
                    boolean currentClassPublication = activeYearId != null
                            && activeYearId.equals(publication.getAcademicYearId())
                            && student.getClassName() != null
                            && student.getClassName().equalsIgnoreCase(publication.getClassName())
                            && (className == null || className.isBlank()
                                    || className.equalsIgnoreCase(publication.getClassName()));
                    boolean lastAnnualPromotion = student.getLastAnnualDeliberationYearId() != null
                            && student.getLastAnnualDeliberationClassId() != null
                            && student.getLastAnnualDeliberationYearId().equals(publication.getAcademicYearId())
                            && student.getLastAnnualDeliberationClassId().equals(
                                    publication.getPromotionSourceClassId())
                            && "Bilan Annuel".equalsIgnoreCase(publication.getPeriod());
                    return currentClassPublication || lastAnnualPromotion;
                })
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    private BulletinPublicationDto mapToDto(BulletinPublication entity) {
        BulletinPublicationDto dto = new BulletinPublicationDto();
        dto.setId(entity.getId());
        dto.setClassName(entity.getClassName());
        dto.setPeriod(entity.getPeriod());
        dto.setStudentId(entity.getStudentId());
        dto.setPublished(entity.isPublished());
        dto.setPublishedBy(entity.getPublishedBy());
        dto.setPublishedByRole(entity.getPublishedByRole());
        dto.setLanguageCode("en".equalsIgnoreCase(entity.getLanguageCode()) ? "en" : "fr");
        dto.setPublishedAt(entity.getPublishedAt());
        dto.setPromotionThreshold(entity.getPromotionThreshold());
        dto.setPromotionTargetClassName(entity.getPromotionTargetClassName());
        return dto;
    }
}
