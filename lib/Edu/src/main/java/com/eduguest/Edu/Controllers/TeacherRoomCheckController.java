package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.TeacherRoomCheckDto;
import com.eduguest.Edu.Service.TeacherRoomCheckService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/academique/teacher-room-checks")
public class TeacherRoomCheckController {
    private final TeacherRoomCheckService service;

    public TeacherRoomCheckController(TeacherRoomCheckService service) {
        this.service = service;
    }

    @GetMapping
    public ResponseEntity<List<TeacherRoomCheckDto>> getChecks(
            @RequestParam(required = false) LocalDate date,
            @RequestParam(required = false) String teacherId) {
        if (teacherId != null && !teacherId.isBlank()) {
            return ResponseEntity.ok(service.getTeacherAbsences(teacherId));
        }
        return ResponseEntity.ok(service.getChecks(date == null ? LocalDate.now() : date));
    }

    @PostMapping
    public ResponseEntity<TeacherRoomCheckDto> saveCheck(
            @Valid @RequestBody TeacherRoomCheckDto dto) {
        return ResponseEntity.ok(service.saveCheck(dto));
    }

    @PutMapping("/{id}/justification")
    public ResponseEntity<TeacherRoomCheckDto> justify(
            @PathVariable Long id,
            @RequestParam String teacherId,
            @RequestBody TeacherRoomCheckDto dto) {
        return ResponseEntity.ok(service.justify(id, teacherId, dto.getJustification()));
    }
}
