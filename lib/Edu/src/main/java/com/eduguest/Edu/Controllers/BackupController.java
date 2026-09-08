package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.Config.RequireRoles;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Service.BackupService;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.Map;

@RestController
@RequestMapping("/api/backup")
@RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR})
public class BackupController {

    private final BackupService backupService;

    public BackupController(BackupService backupService) {
        this.backupService = backupService;
    }

    @GetMapping("/export")
    public ResponseEntity<Map<String, Object>> exportBackup(
            @RequestParam(required = false) Long schoolId) {
        Map<String, Object> data = backupService.exportSchoolData(schoolId);
        String filename = "edugest_sauvegarde_" + LocalDate.now() + ".json";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.APPLICATION_JSON)
                .body(data);
    }

    @PostMapping("/import")
    public ResponseEntity<Map<String, Object>> importBackup(
            @RequestParam(required = false) Long schoolId,
            @RequestBody Map<String, Object> payload) {
        return ResponseEntity.ok(backupService.importSchoolData(schoolId, payload));
    }

    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getStatus() {
        return ResponseEntity.ok(backupService.getBackupStatus());
    }

    @PostMapping("/trigger-auto")
    public ResponseEntity<Map<String, Object>> triggerAuto() {
        backupService.triggerAutoBackup();
        return ResponseEntity.ok(backupService.getBackupStatus());
    }
}
