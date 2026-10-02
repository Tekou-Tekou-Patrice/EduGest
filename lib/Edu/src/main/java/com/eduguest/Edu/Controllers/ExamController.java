package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.Config.RequireRoles;
import com.eduguest.Edu.DTO.ExamDto;
import com.eduguest.Edu.DTO.GradeDto;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Service.ExamService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/academique")
public class ExamController {

    private final ExamService examService;

    public ExamController(ExamService examService) {
        this.examService = examService;
    }

    @GetMapping("/exams")
    public ResponseEntity<List<ExamDto>> getAllExams(
            @RequestParam(required = false) String className,
            @RequestParam(required = false) String teacherName) {
        try {
            if (className != null && !className.isBlank()) {
                return ResponseEntity.ok(examService.getExamsByClass(className));
            }
            if (teacherName != null && !teacherName.isBlank()) {
                return ResponseEntity.ok(examService.getExamsByTeacher(teacherName));
            }
            return ResponseEntity.ok(examService.getAllExams());
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    @PostMapping("/exams")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.ENSEIGNANT})
    public ResponseEntity<ExamDto> createExam(@Valid @RequestBody ExamDto dto) {
        return ResponseEntity.ok(examService.createExam(dto));
    }

    @GetMapping("/exams/{id}/grades")
    public ResponseEntity<List<GradeDto>> getGradesByExam(@PathVariable String id) {
        try {
            return ResponseEntity.ok(examService.getGradesByExam(id));
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    @PostMapping("/grades")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.ENSEIGNANT})
    public ResponseEntity<?> saveGrades(@RequestBody Map<String, Object> payload) {
        // Batch Flutter: { classe, sequence, grades: {id: score} }
        if (payload.containsKey("grades") || payload.containsKey("items")) {
            return ResponseEntity.ok(examService.saveGradesBatch(payload));
        }

        // Note unique: { studentId, examId, score, observations }
        GradeDto dto = new GradeDto();
        if (payload.get("studentId") != null) dto.setStudentId(payload.get("studentId").toString());
        if (payload.get("examId") != null) dto.setExamId(payload.get("examId").toString());
        if (payload.get("score") != null) dto.setScore(Double.parseDouble(payload.get("score").toString()));
        if (payload.get("observations") != null) dto.setObservations(payload.get("observations").toString());
        return ResponseEntity.ok(examService.saveGrade(dto));
    }

    @PutMapping("/grades/{id}")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.SECRETAIRE, UserRole.ENSEIGNANT})
    public ResponseEntity<GradeDto> updateGrade(@PathVariable Long id, @RequestBody GradeDto dto) {
        return ResponseEntity.ok(examService.updateGrade(id, dto));
    }

    @PutMapping("/grades/batch")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.SECRETAIRE, UserRole.ENSEIGNANT})
    public ResponseEntity<List<GradeDto>> updateGrades(@RequestBody List<GradeDto> grades) {
        return ResponseEntity.ok(examService.updateGrades(grades));
    }

    @DeleteMapping("/grades/{id}")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.ENSEIGNANT})
    public ResponseEntity<Void> deleteGrade(@PathVariable Long id) {
        examService.deleteGrade(id);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/exams/{id}")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.ENSEIGNANT})
    public ResponseEntity<Void> deleteExam(@PathVariable Long id) {
        examService.deleteExam(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/pending-submissions")
    public ResponseEntity<List<Map<String, Object>>> getPendingSubmissions(
            @RequestParam(required = false) String period) {
        return ResponseEntity.ok(examService.getPendingSubjectSubmissions(period));
    }
}
