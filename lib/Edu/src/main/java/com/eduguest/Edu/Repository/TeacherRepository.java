package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.Teacher;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TeacherRepository extends JpaRepository<Teacher, Long> {
    
    @Query("SELECT t FROM Teacher t WHERE t.speciality = :speciality")
    List<Teacher> findBySpeciality(@Param("speciality") String speciality);

    @Query("SELECT t FROM Teacher t WHERE LOWER(t.firstName) LIKE LOWER(concat('%', :query, '%')) OR LOWER(t.lastName) LIKE LOWER(concat('%', :query, '%'))")
    List<Teacher> searchTeachers(@Param("query") String query);

    @Query(value = "SELECT * FROM teachers ORDER BY speciality ASC, last_name ASC", nativeQuery = true)
    List<Teacher> findAllSortedBySpeciality();
}
