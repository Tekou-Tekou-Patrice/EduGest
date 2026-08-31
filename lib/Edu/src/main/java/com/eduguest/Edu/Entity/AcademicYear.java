package com.eduguest.Edu.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "academic_years")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AcademicYear implements SchoolScoped {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "school_id")
    private School school;
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String label;

    @Column(name = "start_date")
    private LocalDate startDate;

    /** Date à laquelle l'année est sauvegardée / clôturée. */
    @Column(name = "end_date")
    private LocalDate endDate;

    @Column(name = "is_active")
    private boolean active = false;

    private Double totalRevenue;
    private Double totalExpenses;
    private Integer studentCount;
    private Integer teacherCount;
    private Integer absenceCount;
    private Integer sanctionCount;
    private Integer examCount;
    private Integer lessonCount;

    @Column(name = "school_name")
    private String schoolName;

    @Column(name = "closed_at")
    private LocalDateTime closedAt;
}
