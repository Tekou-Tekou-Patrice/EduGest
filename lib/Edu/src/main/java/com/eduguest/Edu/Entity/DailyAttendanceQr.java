package com.eduguest.Edu.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "daily_attendance_qr",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_daily_attendance_qr_school_date",
                columnNames = {"school_id", "attendance_date"}))
@Data
@NoArgsConstructor
public class DailyAttendanceQr implements SchoolScoped {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "school_id", nullable = false)
    private School school;

    @Column(name = "attendance_date", nullable = false)
    private LocalDate attendanceDate;

    @Column(name = "token_hash", nullable = false, length = 64)
    private String tokenHash;

    @Column(name = "generated_at", nullable = false)
    private LocalDateTime generatedAt;
}
