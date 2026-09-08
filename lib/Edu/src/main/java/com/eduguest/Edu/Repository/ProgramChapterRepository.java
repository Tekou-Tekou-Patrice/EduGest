package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.ProgramChapter;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProgramChapterRepository extends JpaRepository<ProgramChapter, Long> {

    @Query("SELECT p FROM ProgramChapter p WHERE p.teacherId = :teacherId ORDER BY p.completed ASC, p.createdAt DESC")
    List<ProgramChapter> findByTeacherId(@Param("teacherId") String teacherId);

    @Query("SELECT p FROM ProgramChapter p WHERE p.className = :className AND p.completed = true ORDER BY p.completedAt DESC")
    List<ProgramChapter> findCompletedByClassName(@Param("className") String className);
}
