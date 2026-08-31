package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.EventDto;
import com.eduguest.Edu.Entity.Event;
import com.eduguest.Edu.Repository.EventRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class EventService {
    private final EventRepository eventRepository;
    private final AcademicYearService academicYearService;
    private final SchoolContextService schoolContextService;
    private final AppNotificationService notificationService;


    public EventService(EventRepository eventRepository, AcademicYearService academicYearService,
                        SchoolContextService schoolContextService,
                        AppNotificationService notificationService) {
        this.schoolContextService = schoolContextService;
        this.eventRepository = eventRepository;
        this.academicYearService = academicYearService;
        this.notificationService = notificationService;
    }

    @Transactional
    public List<EventDto> getAllEvents() {
        academicYearService.autoCloseIfDue();
        return academicYearService.filterCurrentYear(schoolContextService.scope(eventRepository.findAll()), Event::getAcademicYearId)
                .stream().map(this::mapToDto).collect(Collectors.toList());
    }

    @Transactional
    public EventDto createEvent(EventDto dto) {
        Event event;
        boolean isNew = dto.getId() == null;
        if (dto.getId() != null) {
            event = eventRepository.findById(dto.getId()).orElse(new Event());
            isNew = event.getId() == null;
        } else {
            event = new Event();
        }
        event.setTitle(dto.getTitle());
        event.setDate(dto.getDate() != null ? dto.getDate() : LocalDateTime.now());
        event.setHour(dto.getHour());
        event.setMinute(dto.getMinute());
        event.setCategory(dto.getCategory() != null ? dto.getCategory() : "Réunion");
        
        if (event.getAcademicYearId() == null) {
            try {
                event.setAcademicYearId(academicYearService.stampCurrentYear());
            } catch (RuntimeException e) {
                event.setAcademicYearId(academicYearService.getOrAutoCreateActiveYear().getId());
            }
        }
        
        schoolContextService.verifyAndAssign(event);
        Event saved = eventRepository.save(event);
        if (isNew) {
            notificationService.notifyEvent(saved);
        }
        return mapToDto(saved);
    }

    @Transactional
    public void deleteEvent(Long id) {
        if (!eventRepository.existsById(id)) {
            throw new RuntimeException("Événement non trouvé");
        }
        eventRepository.findById(id).ifPresent(event -> {
            schoolContextService.verifyAndAssign(event);
            eventRepository.delete(event);
        });
    }

    private EventDto mapToDto(Event entity) {
        EventDto dto = new EventDto();
        dto.setId(entity.getId());
        dto.setTitle(entity.getTitle());
        dto.setDate(entity.getDate());
        dto.setHour(entity.getHour());
        dto.setMinute(entity.getMinute());
        dto.setCategory(entity.getCategory());
        return dto;
    }
}
