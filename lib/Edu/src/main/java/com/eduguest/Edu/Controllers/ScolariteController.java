package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.ClassroomDto;
import com.eduguest.Edu.DTO.StudentDto;
import com.eduguest.Edu.DTO.TeacherDto;
import com.eduguest.Edu.Service.ScolariteService;
import com.eduguest.Edu.Service.UserSecurityContextService;
import com.eduguest.Edu.Config.RequireRoles;
import com.eduguest.Edu.Entity.UserRole;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/scolarite")
public class ScolariteController {

    private final ScolariteService scolariteService;
    private final UserSecurityContextService securityContextService;

    public ScolariteController(ScolariteService scolariteService,
                               UserSecurityContextService securityContextService) {
        this.scolariteService = scolariteService;
        this.securityContextService = securityContextService;
    }

    // --- ENSEIGNANTS ---
    @GetMapping("/teachers")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SECRETAIRE, UserRole.ENSEIGNANT})
    public ResponseEntity<List<TeacherDto>> getTeachers(@RequestParam(required = false) String query) {
        return ResponseEntity.ok(scolariteService.getTeachers(query));
    }

    @PostMapping("/teachers")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR})
    public ResponseEntity<TeacherDto> createTeacher(@Valid @RequestBody TeacherDto dto) {
        return ResponseEntity.ok(scolariteService.createTeacher(dto));
    }

    @DeleteMapping("/teachers/{id}")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SECRETAIRE})
    public ResponseEntity<Void> deleteTeacher(@PathVariable Long id) {
        scolariteService.deleteTeacher(id);
        return ResponseEntity.noContent().build();
    }

    // --- ÉLÈVES ---
    @GetMapping("/students")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SECRETAIRE, UserRole.ENSEIGNANT})
    public ResponseEntity<List<StudentDto>> getStudents(
            @RequestParam(required = false) String className,
            @RequestParam(required = false) String query) {
        return ResponseEntity.ok(scolariteService.getStudents(className, query));
    }

    @GetMapping("/parents/{parentUserId}/students")
    public ResponseEntity<List<StudentDto>> getStudentsForParent(@PathVariable Long parentUserId) {
        securityContextService.requireUserOrStaff(parentUserId);
        return ResponseEntity.ok(scolariteService.getStudentsForParent(parentUserId));
    }

    @PostMapping("/students")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SECRETAIRE})
    public ResponseEntity<StudentDto> createStudent(@Valid @RequestBody StudentDto dto) {
        return ResponseEntity.ok(scolariteService.createStudent(dto));
    }

    @PostMapping("/students/{id}/validate")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR})
    public ResponseEntity<StudentDto> validateStudent(
            @PathVariable Long id,
            @RequestParam Long classroomId) {
        return ResponseEntity.ok(scolariteService.validateStudent(
                id,
                classroomId,
                securityContextService.getCurrentUserId()
        ));
    }

    @DeleteMapping("/students/{id}")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SECRETAIRE})
    public ResponseEntity<Void> deleteStudent(@PathVariable Long id) {
        scolariteService.deleteStudent(id);
        return ResponseEntity.noContent().build();
    }

    // --- CLASSES ---
    @GetMapping({"/classrooms", "/classes"})
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SECRETAIRE, UserRole.ENSEIGNANT})
    public ResponseEntity<List<ClassroomDto>> getClassrooms() {
        return ResponseEntity.ok(scolariteService.getClassrooms());
    }

    @PostMapping({"/classrooms", "/classes"})
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SECRETAIRE})
    public ResponseEntity<ClassroomDto> createClassroom(@Valid @RequestBody ClassroomDto dto) {
        return ResponseEntity.ok(scolariteService.createClassroom(dto));
    }

    @PutMapping("/classrooms/{id}/promotion")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.SECRETAIRE})
    public ResponseEntity<ClassroomDto> savePromotionSettings(
            @PathVariable Long id,
            @RequestBody ClassroomDto dto) {
        return ResponseEntity.ok(scolariteService.savePromotionSettings(id, dto));
    }

    @DeleteMapping({"/classrooms/{id}", "/classes/{id}"})
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SECRETAIRE})
    public ResponseEntity<Void> deleteClassroom(@PathVariable Long id) {
        scolariteService.deleteClassroom(id);
        return ResponseEntity.noContent().build();
    }
}
