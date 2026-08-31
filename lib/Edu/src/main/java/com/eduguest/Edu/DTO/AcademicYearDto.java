package com.eduguest.Edu.DTO;

import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
public class AcademicYearDto {
    private Long id;
    private String label;
    private LocalDate startDate;
    private LocalDate endDate;
    private boolean active;
    private String status;
    private Double totalRevenue;
    private Double totalExpenses;
    private Double balance;
    private Integer studentCount;
    private Integer teacherCount;
    private Integer absenceCount;
    private Integer sanctionCount;
    private Integer examCount;
    private Integer lessonCount;
    private String schoolName;
    private LocalDateTime closedAt;
}
