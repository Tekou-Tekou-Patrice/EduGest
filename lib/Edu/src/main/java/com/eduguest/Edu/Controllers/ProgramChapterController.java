package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.ProgramChapterDto;
import com.eduguest.Edu.Config.RequireRoles;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Service.ProgramChapterService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/academique/program")
public class ProgramChapterController {
    private final ProgramChapterService service;

    public ProgramChapterController(ProgramChapterService service) {
        this.service = service;
    }

    @GetMapping
    public ResponseEntity<List<ProgramChapterDto>> getChapters(
            @RequestParam(required = false) String teacherId,
            @RequestParam(required = false) String className,
            @RequestParam(required = false) Boolean completed) {
        return ResponseEntity.ok(service.getChapters(teacherId, className, completed));
    }

    @PostMapping
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.ENSEIGNANT})
    public ResponseEntity<ProgramChapterDto> saveChapter(@Valid @RequestBody ProgramChapterDto dto) {
        return ResponseEntity.ok(service.saveChapter(dto));
    }

    @PutMapping("/{id}/completed")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.ENSEIGNANT})
    public ResponseEntity<ProgramChapterDto> setCompleted(
            @PathVariable Long id,
            @RequestParam boolean completed) {
        return ResponseEntity.ok(service.setCompleted(id, completed));
    }
}
