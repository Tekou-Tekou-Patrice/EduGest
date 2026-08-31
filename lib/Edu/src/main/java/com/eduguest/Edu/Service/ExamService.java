package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.ExamDto;
import com.eduguest.Edu.DTO.GradeDto;
import com.eduguest.Edu.Entity.Exam;
import com.eduguest.Edu.Entity.Grade;
import com.eduguest.Edu.Repository.ExamRepository;
import com.eduguest.Edu.Repository.GradeRepository;
import com.eduguest.Edu.Repository.ScheduleItemRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class ExamService {
    private final ExamRepository examRepository;
    private final GradeRepository gradeRepository;
    private final AcademicYearService academicYearService;
    private final ScheduleItemRepository scheduleItemRepository;
    private final SchoolContextService schoolContextService;
    private final AppNotificationService notificationService;


    public ExamService(ExamRepository examRepository,
                       GradeRepository gradeRepository,
                       AcademicYearService academicYearService,
                       ScheduleItemRepository scheduleItemRepository,
                       SchoolContextService schoolContextService,
                       AppNotificationService notificationService) {
        this.schoolContextService = schoolContextService;
        this.examRepository = examRepository;
        this.gradeRepository = gradeRepository;
        this.academicYearService = academicYearService;
        this.scheduleItemRepository = scheduleItemRepository;
        this.notificationService = notificationService;
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
        entity.setCoefficient(dto.getCoefficient() != null ? dto.getCoefficient() : 1.0);
        entity.setSubmittedAt(LocalDateTime.now());
        try {
            entity.setAcademicYearId(academicYearService.stampCurrentYear());
        } catch (RuntimeException e) {
            entity.setAcademicYearId(academicYearService.getOrAutoCreateActiveYear().getId());
        }
        schoolContextService.verifyAndAssign(entity);
        return mapToExamDto(examRepository.save(entity));
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
            exam.setCoefficient(1.0);
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
                    notificationService.notifyGrade(savedGrade);
                    saved.add(mapToGradeDto(savedGrade));
                } catch (NumberFormatException ignored) {
                    // skip invalid scores
                }
            }
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
        grade.setScore(dto.getScore());
        grade.setObservations(dto.getObservations());
        Grade saved = gradeRepository.save(grade);
        notificationService.notifyGrade(saved);
        return mapToGradeDto(saved);
    }

    private ExamDto mapToExamDto(Exam entity) {
        ExamDto dto = new ExamDto();
        dto.setId(entity.getId());
        dto.setTitle(entity.getTitle());
        dto.setSubject(entity.getSubject());
        dto.setClassName(entity.getClassName());
        dto.setDate(entity.getDate());
        dto.setCoefficient(entity.getCoefficient());
        dto.setSubmittedAt(entity.getSubmittedAt());
        dto.setEditable(entity.getSubmittedAt() == null ||
                ChronoUnit.DAYS.between(entity.getSubmittedAt(), LocalDateTime.now()) < 7);
        return dto;
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
