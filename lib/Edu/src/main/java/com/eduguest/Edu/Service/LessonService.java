package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.LessonDto;
import com.eduguest.Edu.Entity.Lesson;
import com.eduguest.Edu.Repository.LessonRepository;
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


    public LessonService(LessonRepository lessonRepository, AcademicYearService academicYearService,
                               SchoolContextService schoolContextService) {
        this.schoolContextService = schoolContextService;
        this.lessonRepository = lessonRepository;
        this.academicYearService = academicYearService;
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
        if (dto.getId() != null) {
            lesson = lessonRepository.findById(dto.getId()).orElse(new Lesson());
        } else {
            lesson = new Lesson();
        }
        lesson.setTitle(dto.getTitle());
        lesson.setContent(dto.getContent());
        lesson.setClassName(dto.getClassName());
        lesson.setSubject(dto.getSubject() != null ? dto.getSubject() : "Général");
        lesson.setDate(dto.getDate() != null ? dto.getDate() : LocalDateTime.now());
        lesson.setTeacherId(dto.getTeacherId());
        if (lesson.getAcademicYearId() == null) {
            try {
                lesson.setAcademicYearId(academicYearService.stampCurrentYear());
            } catch (RuntimeException e) {
                lesson.setAcademicYearId(academicYearService.getOrAutoCreateActiveYear().getId());
            }
        }
        schoolContextService.verifyAndAssign(lesson);
        return mapToDto(lessonRepository.save(lesson));
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
        return dto;
    }
}
