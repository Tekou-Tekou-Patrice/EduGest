package com.eduguest.Edu.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "bulletin_publications")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class BulletinPublication implements SchoolScoped {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "school_id")
    private School school;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "class_name", nullable = false)
    private String className;

    @Column(nullable = false)
    private String period;

    @Column(name = "student_id")
    private String studentId; // null signifie toute la classe

    @Column(name = "published_by", nullable = false)
    private String publishedBy;

    @Column(name = "published_by_role", nullable = false)
    private String publishedByRole;

    @Column(name = "language_code")
    private String languageCode = "fr";

    @Column(name = "published_at", nullable = false)
    private LocalDateTime publishedAt;

    private boolean published = true;

    @Column(name = "academic_year_id")
    private Long academicYearId;

    @Column(name = "promotion_threshold")
    private Double promotionThreshold;

    @Column(name = "promotion_target_class_name")
    private String promotionTargetClassName;

    @Column(name = "promotion_source_class_id")
    private Long promotionSourceClassId;
}
