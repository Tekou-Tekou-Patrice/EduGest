package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.Config.RequireRoles;
import com.eduguest.Edu.DTO.ExamClassConfigDto;
import com.eduguest.Edu.DTO.StudentExamStatusDto;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Service.ExamClassService;
import com.eduguest.Edu.Service.UserSecurityContextService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/exam-classes")
@RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SECRETAIRE, UserRole.COMPTABLE})
public class ExamClassController {

    private final ExamClassService service;
    private final UserSecurityContextService securityContextService;

    public ExamClassController(ExamClassService service,
                               UserSecurityContextService securityContextService) {
        this.service = service;
        this.securityContextService = securityContextService;
    }

    @GetMapping("/{classroomId}/config")
    public ResponseEntity<ExamClassConfigDto> getConfig(@PathVariable Long classroomId) {
        return ResponseEntity.ok(service.getConfig(classroomId));
    }

    @PutMapping("/{classroomId}/config")
    public ResponseEntity<ExamClassConfigDto> saveConfig(@PathVariable Long classroomId,
                                                         @RequestBody ExamClassConfigDto dto) {
        return ResponseEntity.ok(service.saveConfig(classroomId, dto));
    }

    @GetMapping("/{classroomId}/students")
    public ResponseEntity<List<StudentExamStatusDto>> getStudents(@PathVariable Long classroomId) {
        return ResponseEntity.ok(service.getStudentStatuses(classroomId));
    }

    @PutMapping("/{classroomId}/students/{studentId}")
    public ResponseEntity<StudentExamStatusDto> updateStudent(@PathVariable Long classroomId,
                                                              @PathVariable Long studentId,
                                                              @RequestBody StudentExamStatusDto dto) {
        return ResponseEntity.ok(service.updateStudentStatus(classroomId, studentId, dto));
    }

    @GetMapping("/parent/students/{studentId}")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.PARENT})
    public ResponseEntity<StudentExamStatusDto> getParentStudentStatus(
            @PathVariable Long studentId) {
        Long parentUserId = securityContextService.getCurrentUserId();
        return ResponseEntity.ok(service.getParentStudentStatus(studentId, parentUserId));
    }
}
