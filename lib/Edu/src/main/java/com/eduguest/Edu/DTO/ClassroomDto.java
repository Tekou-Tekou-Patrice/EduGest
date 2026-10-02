package com.eduguest.Edu.DTO;

import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Data
public class ClassroomDto {
    private Long id;
    private String name;
    private String level;
    private Integer capacity;
    private String description;
    private Double tuitionFee;
    private Boolean examClass;
    private Double promotionThreshold;
    private Long promotionTargetClassId;
    private Long teacherId;
    private String teacherName;
    private List<Long> teacherIds = new ArrayList<>();
    private List<String> teacherNames = new ArrayList<>();
    private Integer studentCount;
}
