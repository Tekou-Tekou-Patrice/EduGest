package com.eduguest.Edu.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "schedule_items")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ScheduleItem implements SchoolScoped {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "school_id")
    private School school;
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String day; // Lundi, Mardi...

    @Column(name = "start_time", nullable = false)
    private String startTime;

    @Column(name = "end_time", nullable = false)
    private String endTime;

    @Column(nullable = false)
    private String subject;

    @Column(name = "class_name", nullable = false)
    private String className;

    @Column(name = "teacher_name")
    private String teacherName;

    private String room;

    @Column(name = "is_break")
    private boolean isBreak = false;

    @Column(name = "academic_year_id")
    private Long academicYearId;
}
