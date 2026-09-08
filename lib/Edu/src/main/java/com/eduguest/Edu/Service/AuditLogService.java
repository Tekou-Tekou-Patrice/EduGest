package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.AuditLogDto;
import com.eduguest.Edu.Entity.AuditLog;
import com.eduguest.Edu.Repository.AuditLogRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class AuditLogService {

    private final AuditLogRepository auditLogRepository;
    private final SchoolContextService schoolContextService;
    private final AcademicYearService academicYearService;
    private final UserSecurityContextService userSecurityContextService;

    public AuditLogService(AuditLogRepository auditLogRepository,
                           SchoolContextService schoolContextService,
                           AcademicYearService academicYearService,
                           UserSecurityContextService userSecurityContextService) {
        this.auditLogRepository = auditLogRepository;
        this.schoolContextService = schoolContextService;
        this.academicYearService = academicYearService;
        this.userSecurityContextService = userSecurityContextService;
    }

    @Transactional
    public AuditLog logAction(String action, String entityType, String entityId,
                             String description, String oldValue, String newValue) {
        return logAction(action, entityType, entityId, description, oldValue, newValue, null, null);
    }

    @Transactional
    public AuditLog logAction(String action, String entityType, String entityId,
                             String description, String oldValue, String newValue,
                             String performerName, String performerRole) {
        AuditLog log = new AuditLog();
        log.setAction(action != null ? action.toUpperCase() : "ACTION");
        log.setEntityType(entityType != null ? entityType.toUpperCase() : "GENERAL");
        log.setEntityId(entityId);
        log.setDescription(description);
        log.setOldValue(oldValue);
        log.setNewValue(newValue);

        String user = performerName != null && !performerName.isBlank()
                ? performerName
                : userSecurityContextService.getCurrentUserDisplayName();
        String role = performerRole != null && !performerRole.isBlank()
                ? performerRole
                : userSecurityContextService.getCurrentRoleName();
        Long userId = userSecurityContextService.getCurrentUserId();

        log.setPerformedBy(user);
        log.setPerformedByRole(role != null ? role : "Utilisateur");
        log.setPerformedById(userId);
        log.setTimestamp(LocalDateTime.now());

        try {
            log.setAcademicYearId(academicYearService.stampCurrentYear());
        } catch (Exception e) {
            try {
                log.setAcademicYearId(academicYearService.getOrAutoCreateActiveYear().getId());
            } catch (Exception ignored) {}
        }

        try {
            schoolContextService.verifyAndAssign(log);
        } catch (Exception ignored) {}

        return auditLogRepository.save(log);
    }

    @Transactional(readOnly = true)
    public List<AuditLogDto> getAuditLogs(String entityType, String query) {
        List<AuditLog> scoped = schoolContextService.scope(auditLogRepository.findAllByOrderByTimestampDesc());

        if (entityType != null && !entityType.isBlank() && !"TOUS".equalsIgnoreCase(entityType)) {
            scoped = scoped.stream()
                    .filter(l -> entityType.equalsIgnoreCase(l.getEntityType()))
                    .toList();
        }

        if (query != null && !query.isBlank()) {
            String q = query.trim().toLowerCase();
            scoped = scoped.stream()
                    .filter(l -> (l.getDescription() != null && l.getDescription().toLowerCase().contains(q))
                            || (l.getPerformedBy() != null && l.getPerformedBy().toLowerCase().contains(q))
                            || (l.getAction() != null && l.getAction().toLowerCase().contains(q))
                            || (l.getEntityId() != null && l.getEntityId().toLowerCase().contains(q)))
                    .toList();
        }

        return scoped.stream().map(this::toDto).collect(Collectors.toList());
    }

    private AuditLogDto toDto(AuditLog entity) {
        return new AuditLogDto(
                entity.getId(),
                entity.getAction(),
                entity.getEntityType(),
                entity.getEntityId(),
                entity.getDescription(),
                entity.getOldValue(),
                entity.getNewValue(),
                entity.getPerformedBy(),
                entity.getPerformedByRole(),
                entity.getPerformedById(),
                entity.getTimestamp()
        );
    }
}
