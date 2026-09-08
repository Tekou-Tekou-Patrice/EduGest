package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.AbsenceDto;
import com.eduguest.Edu.DTO.SanctionDto;
import com.eduguest.Edu.Service.DisciplineService;
import com.eduguest.Edu.Config.RequireRoles;
import com.eduguest.Edu.Entity.UserRole;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/discipline")
public class DisciplineController {

    private final DisciplineService disciplineService;

    public DisciplineController(DisciplineService disciplineService) {
        this.disciplineService = disciplineService;
    }

    @GetMapping("/absences")
    public ResponseEntity<List<AbsenceDto>> getAbsences(
            @RequestParam(required = false) String className) {
        try {
            return ResponseEntity.ok(disciplineService.getAbsences(className));
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    @PostMapping("/absences")
    @RequireRoles({UserRole.ENSEIGNANT})
    public ResponseEntity<AbsenceDto> createAbsence(@Valid @RequestBody AbsenceDto dto) {
        return ResponseEntity.ok(disciplineService.createAbsence(dto));
    }

    @GetMapping("/sanctions")
    public ResponseEntity<List<SanctionDto>> getAllSanctions() {
        try {
            return ResponseEntity.ok(disciplineService.getAllSanctions());
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    @PostMapping("/sanctions")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SURVEILLANT_GENERAL, UserRole.SURVEILLANT})
    public ResponseEntity<SanctionDto> createSanction(@Valid @RequestBody SanctionDto dto) {
        return ResponseEntity.ok(disciplineService.createSanction(dto));
    }

    @DeleteMapping("/sanctions/{id}")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SURVEILLANT_GENERAL})
    public ResponseEntity<Void> deleteSanction(@PathVariable Long id) {
        disciplineService.deleteSanction(id);
        return ResponseEntity.noContent().build();
    }
}
