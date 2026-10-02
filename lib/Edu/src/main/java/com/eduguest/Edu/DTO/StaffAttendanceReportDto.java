package com.eduguest.Edu.DTO;

import java.time.LocalDate;
import java.time.LocalDateTime;

public record StaffAttendanceReportDto(
        Long userId,
        String fullName,
        String role,
        LocalDate date,
        LocalDateTime checkInAt,
        LocalDateTime checkOutAt,
        Long durationMinutes) {
}
