package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.StudentExamRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface StudentExamRecordRepository extends JpaRepository<StudentExamRecord, Long> {
    List<StudentExamRecord> findByConfigId(Long configId);
    Optional<StudentExamRecord> findByConfigIdAndStudentId(Long configId, Long studentId);
}
