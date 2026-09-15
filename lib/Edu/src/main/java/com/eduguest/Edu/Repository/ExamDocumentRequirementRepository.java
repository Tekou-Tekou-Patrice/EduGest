package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.ExamDocumentRequirement;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ExamDocumentRequirementRepository extends JpaRepository<ExamDocumentRequirement, Long> {
    List<ExamDocumentRequirement> findByConfigIdOrderByIdAsc(Long configId);
}
