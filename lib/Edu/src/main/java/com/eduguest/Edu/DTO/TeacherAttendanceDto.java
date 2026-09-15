package com.eduguest.Edu.DTO;

import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
public class TeacherAttendanceDto {
    private Long id;
    private Long teacherId;
    private String teacherName;
    private LocalDate attendanceDate;
    private String status;
    private Long recordedById;
    private String recordedByName;
    private LocalDateTime recordedAt;
}
