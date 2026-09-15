package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.VerificationCode;
import com.eduguest.Edu.Entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.List;

public interface VerificationCodeRepository extends JpaRepository<VerificationCode, Long> {
    Optional<VerificationCode> findTopByUserAndPurposeAndUsedFalseOrderByIdDesc(User user, String purpose);
    List<VerificationCode> findByUserId(Long userId);
}
