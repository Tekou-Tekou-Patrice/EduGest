package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.Student;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StudentRepository extends JpaRepository<Student, Long> {
    
    @Query("SELECT s FROM Student s WHERE s.className = :className")
    List<Student> findByClassName(@Param("className") String className);
    
    @Query("""
        SELECT s FROM Student s WHERE
        LOWER(s.firstName) LIKE LOWER(concat('%', :query, '%'))
        OR LOWER(s.lastName) LIKE LOWER(concat('%', :query, '%'))
        OR LOWER(concat(s.firstName, ' ', s.lastName)) LIKE LOWER(concat('%', :query, '%'))
        OR LOWER(concat(s.lastName, ' ', s.firstName)) LIKE LOWER(concat('%', :query, '%'))
        """)
    List<Student> searchStudents(@Param("query") String query);
    
    @Query("SELECT COUNT(s) FROM Student s WHERE s.className = :className")
    long countByClassName(@Param("className") String className);

    @Query(value = "SELECT * FROM students ORDER BY last_name ASC", nativeQuery = true)
    List<Student> findAllSortedByName();

    @Query("SELECT s FROM Student s WHERE (:phone <> '' AND s.parentPhone = :phone) OR (:email <> '' AND LOWER(s.parentEmail) = LOWER(:email))")
    List<Student> findByParentContact(@Param("phone") String phone, @Param("email") String email);
}
