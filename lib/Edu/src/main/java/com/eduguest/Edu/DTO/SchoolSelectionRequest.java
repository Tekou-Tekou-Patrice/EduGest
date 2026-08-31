package com.eduguest.Edu.DTO;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class SchoolSelectionRequest {
    @NotNull
    private Long schoolId;
}
