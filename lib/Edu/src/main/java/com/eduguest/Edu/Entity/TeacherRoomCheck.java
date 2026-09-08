package com.eduguest.Edu.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "teacher_room_checks")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TeacherRoomCheck implements SchoolScoped {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "school_id")
    private School school;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "schedule_item_id", nullable = false)
    private Long scheduleItemId;

    @Column(nullable = false)
    private LocalDate checkDate;

    @Column(nullable = false)
    private boolean present;

    @Column(name = "teacher_name", nullable = false)
    private String teacherName;

    @Column(name = "teacher_id")
    private String teacherId;

    @Column(name = "class_name", nullable = false)
    private String className;

    @Column(nullable = false)
    private String subject;

    private String room;

    @Column(name = "verifier_id", nullable = false)
    private String verifierId;

    @Column(name = "verifier_name", nullable = false)
    private String verifierName;

    @Column(columnDefinition = "TEXT")
    private String justification;

    @Column(name = "justification_submitted_at")
    private LocalDateTime justificationSubmittedAt;

    @Column(name = "justification_deadline")
    private LocalDateTime justificationDeadline;

    @Column(name = "checked_at", nullable = false)
    private LocalDateTime checkedAt;

    @Column(name = "academic_year_id")
    private Long academicYearId;
}
