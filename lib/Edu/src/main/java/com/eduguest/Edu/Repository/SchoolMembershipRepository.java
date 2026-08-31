package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.SchoolMembership;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SchoolMembershipRepository extends JpaRepository<SchoolMembership, Long> {
    List<SchoolMembership> findByUserIdAndActiveTrueOrderBySchool_Name(Long userId);
    Optional<SchoolMembership> findByUserIdAndSchoolId(Long userId, Long schoolId);
    boolean existsByUserIdAndSchoolId(Long userId, Long schoolId);
    List<SchoolMembership> findBySchoolIdAndActiveTrueOrderByUser_FullName(Long schoolId);
    void deleteBySchoolId(Long schoolId);
}
