package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.Subject;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SubjectRepository extends JpaRepository<Subject, Long> {
    
    @Query("SELECT s FROM Subject s WHERE s.name = :name")
    Optional<Subject> findByName(@Param("name") String name);

    @Query(value = "SELECT * FROM subjects ORDER BY coefficient DESC", nativeQuery = true)
    List<Subject> findAllOrderByCoefficientDesc();
}
