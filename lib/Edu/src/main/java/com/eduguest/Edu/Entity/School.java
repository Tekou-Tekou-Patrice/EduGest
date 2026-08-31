package com.eduguest.Edu.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "schools")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class School {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 160)
    private String name;

    @Column(unique = true, length = 80)
    private String code;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "subscription_status", length = 30)
    private String subscriptionStatus = "ACTIVE";

    @Column(name = "subscription_expires_at")
    private java.time.LocalDate subscriptionExpiresAt;

    @Column(name = "monthly_fee")
    private Double monthlyFee = 25000.0;

    @Column(name = "plan_name", length = 60)
    private String planName = "Mensuel Standard";

    @Column(name = "founder_name", length = 120)
    private String founderName;

    @Column(name = "founder_phone", length = 30)
    private String founderPhone;

    @Column(name = "founder_email", length = 150)
    private String founderEmail;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (subscriptionExpiresAt == null) {
            subscriptionExpiresAt = java.time.LocalDate.now().plusMonths(1);
        }
        if (subscriptionStatus == null) {
            subscriptionStatus = "ACTIVE";
        }
    }
}
