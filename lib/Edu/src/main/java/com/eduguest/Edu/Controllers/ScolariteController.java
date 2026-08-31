package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.ClassroomDto;
import com.eduguest.Edu.DTO.StudentDto;
import com.eduguest.Edu.DTO.TeacherDto;
import com.eduguest.Edu.Service.ScolariteService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/scolarite")
public class ScolariteController {

    private final ScolariteService scolariteService;

    public ScolariteController(ScolariteService scolariteService) {
        this.scolariteService = scolariteService;
    }

    // --- ENSEIGNANTS ---
    @GetMapping("/teachers")
    public ResponseEntity<List<TeacherDto>> getTeachers(@RequestParam(required = false) String query) {
        return ResponseEntity.ok(scolariteService.getTeachers(query));
    }

    @PostMapping("/teachers")
    public ResponseEntity<TeacherDto> createTeacher(@Valid @RequestBody TeacherDto dto) {
        return ResponseEntity.ok(scolariteService.createTeacher(dto));
    }

    @DeleteMapping("/teachers/{id}")
    public ResponseEntity<Void> deleteTeacher(@PathVariable Long id) {
        scolariteService.deleteTeacher(id);
        return ResponseEntity.noContent().build();
    }

    // --- ÉLÈVES ---
    @GetMapping("/students")
    public ResponseEntity<List<StudentDto>> getStudents(
            @RequestParam(required = false) String className,
            @RequestParam(required = false) String query) {
        return ResponseEntity.ok(scolariteService.getStudents(className, query));
    }

    @GetMapping("/parents/{parentUserId}/students")
    public ResponseEntity<List<StudentDto>> getStudentsForParent(@PathVariable Long parentUserId) {
        return ResponseEntity.ok(scolariteService.getStudentsForParent(parentUserId));
    }

    @PostMapping("/students")
    public ResponseEntity<StudentDto> createStudent(@Valid @RequestBody StudentDto dto) {
        return ResponseEntity.ok(scolariteService.createStudent(dto));
    }

    @DeleteMapping("/students/{id}")
    public ResponseEntity<Void> deleteStudent(@PathVariable Long id) {
        scolariteService.deleteStudent(id);
        return ResponseEntity.noContent().build();
    }

    // --- CLASSES ---
    @GetMapping("/classrooms")
    public ResponseEntity<List<ClassroomDto>> getClassrooms() {
        return ResponseEntity.ok(scolariteService.getClassrooms());
    }

    @PostMapping("/classrooms")
    public ResponseEntity<ClassroomDto> createClassroom(@Valid @RequestBody ClassroomDto dto) {
        return ResponseEntity.ok(scolariteService.createClassroom(dto));
    }

    @DeleteMapping("/classrooms/{id}")
    public ResponseEntity<Void> deleteClassroom(@PathVariable Long id) {
        scolariteService.deleteClassroom(id);
        return ResponseEntity.noContent().build();
    }
}
