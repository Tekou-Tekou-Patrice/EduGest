package com.eduguest.Edu.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "students")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Student implements SchoolScoped {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "school_id")
    private School school;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "first_name", nullable = false, length = 80)
    private String firstName;

    @Column(name = "last_name", nullable = false, length = 80)
    private String lastName;

    @Column(name = "class_name", length = 60)
    private String className;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(name = "parent_name", length = 120)
    private String parentName;

    @Column(name = "parent_phone", length = 20)
    private String parentPhone;

    @Column(name = "parent_email", length = 150)
    private String parentEmail;

    @Column(name = "photo_url")
    private String photoUrl;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "classroom_id")
    private Classroom classroom;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "registered_by_id")
    private User registeredBy;

    @Column(name = "registration_date")
    private LocalDateTime registrationDate;

    @Column(name = "registration_status", nullable = false, length = 20)
    private String registrationStatus = "VALIDATED";

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "validated_by_id")
    private User validatedBy;

    @Column(name = "validated_at")
    private LocalDateTime validatedAt;

    @Column(name = "last_annual_deliberation_year_id")
    private Long lastAnnualDeliberationYearId;

    @Column(name = "last_annual_deliberation_class_id")
    private Long lastAnnualDeliberationClassId;

    @Column(name = "annual_promotion_from_class_id")
    private Long annualPromotionFromClassId;

    @Column(name = "annual_promotion_to_class_id")
    private Long annualPromotionToClassId;

    @PrePersist
    protected void onCreate() {
        registrationDate = LocalDateTime.now();
    }
}
