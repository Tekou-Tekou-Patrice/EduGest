package com.eduguest.Edu.DTO;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class PaymentDto {
    private Long id;
    private String studentId;
    private String studentName;
    private Double amount;
    private LocalDateTime date;
    private String description;
    private Long recordedById;
    private String recordedByName;
    private Double totalTuition;
    private Double totalPaid;
    private Double remaining;
    private boolean tuitionCompleted;
}
