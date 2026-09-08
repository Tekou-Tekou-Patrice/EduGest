package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.ExamDto;
import com.eduguest.Edu.DTO.GradeDto;
import com.eduguest.Edu.Entity.Exam;
import com.eduguest.Edu.Entity.Grade;
import com.eduguest.Edu.Entity.Subject;
import com.eduguest.Edu.Repository.ExamRepository;
import com.eduguest.Edu.Repository.GradeRepository;
import com.eduguest.Edu.Repository.ScheduleItemRepository;
import com.eduguest.Edu.Repository.SubjectRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class ExamService {
    private final ExamRepository examRepository;
    private final GradeRepository gradeRepository;
    private final AcademicYearService academicYearService;
    private final ScheduleItemRepository scheduleItemRepository;
    private final SchoolContextService schoolContextService;
    private final AppNotificationService notificationService;
    private final SubjectRepository subjectRepository;
    private final AuditLogService auditLogService;

    public ExamService(ExamRepository examRepository,
                       GradeRepository gradeRepository,
                       AcademicYearService academicYearService,
                       ScheduleItemRepository scheduleItemRepository,
                       SchoolContextService schoolContextService,
                       AppNotificationService notificationService,
                       SubjectRepository subjectRepository,
                       AuditLogService auditLogService) {
        this.schoolContextService = schoolContextService;
        this.examRepository = examRepository;
        this.gradeRepository = gradeRepository;
        this.academicYearService = academicYearService;
        this.scheduleItemRepository = scheduleItemRepository;
        this.notificationService = notificationService;
        this.subjectRepository = subjectRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional
    public List<ExamDto> getAllExams() {
        academicYearService.autoCloseIfDue();
        return academicYearService.filterCurrentYear(schoolContextService.scope(examRepository.findAll()), Exam::getAcademicYearId)
                .stream().map(this::mapToExamDto).collect(Collectors.toList());
    }

    @Transactional
    public List<ExamDto> getExamsByClass(String className) {
        academicYearService.autoCloseIfDue();
        return academicYearService.filterCurrentYear(schoolContextService.scope(examRepository.findByClassName(className)), Exam::getAcademicYearId)
                .stream().map(this::mapToExamDto).collect(Collectors.toList());
    }

    @Transactional
    public List<ExamDto> getUpcomingExams() {
        academicYearService.autoCloseIfDue();
        return academicYearService.filterCurrentYear(schoolContextService.scope(examRepository.findUpcomingExams()), Exam::getAcademicYearId)
                .stream().map(this::mapToExamDto).collect(Collectors.toList());
    }

    @Transactional
    public ExamDto createExam(ExamDto dto) {
        Exam entity = new Exam();
        entity.setTitle(dto.getTitle());
        entity.setSubject(dto.getSubject());
        entity.setClassName(dto.getClassName());
        entity.setDate(dto.getDate() != null ? dto.getDate() : LocalDateTime.now());
        entity.setTeacherName(dto.getTeacherName());
        entity.setCoefficient(dto.getCoefficient() != null && dto.getCoefficient() > 0
                ? dto.getCoefficient()
                : findSubjectCoefficient(dto.getSubject()).orElse(1.0));
        entity.setSubmittedAt(LocalDateTime.now());
        try {
            entity.setAcademicYearId(academicYearService.stampCurrentYear());
        } catch (RuntimeException e) {
            entity.setAcademicYearId(academicYearService.getOrAutoCreateActiveYear().getId());
        }
        schoolContextService.verifyAndAssign(entity);
        Exam saved = examRepository.save(entity);

        try {
            auditLogService.logAction(
                    "CREATE",
                    "EVALUATION",
                    saved.getId().toString(),
                    "Création évaluation : " + saved.getTitle() + " (" + saved.getClassName() + " - " + saved.getSubject() + ")",
                    null,
                    "Coeff: " + saved.getCoefficient() + ", Enseignant: " + saved.getTeacherName()
            );
        } catch (Exception ignored) {}

        return mapToExamDto(saved);
    }

    @Transactional(readOnly = true)
    public List<GradeDto> getGradesByExam(String examId) {
        return gradeRepository.findByExamId(examId).stream().map(this::mapToGradeDto).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Double getExamAverage(String examId) {
        return gradeRepository.getAverageByExam(examId);
    }

    @Transactional
    public GradeDto saveGrade(GradeDto dto) {
        Grade entity = new Grade();
        entity.setStudentId(dto.getStudentId());
        entity.setExamId(dto.getExamId());
        entity.setScore(dto.getScore());
        entity.setObservations(dto.getObservations());
        try {
            entity.setAcademicYearId(academicYearService.stampCurrentYear());
        } catch (RuntimeException e) {
            entity.setAcademicYearId(academicYearService.getOrAutoCreateActiveYear().getId());
        }
        schoolContextService.verifyAndAssign(entity);
        Grade saved = gradeRepository.save(entity);

        try {
            auditLogService.logAction(
                    "CREATE",
                    "NOTE",
                    saved.getId().toString(),
                    "Saisie de note individuelle pour élève ID " + saved.getStudentId() + " (Éval " + saved.getExamId() + ")",
                    null,
                    "Note: " + saved.getScore() + "/20"
            );
        } catch (Exception ignored) {}

        notificationService.notifyGrade(saved);
        return mapToGradeDto(saved);
    }

    /**
     * Accepte le payload Flutter: { classe, sequence, grades: { studentId: score } }
     * ou une liste de GradeDto.
     */
    @Transactional
    @SuppressWarnings("unchecked")
    public List<GradeDto> saveGradesBatch(Map<String, Object> payload) {
        List<GradeDto> saved = new ArrayList<>();

        if (payload.containsKey("grades") && payload.get("grades") instanceof Map<?, ?> rawGrades) {
            String className = payload.get("classe") != null ? payload.get("classe").toString() : "Général";
            String sequence = payload.get("sequence") != null ? payload.get("sequence").toString() : "Séquence";
            String subject = payload.get("subject") != null ? payload.get("subject").toString() : "Général";
            String teacherName = payload.get("teacherName") == null ? "" : payload.get("teacherName").toString().trim();
            if (!teacherName.isBlank() && schoolContextService.scope(scheduleItemRepository.findByTeacherName(teacherName)).stream()
                    .noneMatch(item -> className.equals(item.getClassName()) && subject.equals(item.getSubject()))) {
                throw new IllegalArgumentException("Cette matière ou cette classe n'est pas attribuée à cet enseignant.");
            }

            Long yearId;
            try {
                yearId = academicYearService.stampCurrentYear();
            } catch (RuntimeException e) {
                yearId = academicYearService.getOrAutoCreateActiveYear().getId();
            }

            String title = sequence + " - " + className;
            Exam exam = examRepository.findFirstByTitleAndClassNameAndSubject(title, className, subject)
                    .orElseGet(Exam::new);
            if (exam.getSubmittedAt() != null &&
                    ChronoUnit.DAYS.between(exam.getSubmittedAt(), LocalDateTime.now()) >= 7) {
                throw new IllegalStateException("La période de modification des notes est expirée (7 jours).");
            }
            exam.setTitle(title);
            exam.setSubject(subject);
            exam.setClassName(className);
            exam.setDate(exam.getDate() == null ? LocalDateTime.now() : exam.getDate());
            exam.setSubmittedAt(exam.getSubmittedAt() == null ? LocalDateTime.now() : exam.getSubmittedAt());

            Double coef = null;
            if (payload.get("coefficient") != null) {
                try {
                    coef = Double.parseDouble(payload.get("coefficient").toString().replace(',', '.'));
                } catch (Exception ignored) {}
            }
            if (coef == null || coef <= 0) {
                coef = findSubjectCoefficient(subject).orElse(1.0);
            }
            exam.setCoefficient(coef != null && coef > 0 ? coef : 1.0);

            if (!teacherName.isBlank()) {
                exam.setTeacherName(teacherName);
            }
            exam.setAcademicYearId(yearId);
            schoolContextService.verifyAndAssign(exam);
            Exam savedExam = examRepository.save(exam);
            String examId = String.valueOf(savedExam.getId());

            for (Map.Entry<?, ?> entry : rawGrades.entrySet()) {
                String studentId = String.valueOf(entry.getKey());
                if (entry.getValue() == null || entry.getValue().toString().isBlank()) {
                    continue;
                }
                try {
                    double score = Double.parseDouble(entry.getValue().toString().replace(',', '.'));
                    Grade grade = new Grade();
                    grade.setStudentId(studentId);
                    grade.setExamId(examId);
                    grade.setScore(score);
                    grade.setAcademicYearId(yearId);
                    schoolContextService.verifyAndAssign(grade);
                    Grade savedGrade = gradeRepository.save(grade);
                    saved.add(mapToGradeDto(savedGrade));
                } catch (NumberFormatException ignored) {
                    // skip invalid scores
                }
            }

            // Journal d'audit pour le lot de notes
            try {
                auditLogService.logAction(
                        "CREATE",
                        "NOTE",
                        examId,
                        "Saisie bordereau notes : " + subject + " (" + className + ", " + sequence + ")",
                        null,
                        saved.size() + " note(s) saisie(s) par " + (teacherName.isBlank() ? "l'enseignant" : teacherName),
                        teacherName,
                        "Enseignant"
                );
            } catch (Exception ignored) {}

            // Notification ciblée aux parents pour la matière publiée
            try {
                notificationService.notifyNotesPublished(className, subject, sequence, teacherName);
            } catch (Exception ignored) {}

            return saved;
        }

        if (payload.containsKey("items") && payload.get("items") instanceof List<?> items) {
            for (Object item : items) {
                if (item instanceof Map<?, ?> map) {
                    GradeDto dto = new GradeDto();
                    dto.setStudentId(String.valueOf(map.get("studentId")));
                    dto.setExamId(String.valueOf(map.get("examId")));
                    Object score = map.get("score");
                    if (score != null) {
                        dto.setScore(Double.parseDouble(score.toString()));
                    }
                    if (map.get("observations") != null) {
                        dto.setObservations(map.get("observations").toString());
                    }
                    saved.add(saveGrade(dto));
                }
            }
        }

        return saved;
    }

    @Transactional
    public GradeDto updateGrade(Long gradeId, GradeDto dto) {
        Grade grade = gradeRepository.findById(gradeId)
                .orElseThrow(() -> new RuntimeException("Note introuvable"));
        Exam exam = examRepository.findById(Long.valueOf(grade.getExamId()))
                .orElseThrow(() -> new RuntimeException("Évaluation introuvable"));
        schoolContextService.verifyAndAssign(grade);
        schoolContextService.verifyAndAssign(exam);
        if (exam.getSubmittedAt() != null &&
                ChronoUnit.DAYS.between(exam.getSubmittedAt(), LocalDateTime.now()) >= 7) {
            throw new IllegalStateException("La période de modification des notes est expirée (7 jours).");
        }

        double oldScore = grade.getScore();
        String oldObs = grade.getObservations();

        grade.setScore(dto.getScore());
        grade.setObservations(dto.getObservations());
        Grade saved = gradeRepository.save(grade);

        try {
            auditLogService.logAction(
                    "UPDATE",
                    "NOTE",
                    saved.getId().toString(),
                    "Modification note élève ID " + saved.getStudentId() + " (" + exam.getSubject() + " - " + exam.getClassName() + ")",
                    "Note: " + oldScore + "/20" + (oldObs != null && !oldObs.isBlank() ? " (" + oldObs + ")" : ""),
                    "Note: " + dto.getScore() + "/20" + (dto.getObservations() != null && !dto.getObservations().isBlank() ? " (" + dto.getObservations() + ")" : "")
            );
        } catch (Exception ignored) {}

        notificationService.notifyGrade(saved);
        return mapToGradeDto(saved);
    }

    @Transactional
    public void deleteGrade(Long id) {
        Grade grade = gradeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Note introuvable"));
        schoolContextService.verifyAndAssign(grade);
        try {
            auditLogService.logAction(
                    "DELETE",
                    "NOTE",
                    grade.getId().toString(),
                    "Suppression note élève ID " + grade.getStudentId() + " (Éval " + grade.getExamId() + ")",
                    "Note: " + grade.getScore() + "/20",
                    "Supprimé"
            );
        } catch (Exception ignored) {}
        gradeRepository.delete(grade);
    }

    @Transactional
    public void deleteExam(Long id) {
        Exam exam = examRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Évaluation introuvable"));
        schoolContextService.verifyAndAssign(exam);
        try {
            auditLogService.logAction(
                    "DELETE",
                    "EVALUATION",
                    exam.getId().toString(),
                    "Suppression évaluation : " + exam.getTitle() + " (" + exam.getClassName() + " - " + exam.getSubject() + ")",
                    "Coeff: " + exam.getCoefficient() + ", Enseignant: " + exam.getTeacherName(),
                    "Supprimé"
            );
        } catch (Exception ignored) {}
        List<Grade> grades = gradeRepository.findByExamId(String.valueOf(id));
        gradeRepository.deleteAll(grades);
        examRepository.delete(exam);
    }

    /**
     * Recherche les matières attendues par classe (selon l'emploi du temps)
     * qui n'ont pas encore été transmises / saisies pour la période indiquée.
     */
    @Transactional(readOnly = true)
    public List<Map<String, Object>> getPendingSubjectSubmissions(String period) {
        List<com.eduguest.Edu.Entity.ScheduleItem> schedules = schoolContextService.scope(scheduleItemRepository.findAll());
        List<Exam> exams = academicYearService.filterCurrentYear(
                schoolContextService.scope(examRepository.findAll()),
                Exam::getAcademicYearId
        );

        Map<String, Set<String>> submittedByClass = new HashMap<>();
        for (Exam exam : exams) {
            if (period == null || period.isBlank() ||
                    (exam.getTitle() != null && exam.getTitle().toLowerCase().contains(period.trim().toLowerCase()))) {
                if (exam.getClassName() != null && exam.getSubject() != null) {
                    submittedByClass
                            .computeIfAbsent(exam.getClassName().trim().toLowerCase(), k -> new HashSet<>())
                            .add(exam.getSubject().trim().toLowerCase());
                }
            }
        }

        Map<String, Map<String, Object>> pending = new LinkedHashMap<>();
        for (var item : schedules) {
            String className = item.getClassName();
            String subject = item.getSubject();
            if (className == null || className.isBlank() || subject == null || subject.isBlank()) continue;

            Set<String> done = submittedByClass.getOrDefault(className.trim().toLowerCase(), Collections.emptySet());
            if (!done.contains(subject.trim().toLowerCase())) {
                String key = className.trim() + "___" + subject.trim();
                if (!pending.containsKey(key)) {
                    Map<String, Object> map = new LinkedHashMap<>();
                    map.put("className", className);
                    map.put("subject", subject);
                    map.put("teacherName", item.getTeacherName() != null ? item.getTeacherName() : "Non assigné");
                    map.put("period", period != null && !period.isBlank() ? period : "En cours");
                    pending.put(key, map);
                }
            }
        }
        return new ArrayList<>(pending.values());
    }

    private ExamDto mapToExamDto(Exam entity) {
        ExamDto dto = new ExamDto();
        dto.setId(entity.getId());
        dto.setTitle(entity.getTitle());
        dto.setSubject(entity.getSubject());
        dto.setClassName(entity.getClassName());
        dto.setDate(entity.getDate());
        Double coef = entity.getCoefficient();
        if (coef == null || coef == 1.0) {
            java.util.Optional<Double> subCoef = findSubjectCoefficient(entity.getSubject());
            if (subCoef.isPresent() && subCoef.get() > 0) {
                coef = subCoef.get();
            }
        }
        dto.setCoefficient(coef != null && coef > 0 ? coef : 1.0);
        dto.setTeacherName(entity.getTeacherName());
        dto.setSubmittedAt(entity.getSubmittedAt());
        dto.setEditable(entity.getSubmittedAt() == null ||
                ChronoUnit.DAYS.between(entity.getSubmittedAt(), LocalDateTime.now()) < 7);
        return dto;
    }

    private java.util.Optional<Double> findSubjectCoefficient(String subjectName) {
        if (subjectName == null || subjectName.isBlank()) {
            return java.util.Optional.empty();
        }
        var scopedList = schoolContextService.scope(subjectRepository.findAll());
        var match = scopedList.stream()
                .filter(subject -> subject.getName() != null
                        && subject.getName().trim().equalsIgnoreCase(subjectName.trim()))
                .map(Subject::getCoefficient)
                .filter(coefficient -> coefficient != null && coefficient > 0)
                .findFirst();
        if (match.isPresent()) {
            return match;
        }
        return subjectRepository.findAll().stream()
                .filter(subject -> subject.getName() != null
                        && subject.getName().trim().equalsIgnoreCase(subjectName.trim()))
                .map(Subject::getCoefficient)
                .filter(coefficient -> coefficient != null && coefficient > 0)
                .findFirst();
    }

    private GradeDto mapToGradeDto(Grade entity) {
        GradeDto dto = new GradeDto();
        dto.setId(entity.getId());
        dto.setStudentId(entity.getStudentId());
        dto.setExamId(entity.getExamId());
        dto.setScore(entity.getScore());
        dto.setObservations(entity.getObservations());
        return dto;
    }
}
