package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.Absence;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AbsenceRepository extends JpaRepository<Absence, Long> {
    
    @Query("SELECT a FROM Absence a WHERE a.studentId = :studentId")
    List<Absence> findByStudentId(@Param("studentId") String studentId);

    @Query("SELECT a FROM Absence a WHERE a.className = :className")
    List<Absence> findByClassName(@Param("className") String className);

    @Query(value = "SELECT * FROM absences WHERE is_justified = false", nativeQuery = true)
    List<Absence> findAllUnjustified();
}
