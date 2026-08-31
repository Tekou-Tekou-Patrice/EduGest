package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.Grade;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface GradeRepository extends JpaRepository<Grade, Long> {
    
    @Query("SELECT g FROM Grade g WHERE g.studentId = :studentId")
    List<Grade> findByStudentId(@Param("studentId") String studentId);
    
    @Query("SELECT g FROM Grade g WHERE g.examId = :examId")
    List<Grade> findByExamId(@Param("examId") String examId);

    @Query(value = "SELECT AVG(score) FROM grades WHERE exam_id = :examId", nativeQuery = true)
    Double getAverageByExam(@Param("examId") String examId);
}
