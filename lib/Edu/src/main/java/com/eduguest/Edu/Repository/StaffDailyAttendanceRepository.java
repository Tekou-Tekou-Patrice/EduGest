package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.StaffDailyAttendance;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface StaffDailyAttendanceRepository extends JpaRepository<StaffDailyAttendance, Long> {
    Optional<StaffDailyAttendance> findBySchoolIdAndUserIdAndAttendanceDate(
            Long schoolId, Long userId, LocalDate attendanceDate);

    List<StaffDailyAttendance> findBySchoolIdAndAttendanceDateGreaterThanEqualAndAttendanceDateLessThanOrderByAttendanceDateDescCheckInAtDesc(
            Long schoolId, LocalDate start, LocalDate end);

    List<StaffDailyAttendance> findBySchoolIdAndUserIdAndAttendanceDateGreaterThanEqualAndAttendanceDateLessThan(
            Long schoolId, Long userId, LocalDate start, LocalDate end);
}
