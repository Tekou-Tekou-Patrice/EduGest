package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.ProgramChapterDto;
import com.eduguest.Edu.Entity.ProgramChapter;
import com.eduguest.Edu.Repository.ProgramChapterRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ProgramChapterService {
    private final ProgramChapterRepository repository;
    private final AcademicYearService academicYearService;
    private final SchoolContextService schoolContextService;
    private final AppNotificationService notificationService;

    public ProgramChapterService(
            ProgramChapterRepository repository,
            AcademicYearService academicYearService,
            SchoolContextService schoolContextService,
            AppNotificationService notificationService) {
        this.repository = repository;
        this.academicYearService = academicYearService;
        this.schoolContextService = schoolContextService;
        this.notificationService = notificationService;
    }

    @Transactional
    public List<ProgramChapterDto> getChapters(String teacherId, String className, Boolean completed) {
        academicYearService.autoCloseIfDue();
        List<ProgramChapter> chapters;
        if (teacherId != null && !teacherId.isBlank()) {
            chapters = repository.findByTeacherId(teacherId);
        } else if (className != null && !className.isBlank()) {
            chapters = repository.findCompletedByClassName(className);
        } else {
            chapters = repository.findAll();
        }

        return academicYearService
                .filterCurrentYear(schoolContextService.scope(chapters), ProgramChapter::getAcademicYearId)
                .stream()
                .filter(chapter -> completed == null || chapter.isCompleted() == completed)
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public ProgramChapterDto saveChapter(ProgramChapterDto dto) {
        if (dto.getMajorChapter() == null || dto.getMajorChapter().isBlank()) {
            throw new IllegalArgumentException("Le grand chapitre est obligatoire");
        }
        if (dto.getClassName() == null || dto.getClassName().isBlank()) {
            throw new IllegalArgumentException("La classe est obligatoire");
        }
        if (dto.getSubject() == null || dto.getSubject().isBlank()) {
            throw new IllegalArgumentException("La matière est obligatoire");
        }
        if (dto.getTeacherId() == null || dto.getTeacherId().isBlank()) {
            throw new IllegalArgumentException("Le professeur est obligatoire");
        }

        ProgramChapter chapter = dto.getId() == null
                ? new ProgramChapter()
                : repository.findById(dto.getId()).orElse(new ProgramChapter());
        chapter.setMajorChapter(dto.getMajorChapter().trim());
        chapter.setSubChapter(dto.getSubChapter() == null || dto.getSubChapter().isBlank()
                ? null : dto.getSubChapter().trim());
        chapter.setClassName(dto.getClassName().trim());
        chapter.setSubject(dto.getSubject().trim());
        chapter.setTeacherId(dto.getTeacherId().trim());
        chapter.setTeacherName(dto.getTeacherName());
        chapter.setCompleted(dto.isCompleted());
        chapter.setCompletedAt(dto.isCompleted()
                ? (chapter.getCompletedAt() == null ? LocalDateTime.now() : chapter.getCompletedAt())
                : null);
        if (chapter.getCreatedAt() == null) {
            chapter.setCreatedAt(LocalDateTime.now());
        }
        if (chapter.getAcademicYearId() == null) {
            chapter.setAcademicYearId(academicYearService.stampCurrentYear());
        }
        schoolContextService.verifyAndAssign(chapter);
        ProgramChapterDto result = mapToDto(repository.save(chapter));
        notificationService.notifyProgramChapterUpdated(
                chapter.getClassName(), chapter.getSubject(), chapter.getMajorChapter(),
                chapter.getTeacherName(), chapter.isCompleted());
        return result;
    }

    @Transactional
    public ProgramChapterDto setCompleted(Long id, boolean completed) {
        ProgramChapter chapter = schoolContextService.scope(repository.findAll()).stream()
                .filter(item -> item.getId().equals(id))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Chapitre introuvable"));
        chapter.setCompleted(completed);
        chapter.setCompletedAt(completed ? LocalDateTime.now() : null);
        ProgramChapterDto result = mapToDto(repository.save(chapter));
        notificationService.notifyProgramChapterUpdated(
                chapter.getClassName(), chapter.getSubject(), chapter.getMajorChapter(),
                chapter.getTeacherName(), chapter.isCompleted());
        return result;
    }

    private ProgramChapterDto mapToDto(ProgramChapter entity) {
        ProgramChapterDto dto = new ProgramChapterDto();
        dto.setId(entity.getId());
        dto.setMajorChapter(entity.getMajorChapter());
        dto.setSubChapter(entity.getSubChapter());
        dto.setClassName(entity.getClassName());
        dto.setSubject(entity.getSubject());
        dto.setTeacherId(entity.getTeacherId());
        dto.setTeacherName(entity.getTeacherName());
        dto.setCompleted(entity.isCompleted());
        dto.setCompletedAt(entity.getCompletedAt());
        dto.setCreatedAt(entity.getCreatedAt());
        return dto;
    }
}
