package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.School;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SchoolRepository extends JpaRepository<School, Long> {
    Optional<School> findByCode(String code);
    Optional<School> findFirstByOrderByIdAsc();
}
