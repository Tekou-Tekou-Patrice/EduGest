package com.eduguest.Edu.DTO;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AuditLogDto {
    private Long id;
    private String action;
    private String entityType;
    private String entityId;
    private String description;
    private String oldValue;
    private String newValue;
    private String performedBy;
    private String performedByRole;
    private Long performedById;
    private LocalDateTime timestamp;
}
