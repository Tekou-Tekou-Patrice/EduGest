package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.DailyAttendanceQr;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.Optional;

public interface DailyAttendanceQrRepository extends JpaRepository<DailyAttendanceQr, Long> {
    Optional<DailyAttendanceQr> findBySchoolIdAndAttendanceDate(Long schoolId, LocalDate attendanceDate);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT q FROM DailyAttendanceQr q WHERE q.school.id = :schoolId "
            + "AND q.attendanceDate = :attendanceDate AND q.tokenHash = :tokenHash")
    Optional<DailyAttendanceQr> findForUpdate(
            @Param("schoolId") Long schoolId,
            @Param("attendanceDate") LocalDate attendanceDate,
            @Param("tokenHash") String tokenHash);
}
