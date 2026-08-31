package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.Lesson;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface LessonRepository extends JpaRepository<Lesson, Long> {
    
    @Query("SELECT l FROM Lesson l WHERE l.className = :className ORDER BY l.date DESC")
    List<Lesson> findByClassName(@Param("className") String className);
    
    @Query("SELECT l FROM Lesson l WHERE l.teacherId = :teacherId ORDER BY l.date DESC")
    List<Lesson> findByTeacherId(@Param("teacherId") String teacherId);

    @Query(value = "SELECT * FROM lessons WHERE date >= DATE_SUB(NOW(), INTERVAL 7 DAY)", nativeQuery = true)
    List<Lesson> findLessonsFromLastWeek();
}
