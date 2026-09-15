package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.StudentExamDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface StudentExamDocumentRepository extends JpaRepository<StudentExamDocument, Long> {
    List<StudentExamDocument> findByRecordId(Long recordId);
    Optional<StudentExamDocument> findByRecordIdAndRequirementId(Long recordId, Long requirementId);
}
