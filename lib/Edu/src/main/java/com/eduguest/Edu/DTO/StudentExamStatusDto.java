package com.eduguest.Edu.DTO;

import lombok.Data;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Data
public class StudentExamStatusDto {
    private Long studentId;
    private String studentName;
    private BigDecimal officialFee;
    private BigDecimal paidAmount;
    private boolean feesComplete;
    private boolean dossierComplete;
    private List<StudentExamDocumentDto> documents = new ArrayList<>();
}
