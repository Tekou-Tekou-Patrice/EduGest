package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.Sanction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SanctionRepository extends JpaRepository<Sanction, Long> {
    List<Sanction> findByStudentId(String studentId);
}
