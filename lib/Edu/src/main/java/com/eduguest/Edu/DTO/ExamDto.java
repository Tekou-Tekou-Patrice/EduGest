package com.eduguest.Edu.DTO;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class ExamDto {
    private Long id;
    private String title;
    private String subject;
    private String className;
    private LocalDateTime date;
    private Double coefficient;
    private LocalDateTime submittedAt;
    private boolean editable;
}
