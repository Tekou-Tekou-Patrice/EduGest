package com.eduguest.Edu.DTO;

import com.eduguest.Edu.Entity.UserRole;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SchoolDto {
    private Long id;
    private String name;
    private String code;
    private boolean active;
    private LocalDateTime createdAt;
    private UserRole membershipRole;

    private String subscriptionStatus;
    private LocalDate subscriptionExpiresAt;
    private Double monthlyFee;
    private String planName;
    private String founderName;
    private String founderPhone;
    private String founderEmail;

    private Long studentCount;
    private Long teacherCount;
    private Long classroomCount;

    public SchoolDto(Long id, String name, String code, boolean active, LocalDateTime createdAt, UserRole membershipRole) {
        this.id = id;
        this.name = name;
        this.code = code;
        this.active = active;
        this.createdAt = createdAt;
        this.membershipRole = membershipRole;
        this.subscriptionStatus = active ? "ACTIVE" : "SUSPENDED";
        this.subscriptionExpiresAt = LocalDate.now().plusMonths(1);
        this.monthlyFee = 25000.0;
        this.planName = "Mensuel Standard";
        this.founderName = "Non renseigné";
        this.founderPhone = "";
        this.founderEmail = "";
        this.studentCount = 0L;
        this.teacherCount = 0L;
        this.classroomCount = 0L;
    }
}
