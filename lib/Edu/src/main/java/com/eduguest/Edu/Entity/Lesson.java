package com.eduguest.Edu.Entity;

import com.eduguest.Edu.Config.CompressedStringConverter;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "lessons")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Lesson implements SchoolScoped {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "school_id")
    private School school;
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    @Convert(converter = CompressedStringConverter.class)
    private String content;

    @Column(name = "class_name", nullable = false)
    private String className;

    @Column(nullable = false)
    private String subject;

    @Column(nullable = false)
    private LocalDateTime date;

    @Column(name = "teacher_id")
    private String teacherId;

    @Column(name = "teacher_name")
    private String teacherName;

    @Column(name = "academic_year_id")
    private Long academicYearId;
}
