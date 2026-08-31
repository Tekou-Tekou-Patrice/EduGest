package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.ScheduleItemDto;
import com.eduguest.Edu.Entity.ScheduleItem;
import com.eduguest.Edu.Repository.ScheduleItemRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class ScheduleService {
    private final ScheduleItemRepository scheduleItemRepository;
    private final AcademicYearService academicYearService;
    private final SchoolContextService schoolContextService;


    public ScheduleService(ScheduleItemRepository scheduleItemRepository,
                           AcademicYearService academicYearService,
                               SchoolContextService schoolContextService) {
        this.schoolContextService = schoolContextService;
        this.scheduleItemRepository = scheduleItemRepository;
        this.academicYearService = academicYearService;
    }

    @Transactional
    public List<ScheduleItemDto> getAllScheduleItems() {
        academicYearService.autoCloseIfDue();
        return academicYearService.filterCurrentYear(schoolContextService.scope(scheduleItemRepository.findAll()), ScheduleItem::getAcademicYearId)
                .stream().map(this::mapToDto).collect(Collectors.toList());
    }

    @Transactional
    public List<ScheduleItemDto> getScheduleByDay(String day) {
        academicYearService.autoCloseIfDue();
        return academicYearService.filterCurrentYear(schoolContextService.scope(scheduleItemRepository.findByDay(day)), ScheduleItem::getAcademicYearId)
                .stream().map(this::mapToDto).collect(Collectors.toList());
    }

    @Transactional
    public List<ScheduleItemDto> getScheduleByClass(String className) {
        academicYearService.autoCloseIfDue();
        return academicYearService.filterCurrentYear(schoolContextService.scope(scheduleItemRepository.findByClassName(className)), ScheduleItem::getAcademicYearId)
                .stream().map(this::mapToDto).collect(Collectors.toList());
    }

    @Transactional
    public List<ScheduleItemDto> getScheduleByTeacher(String teacherName) {
        academicYearService.autoCloseIfDue();
        return academicYearService.filterCurrentYear(schoolContextService.scope(scheduleItemRepository.findByTeacherName(teacherName)), ScheduleItem::getAcademicYearId)
                .stream().map(this::mapToDto).collect(Collectors.toList());
    }

    @Transactional
    public ScheduleItemDto createScheduleItem(ScheduleItemDto dto) {
        ScheduleItem entity = new ScheduleItem();
        if (dto.getId() != null) {
            entity = scheduleItemRepository.findById(dto.getId()).orElse(new ScheduleItem());
        }
        entity.setDay(dto.getDay());
        entity.setStartTime(dto.getStartTime());
        entity.setEndTime(dto.getEndTime());
        entity.setSubject(dto.getSubject());
        entity.setClassName(dto.getClassName());
        entity.setTeacherName(dto.getTeacherName());
        entity.setRoom(dto.getRoom());
        entity.setBreak(dto.isBreak());
        if (entity.getAcademicYearId() == null) {
            try {
                entity.setAcademicYearId(academicYearService.stampCurrentYear());
            } catch (RuntimeException e) {
                entity.setAcademicYearId(academicYearService.getOrAutoCreateActiveYear().getId());
            }
        }
        schoolContextService.verifyAndAssign(entity);
        return mapToDto(scheduleItemRepository.save(entity));
    }

    @Transactional
    public void deleteScheduleItem(Long id) {
        if (!scheduleItemRepository.existsById(id)) {
            throw new RuntimeException("Créneau non trouvé");
        }
        scheduleItemRepository.findById(id).ifPresent(item -> {
            schoolContextService.verifyAndAssign(item);
            scheduleItemRepository.delete(item);
        });
    }

    private ScheduleItemDto mapToDto(ScheduleItem entity) {
        ScheduleItemDto dto = new ScheduleItemDto();
        dto.setId(entity.getId());
        dto.setDay(entity.getDay());
        dto.setStartTime(entity.getStartTime());
        dto.setEndTime(entity.getEndTime());
        dto.setSubject(entity.getSubject());
        dto.setClassName(entity.getClassName());
        dto.setTeacherName(entity.getTeacherName());
        dto.setRoom(entity.getRoom());
        dto.setBreak(entity.isBreak());
        return dto;
    }
}
