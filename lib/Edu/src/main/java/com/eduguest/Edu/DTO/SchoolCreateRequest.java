package com.eduguest.Edu.DTO;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class SchoolCreateRequest {
    @NotBlank
    private String name;
    private String code;
    private Long userId;
}
