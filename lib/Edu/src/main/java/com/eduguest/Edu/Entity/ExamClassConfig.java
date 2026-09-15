package com.eduguest.Edu.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Entity
@Table(name = "exam_class_configs",
        uniqueConstraints = @UniqueConstraint(name = "uk_exam_config_school_class", columnNames = {"school_id", "classroom_id"}))
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ExamClassConfig implements SchoolScoped {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "school_id", nullable = false)
    private School school;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "classroom_id", nullable = false)
    private Classroom classroom;

    @Column(name = "exam_name", nullable = false, length = 120)
    private String examName;

    @Column(name = "official_fee", nullable = false, precision = 12, scale = 2)
    private BigDecimal officialFee = BigDecimal.ZERO;
}
