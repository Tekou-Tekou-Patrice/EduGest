package com.eduguest.Edu.DTO;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class ProgramChapterDto {
    private Long id;
    private String majorChapter;
    private String subChapter;
    private String className;
    private String subject;
    private String teacherId;
    private String teacherName;
    private boolean completed;
    private LocalDateTime completedAt;
    private LocalDateTime createdAt;
}
