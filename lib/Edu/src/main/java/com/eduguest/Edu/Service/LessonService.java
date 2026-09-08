package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.LessonDto;
import com.eduguest.Edu.Entity.Lesson;
import com.eduguest.Edu.Entity.User;
import com.eduguest.Edu.Repository.LessonRepository;
import com.eduguest.Edu.Repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class LessonService {
    private final LessonRepository lessonRepository;
    private final AcademicYearService academicYearService;
    private final SchoolContextService schoolContextService;
    private final UserRepository userRepository;
    private final AuditLogService auditLogService;
    private final AppNotificationService notificationService;

    public LessonService(LessonRepository lessonRepository,
                         AcademicYearService academicYearService,
                         SchoolContextService schoolContextService,
                         UserRepository userRepository,
                         AuditLogService auditLogService,
                         AppNotificationService notificationService) {
        this.schoolContextService = schoolContextService;
        this.lessonRepository = lessonRepository;
        this.academicYearService = academicYearService;
        this.userRepository = userRepository;
        this.auditLogService = auditLogService;
        this.notificationService = notificationService;
    }

    @Transactional
    public List<LessonDto> getAllLessons() {
        academicYearService.autoCloseIfDue();
        return academicYearService.filterCurrentYear(schoolContextService.scope(lessonRepository.findAll()), Lesson::getAcademicYearId)
                .stream().map(this::mapToDto).collect(Collectors.toList());
    }

    @Transactional
    public LessonDto createLesson(LessonDto dto) {
        Lesson lesson;
        boolean isUpdate = false;
        String oldTitle = null;
        String oldContent = null;

        if (dto.getId() != null) {
            lesson = lessonRepository.findById(dto.getId()).orElse(new Lesson());
            if (lesson.getId() != null) {
                isUpdate = true;
                oldTitle = lesson.getTitle();
                oldContent = lesson.getContent();
            }
        } else {
            lesson = new Lesson();
        }

        lesson.setTitle(dto.getTitle());
        lesson.setContent(dto.getContent());
        lesson.setClassName(dto.getClassName());
        lesson.setSubject(dto.getSubject() != null ? dto.getSubject() : "Général");
        lesson.setDate(dto.getDate() != null ? dto.getDate() : LocalDateTime.now());
        lesson.setTeacherId(dto.getTeacherId());

        String teacherName = dto.getTeacherName();
        if ((teacherName == null || teacherName.isBlank()) && dto.getTeacherId() != null) {
            try {
                Long uid = Long.parseLong(dto.getTeacherId());
                teacherName = userRepository.findById(uid).map(User::getFullName).orElse(null);
            } catch (Exception ignored) {}
        }
        lesson.setTeacherName(teacherName);

        if (lesson.getAcademicYearId() == null) {
            try {
                lesson.setAcademicYearId(academicYearService.stampCurrentYear());
            } catch (RuntimeException e) {
                lesson.setAcademicYearId(academicYearService.getOrAutoCreateActiveYear().getId());
            }
        }

        schoolContextService.verifyAndAssign(lesson);
        Lesson saved = lessonRepository.save(lesson);

        // Audit Log
        try {
            if (isUpdate) {
                auditLogService.logAction(
                        "UPDATE",
                        "CAHIER_TEXTE",
                        saved.getId().toString(),
                        "Modification leçon : " + saved.getTitle() + " (" + saved.getClassName() + " - " + saved.getSubject() + ")",
                        "Titre: " + oldTitle + (oldContent != null ? " | Contenu: " + oldContent : ""),
                        "Titre: " + saved.getTitle() + (saved.getContent() != null ? " | Contenu: " + saved.getContent() : ""),
                        saved.getTeacherName(),
                        "Enseignant"
                );
            } else {
                auditLogService.logAction(
                        "CREATE",
                        "CAHIER_TEXTE",
                        saved.getId().toString(),
                        "Publication cahier de texte : " + saved.getTitle() + " (" + saved.getClassName() + " - " + saved.getSubject() + ")",
                        null,
                        "Titre: " + saved.getTitle() + ", Enseignant: " + saved.getTeacherName(),
                        saved.getTeacherName(),
                        "Enseignant"
                );
                // Notification ciblée
                notificationService.notifyNewLesson(saved.getClassName(), saved.getSubject(), saved.getTitle(), saved.getTeacherName());
            }
        } catch (Exception ignored) {}

        return mapToDto(saved);
    }

    @Transactional
    public void deleteLesson(Long id) {
        Lesson lesson = lessonRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Leçon introuvable"));
        schoolContextService.verifyAndAssign(lesson);

        try {
            auditLogService.logAction(
                    "DELETE",
                    "CAHIER_TEXTE",
                    id.toString(),
                    "Suppression leçon : " + lesson.getTitle() + " (" + lesson.getClassName() + " - " + lesson.getSubject() + ")",
                    "Titre: " + lesson.getTitle() + " (" + lesson.getTeacherName() + ")",
                    "Supprimé"
            );
        } catch (Exception ignored) {}

        lessonRepository.delete(lesson);
    }

    @Transactional
    public List<LessonDto> getLessonsByClass(String className) {
        academicYearService.autoCloseIfDue();
        return academicYearService.filterCurrentYear(schoolContextService.scope(lessonRepository.findByClassName(className)), Lesson::getAcademicYearId)
                .stream().map(this::mapToDto).collect(Collectors.toList());
    }

    @Transactional
    public List<LessonDto> getLessonsByTeacherId(String teacherId) {
        academicYearService.autoCloseIfDue();
        return academicYearService.filterCurrentYear(schoolContextService.scope(lessonRepository.findByTeacherId(teacherId)), Lesson::getAcademicYearId)
                .stream().map(this::mapToDto).collect(Collectors.toList());
    }

    private LessonDto mapToDto(Lesson entity) {
        LessonDto dto = new LessonDto();
        dto.setId(entity.getId());
        dto.setTitle(entity.getTitle());
        dto.setContent(entity.getContent());
        dto.setClassName(entity.getClassName());
        dto.setSubject(entity.getSubject());
        dto.setDate(entity.getDate());
        dto.setTeacherId(entity.getTeacherId());
        dto.setTeacherName(entity.getTeacherName());
        return dto;
    }
}
