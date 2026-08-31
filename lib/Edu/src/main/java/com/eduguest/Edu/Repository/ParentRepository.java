package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.Parent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ParentRepository extends JpaRepository<Parent, Long> {
    
    @Query("SELECT p FROM Parent p WHERE p.phone = :phone")
    Optional<Parent> findByPhone(@Param("phone") String phone);

    @Query(value = "SELECT p.* FROM parents p JOIN parent_students ps ON p.id = ps.parent_id WHERE ps.student_id = :studentId", nativeQuery = true)
    Optional<Parent> findByStudentId(@Param("studentId") String studentId);
}
