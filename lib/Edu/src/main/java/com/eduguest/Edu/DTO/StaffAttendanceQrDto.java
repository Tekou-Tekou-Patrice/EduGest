package com.eduguest.Edu.DTO;

import java.time.LocalDate;

public record StaffAttendanceQrDto(LocalDate date, String schoolName, String token) {
}
