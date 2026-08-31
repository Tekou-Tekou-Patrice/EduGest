package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.ScheduleItemDto;
import com.eduguest.Edu.Service.ScheduleService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/academique/schedule")
public class ScheduleController {

    private final ScheduleService scheduleService;

    public ScheduleController(ScheduleService scheduleService) {
        this.scheduleService = scheduleService;
    }

    @GetMapping
    public ResponseEntity<List<ScheduleItemDto>> getSchedule(
            @RequestParam(required = false) String day,
            @RequestParam(required = false) String teacherName,
            @RequestParam(required = false) String className) {

        try {
            List<ScheduleItemDto> items;

            if (day != null && !day.isBlank()) {
                items = scheduleService.getScheduleByDay(day);
            } else if (className != null && !className.isBlank()) {
                items = scheduleService.getScheduleByClass(className);
            } else if (teacherName != null && !teacherName.isBlank()) {
                items = scheduleService.getScheduleByTeacher(teacherName);
            } else {
                items = scheduleService.getAllScheduleItems();
            }

            // Filtre enseignant additionnel (ex: day + teacherName)
            if (teacherName != null && !teacherName.isBlank() && day != null && !day.isBlank()) {
                String teacher = teacherName.trim().toLowerCase();
                items = items.stream()
                        .filter(i -> i.getTeacherName() != null
                                && i.getTeacherName().toLowerCase().contains(teacher))
                        .collect(Collectors.toList());
            }

            if (className != null && !className.isBlank() && day != null && !day.isBlank()) {
                String cn = className.trim().toLowerCase();
                items = items.stream()
                        .filter(i -> i.getClassName() != null
                                && i.getClassName().toLowerCase().contains(cn))
                        .collect(Collectors.toList());
            }

            return ResponseEntity.ok(items);
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    @GetMapping("/day/{day}")
    public ResponseEntity<List<ScheduleItemDto>> getScheduleByDay(@PathVariable String day) {
        try {
            return ResponseEntity.ok(scheduleService.getScheduleByDay(day));
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    @GetMapping("/class/{className}")
    public ResponseEntity<List<ScheduleItemDto>> getScheduleByClass(@PathVariable String className) {
        try {
            return ResponseEntity.ok(scheduleService.getScheduleByClass(className));
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    @GetMapping("/teacher/{teacherName}")
    public ResponseEntity<List<ScheduleItemDto>> getScheduleByTeacher(@PathVariable String teacherName) {
        try {
            return ResponseEntity.ok(scheduleService.getScheduleByTeacher(teacherName));
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    @PostMapping
    public ResponseEntity<ScheduleItemDto> createScheduleItem(@Valid @RequestBody ScheduleItemDto dto) {
        return ResponseEntity.ok(scheduleService.createScheduleItem(dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteScheduleItem(@PathVariable Long id) {
        scheduleService.deleteScheduleItem(id);
        return ResponseEntity.noContent().build();
    }
}
