package com.eduguest.Edu.DTO;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class AbsenceDto {
    private Long id;
    private String studentId;
    private String studentName;
    private String className;
    private LocalDateTime date;
    private String period;
    private String reason;

    @JsonProperty("isJustified")
    @JsonAlias({"justified", "is_justified"})
    private boolean justified;
}
