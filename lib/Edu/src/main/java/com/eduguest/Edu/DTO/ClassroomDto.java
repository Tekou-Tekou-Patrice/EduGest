package com.eduguest.Edu.DTO;

import lombok.Data;

@Data
public class ClassroomDto {
    private Long id;
    private String name;
    private String level;
    private Integer capacity;
    private String description;
    private Double tuitionFee;
    private Long teacherId;
    private String teacherName;
    private Integer studentCount;
}
