package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.ExamDto;
import com.eduguest.Edu.DTO.GradeDto;
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
    public ResponseEntity<List<ExamDto>> getAllExams(@RequestParam(required = false) String className) {
        try {
            if (className != null && !className.isBlank()) {
                return ResponseEntity.ok(examService.getExamsByClass(className));
            }
            return ResponseEntity.ok(examService.getAllExams());
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    @PostMapping("/exams")
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
    public ResponseEntity<GradeDto> updateGrade(@PathVariable Long id, @RequestBody GradeDto dto) {
        return ResponseEntity.ok(examService.updateGrade(id, dto));
    }
}
