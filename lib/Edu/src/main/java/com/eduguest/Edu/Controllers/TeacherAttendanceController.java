package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.Config.RequireRoles;
import com.eduguest.Edu.DTO.TeacherAttendanceDto;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Service.TeacherAttendanceService;
import com.eduguest.Edu.Service.UserSecurityContextService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/scolarite/teacher-attendance")
public class TeacherAttendanceController {
    private final TeacherAttendanceService service;
    private final UserSecurityContextService securityContextService;

    public TeacherAttendanceController(TeacherAttendanceService service,
                                       UserSecurityContextService securityContextService) {
        this.service = service;
        this.securityContextService = securityContextService;
    }

    @GetMapping
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.SECRETAIRE})
    public ResponseEntity<List<TeacherAttendanceDto>> get(
            @RequestParam(required = false) LocalDate date) {
        return ResponseEntity.ok(service.getForDate(date == null ? LocalDate.now() : date));
    }

    @PostMapping
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.SECRETAIRE})
    public ResponseEntity<TeacherAttendanceDto> save(@RequestBody TeacherAttendanceDto dto) {
        return ResponseEntity.ok(service.save(
                dto.getTeacherId(),
                dto.getAttendanceDate() == null ? LocalDate.now() : dto.getAttendanceDate(),
                dto.getStatus(),
                securityContextService.getCurrentUserId()
        ));
    }
}
