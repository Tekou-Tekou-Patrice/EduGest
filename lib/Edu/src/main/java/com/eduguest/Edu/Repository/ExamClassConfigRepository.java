package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.ExamClassConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface ExamClassConfigRepository extends JpaRepository<ExamClassConfig, Long> {
    Optional<ExamClassConfig> findByClassroomId(Long classroomId);
}
