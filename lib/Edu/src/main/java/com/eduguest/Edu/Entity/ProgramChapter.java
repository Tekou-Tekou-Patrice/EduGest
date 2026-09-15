package com.eduguest.Edu.Entity;

import com.eduguest.Edu.Config.CompressedStringConverter;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "program_chapters")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProgramChapter implements SchoolScoped {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "school_id")
    private School school;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "major_chapter", nullable = false, columnDefinition = "TEXT")
    @Convert(converter = CompressedStringConverter.class)
    private String majorChapter;

    @Column(name = "sub_chapter", columnDefinition = "TEXT")
    @Convert(converter = CompressedStringConverter.class)
    private String subChapter;

    @Column(name = "class_name", nullable = false)
    private String className;

    @Column(nullable = false)
    private String subject;

    @Column(name = "teacher_id", nullable = false)
    private String teacherId;

    @Column(name = "teacher_name")
    private String teacherName;

    @Column(nullable = false)
    private boolean completed = false;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "academic_year_id")
    private Long academicYearId;
}
