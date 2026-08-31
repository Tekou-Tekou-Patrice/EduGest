package com.eduguest.Edu.DTO;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class LessonDto {
    private Long id;
    private String title;
    private String content;
    private String className;
    private String subject;
    private LocalDateTime date;
    private String teacherId;
}
