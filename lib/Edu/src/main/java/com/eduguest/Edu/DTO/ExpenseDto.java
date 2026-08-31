package com.eduguest.Edu.DTO;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class ExpenseDto {
    private Long id;
    private String title;
    private String category;
    private Double amount;
    private LocalDateTime date;
    private String description;
    private Long recordedById;
    private String recordedByName;
}
