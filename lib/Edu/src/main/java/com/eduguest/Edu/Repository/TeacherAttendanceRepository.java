package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.TeacherAttendance;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.Optional;

public interface TeacherAttendanceRepository extends JpaRepository<TeacherAttendance, Long> {
    Optional<TeacherAttendance> findByTeacherIdAndAttendanceDate(Long teacherId, LocalDate attendanceDate);
}
