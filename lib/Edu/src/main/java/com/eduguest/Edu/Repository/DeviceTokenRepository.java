package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.DeviceToken;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface DeviceTokenRepository extends JpaRepository<DeviceToken, Long> {
    Optional<DeviceToken> findByToken(String token);
    List<DeviceToken> findByUserId(Long userId);

    void deleteByUserId(Long userId);
}
