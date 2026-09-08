package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.SubjectDto;
import com.eduguest.Edu.Service.SubjectService;
import com.eduguest.Edu.Config.RequireRoles;
import com.eduguest.Edu.Entity.UserRole;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/academique/subjects")
public class SubjectController {

    private final SubjectService subjectService;

    public SubjectController(SubjectService subjectService) {
        this.subjectService = subjectService;
    }

    @GetMapping
    public ResponseEntity<List<SubjectDto>> getAllSubjects() {
        return ResponseEntity.ok(subjectService.getAllSubjects());
    }

    @PostMapping
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR})
    public ResponseEntity<SubjectDto> createSubject(@Valid @RequestBody SubjectDto dto) {
        return ResponseEntity.ok(subjectService.createSubject(dto));
    }

    @DeleteMapping("/{id}")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR})
    public ResponseEntity<Void> deleteSubject(@PathVariable Long id) {
        subjectService.deleteSubject(id);
        return ResponseEntity.noContent().build();
    }
}
