package com.eduguest.Edu.DTO;

import lombok.Data;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Data
public class ExamClassConfigDto {
    private Long classroomId;
    private String classroomName;
    private String examName;
    private BigDecimal officialFee;
    private List<ExamDocumentRequirementDto> documents = new ArrayList<>();
}
