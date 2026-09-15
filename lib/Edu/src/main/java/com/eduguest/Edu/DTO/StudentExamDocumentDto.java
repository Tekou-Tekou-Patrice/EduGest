package com.eduguest.Edu.DTO;

import lombok.Data;

@Data
public class StudentExamDocumentDto {
    private Long requirementId;
    private String name;
    private boolean required;
    private boolean submitted;
}
