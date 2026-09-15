package com.eduguest.Edu.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "student_exam_documents",
        uniqueConstraints = @UniqueConstraint(name = "uk_student_exam_document", columnNames = {"record_id", "requirement_id"}))
@Data
@NoArgsConstructor
@AllArgsConstructor
public class StudentExamDocument {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "record_id", nullable = false)
    private StudentExamRecord record;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "requirement_id", nullable = false)
    private ExamDocumentRequirement requirement;

    @Column(nullable = false)
    private boolean submitted = false;
}
