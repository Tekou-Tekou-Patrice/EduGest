package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.Exam;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ExamRepository extends JpaRepository<Exam, Long> {
    
    @Query("SELECT e FROM Exam e WHERE e.className = :className")
    List<Exam> findByClassName(@Param("className") String className);
    
    @Query("SELECT e FROM Exam e WHERE e.subject = :subject")
    List<Exam> findBySubject(@Param("subject") String subject);

    Optional<Exam> findFirstByTitleAndClassNameAndSubject(String title, String className, String subject);

    @Query(value = "SELECT * FROM exams WHERE date >= NOW() ORDER BY date ASC", nativeQuery = true)
    List<Exam> findUpcomingExams();
}
