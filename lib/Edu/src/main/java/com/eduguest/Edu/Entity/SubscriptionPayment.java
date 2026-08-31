package com.eduguest.Edu.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "subscription_payments")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SubscriptionPayment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "school_id", nullable = false)
    private Long schoolId;

    @Column(name = "school_name", nullable = false, length = 160)
    private String schoolName;

    @Column(nullable = false)
    private Double amount;

    @Column(name = "payment_method", length = 50)
    private String paymentMethod; // MTN Mobile Money, Orange Money, Espèces, Virement

    @Column(name = "transaction_ref", length = 100)
    private String transactionRef;

    @Column(name = "months_added")
    private Integer monthsAdded = 1;

    @Column(name = "plan_name", length = 60)
    private String planName;

    @Column(name = "paid_at")
    private LocalDateTime paidAt;

    @Column(name = "expires_at_after")
    private LocalDate expiresAtAfter;

    @Column(name = "payer_name", length = 120)
    private String payerName;

    @Column(name = "payer_phone", length = 30)
    private String payerPhone;

    @Column(name = "notes", length = 300)
    private String notes;

    @PrePersist
    protected void onCreate() {
        if (paidAt == null) {
            paidAt = LocalDateTime.now();
        }
    }
}
