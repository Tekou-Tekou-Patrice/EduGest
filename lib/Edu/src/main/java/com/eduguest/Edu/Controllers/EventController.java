package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.EventDto;
import com.eduguest.Edu.Service.EventService;
import com.eduguest.Edu.Config.RequireRoles;
import com.eduguest.Edu.Entity.UserRole;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/academique/events")
public class EventController {

    private final EventService eventService;

    public EventController(EventService eventService) {
        this.eventService = eventService;
    }

    @GetMapping
    public ResponseEntity<List<EventDto>> getAllEvents() {
        try {
            return ResponseEntity.ok(eventService.getAllEvents());
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    @PostMapping
    @RequireRoles({
            UserRole.FONDATEUR,
            UserRole.PROVISEUR,
            UserRole.CENSEUR,
            UserRole.SECRETAIRE,
            UserRole.COMPTABLE,
            UserRole.SURVEILLANT_GENERAL,
            UserRole.SURVEILLANT
    })
    public ResponseEntity<EventDto> createEvent(@Valid @RequestBody EventDto dto) {
        return ResponseEntity.ok(eventService.createEvent(dto));
    }

    @DeleteMapping("/{id}")
    @RequireRoles({
            UserRole.FONDATEUR,
            UserRole.PROVISEUR,
            UserRole.CENSEUR,
            UserRole.SECRETAIRE,
            UserRole.COMPTABLE,
            UserRole.SURVEILLANT_GENERAL,
            UserRole.SURVEILLANT
    })
    public ResponseEntity<Void> deleteEvent(@PathVariable Long id) {
        eventService.deleteEvent(id);
        return ResponseEntity.noContent().build();
    }
}
