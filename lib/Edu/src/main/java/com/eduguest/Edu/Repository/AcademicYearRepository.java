package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.AcademicYear;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AcademicYearRepository extends JpaRepository<AcademicYear, Long> {
    Optional<AcademicYear> findByActiveTrue();
    Optional<AcademicYear> findByLabel(String label);
    List<AcademicYear> findByActiveFalseOrderByEndDateDesc();
    List<AcademicYear> findAllByOrderByStartDateDesc();
}
