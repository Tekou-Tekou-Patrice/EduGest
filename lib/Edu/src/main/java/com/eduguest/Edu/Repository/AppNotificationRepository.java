package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.AppNotification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AppNotificationRepository extends JpaRepository<AppNotification, Long> {
    
    @Query("SELECT n FROM AppNotification n WHERE n.read = false ORDER BY n.timestamp DESC")
    List<AppNotification> findUnreadOrderByTimestampDesc();

    @Query("SELECT n FROM AppNotification n WHERE n.read = false")
    List<AppNotification> findByReadFalse();

    @Query("""
        SELECT n FROM AppNotification n
        WHERE n.read = false
          AND (n.recipient.id = :userId OR n.recipient IS NULL)
        ORDER BY n.timestamp DESC
        """)
    List<AppNotification> findUnreadForUser(@Param("userId") Long userId);

    List<AppNotification> findByRecipientIdAndReadFalseOrderByTimestampDesc(Long recipientId);

    boolean existsBySchool_IdAndRecipient_IdAndTypeAndMessageContaining(
            Long schoolId, Long recipientId, String type, String messagePart);

    @Query(value = "SELECT * FROM notifications WHERE type = :type ORDER BY timestamp DESC LIMIT 10", nativeQuery = true)
    List<AppNotification> findRecentByType(@Param("type") String type);
}
