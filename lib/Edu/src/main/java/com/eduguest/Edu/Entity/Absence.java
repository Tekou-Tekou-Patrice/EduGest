package com.eduguest.Edu.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "absences")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Absence implements SchoolScoped {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "school_id")
    private School school;
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "student_id", nullable = false)
    private String studentId;

    @Column(name = "student_name", nullable = false)
    private String studentName;

    @Column(name = "class_name", nullable = false)
    private String className;

    @Column(nullable = false)
    private LocalDateTime date;

    @Column(nullable = false)
    private String period; // Matin, Après-midi, Journée, etc.

    @Column(columnDefinition = "TEXT")
    private String reason;

    @Column(name = "is_justified", nullable = false)
    private boolean justified;

    @Column(name = "academic_year_id")
    private Long academicYearId;
}
