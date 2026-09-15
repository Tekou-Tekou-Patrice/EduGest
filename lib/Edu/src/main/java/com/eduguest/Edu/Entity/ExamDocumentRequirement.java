package com.eduguest.Edu.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "exam_document_requirements",
        uniqueConstraints = @UniqueConstraint(name = "uk_exam_document_config_name", columnNames = {"config_id", "name"}))
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ExamDocumentRequirement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "config_id", nullable = false)
    private ExamClassConfig config;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(nullable = false)
    private boolean required = true;
}
