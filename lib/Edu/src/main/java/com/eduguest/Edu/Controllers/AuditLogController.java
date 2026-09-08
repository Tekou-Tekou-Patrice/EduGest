package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.Config.RequireRoles;
import com.eduguest.Edu.DTO.AuditLogDto;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Service.AuditLogService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/audit-logs")
@RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SECRETAIRE})
public class AuditLogController {

    private final AuditLogService auditLogService;

    public AuditLogController(AuditLogService auditLogService) {
        this.auditLogService = auditLogService;
    }

    @GetMapping
    public ResponseEntity<List<AuditLogDto>> getAuditLogs(
            @RequestParam(required = false) String entityType,
            @RequestParam(required = false) String search) {
        return ResponseEntity.ok(auditLogService.getAuditLogs(entityType, search));
    }
}
