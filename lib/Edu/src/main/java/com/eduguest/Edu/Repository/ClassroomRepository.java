package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.Classroom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ClassroomRepository extends JpaRepository<Classroom, Long> {
    
    @Query("SELECT c FROM Classroom c WHERE c.name = :name")
    Optional<Classroom> findByName(@Param("name") String name);

    @Query(value = "SELECT c.*, (SELECT COUNT(*) FROM students s WHERE s.classroom_id = c.id) as student_count FROM classrooms c", nativeQuery = true)
    List<Object[]> findAllWithStudentCount();
}
