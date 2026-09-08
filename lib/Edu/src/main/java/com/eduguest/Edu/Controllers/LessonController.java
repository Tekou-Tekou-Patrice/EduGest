package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.Config.RequireRoles;
import com.eduguest.Edu.DTO.LessonDto;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Service.LessonService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/academique/lessons")
public class LessonController {

    private final LessonService lessonService;

    public LessonController(LessonService lessonService) {
        this.lessonService = lessonService;
    }

    @GetMapping
    public ResponseEntity<List<LessonDto>> getLessons(
            @RequestParam(required = false) String teacherId) {
        try {
            if (teacherId != null && !teacherId.isEmpty()) {
                return ResponseEntity.ok(lessonService.getLessonsByTeacherId(teacherId));
            }
            return ResponseEntity.ok(lessonService.getAllLessons());
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    @PostMapping
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.ENSEIGNANT})
    public ResponseEntity<LessonDto> createLesson(@Valid @RequestBody LessonDto dto) {
        return ResponseEntity.ok(lessonService.createLesson(dto));
    }

    @DeleteMapping("/{id}")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.ENSEIGNANT})
    public ResponseEntity<Void> deleteLesson(@PathVariable Long id) {
        lessonService.deleteLesson(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/class/{className}")
    public ResponseEntity<List<LessonDto>> getLessonsByClass(@PathVariable String className) {
        try {
            return ResponseEntity.ok(lessonService.getLessonsByClass(className));
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }
}
