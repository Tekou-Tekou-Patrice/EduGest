package com.eduguest.Edu.DTO;

import lombok.Data;

@Data
public class GradeDto {
    private Long id;
    private String studentId;
    private String examId;
    private Double score;
    private String observations;
}
