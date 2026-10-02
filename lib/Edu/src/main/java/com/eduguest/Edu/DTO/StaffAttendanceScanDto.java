package com.eduguest.Edu.DTO;

import java.time.LocalDateTime;

public record StaffAttendanceScanDto(
        String action,
        LocalDateTime checkInAt,
        LocalDateTime checkOutAt,
        Long durationMinutes,
        Long monthlyTotalMinutes) {
}
