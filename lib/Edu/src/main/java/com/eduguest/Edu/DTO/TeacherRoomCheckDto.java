package com.eduguest.Edu.DTO;

import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
public class TeacherRoomCheckDto {
    private Long id;
    private Long scheduleItemId;
    private LocalDate checkDate;
    private boolean present;
    private String teacherName;
    private String teacherId;
    private String className;
    private String subject;
    private String room;
    private String verifierId;
    private String verifierName;
    private String justification;
    private LocalDateTime justificationSubmittedAt;
    private LocalDateTime justificationDeadline;
    private LocalDateTime checkedAt;
}
