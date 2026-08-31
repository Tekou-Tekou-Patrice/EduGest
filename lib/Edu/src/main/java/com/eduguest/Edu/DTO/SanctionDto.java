package com.eduguest.Edu.DTO;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class SanctionDto {
    private Long id;
    private String studentId;
    private String studentName;
    private String type;
    private String reason;
    private LocalDateTime date;
}
