package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.Config.RequireRoles;
import com.eduguest.Edu.DTO.StaffAttendanceQrDto;
import com.eduguest.Edu.DTO.StaffAttendanceReportDto;
import com.eduguest.Edu.DTO.StaffAttendanceScanDto;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Service.StaffAttendanceService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.YearMonth;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/staff-attendance")
public class StaffAttendanceController {
    private final StaffAttendanceService service;

    public StaffAttendanceController(StaffAttendanceService service) {
        this.service = service;
    }

    @GetMapping("/qr/today")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.SECRETAIRE, UserRole.SURVEILLANT_GENERAL})
    public ResponseEntity<StaffAttendanceQrDto> getTodayQr() {
        return ResponseEntity.ok(service.getTodayQr());
    }

    @PostMapping("/scan")
    @RequireRoles({UserRole.ENSEIGNANT, UserRole.SURVEILLANT, UserRole.SURVEILLANT_GENERAL, UserRole.CENSEUR})
    public ResponseEntity<StaffAttendanceScanDto> scan(@RequestBody Map<String, String> body) {
        return ResponseEntity.ok(service.scan(body.get("token")));
    }

    @GetMapping("/report")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.SECRETAIRE, UserRole.SURVEILLANT_GENERAL, UserRole.CENSEUR})
    public ResponseEntity<List<StaffAttendanceReportDto>> getMonthlyReport(@RequestParam String month) {
        return ResponseEntity.ok(service.getMonthlyReport(YearMonth.parse(month)));
    }
}
