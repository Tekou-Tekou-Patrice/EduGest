package com.eduguest.Edu.DTO;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

@Data
public class ScheduleItemDto {
    private Long id;
    private String day;
    private String startTime;
    private String endTime;
    private String subject;
    private String className;
    private String teacherName;
    private String room;

    @JsonProperty("isBreak")
    private boolean isBreak;
}
