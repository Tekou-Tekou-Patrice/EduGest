package com.eduguest.Edu.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "saas_settings")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SaasSetting {

    @Id
    private Long id = 1L;

    @Column(name = "mtn_number", length = 40)
    private String mtnNumber = "+237 670 00 00 00";

    @Column(name = "mtn_name", length = 120)
    private String mtnName = "Patrick - Admin EduGest";

    @Column(name = "orange_number", length = 40)
    private String orangeNumber = "+237 690 00 00 00";

    @Column(name = "orange_name", length = 120)
    private String orangeName = "Patrick - Admin EduGest";

    @Column(name = "pricing_monthly")
    private Double pricingMonthly = 25000.0;

    @Column(name = "pricing_quarterly")
    private Double pricingQuarterly = 65000.0;

    @Column(name = "pricing_yearly")
    private Double pricingYearly = 220000.0;

    @Column(name = "promo_active")
    private boolean promoActive = true;

    @Column(name = "promo_code", length = 50)
    private String promoCode = "RENTREE2026";

    @Column(name = "promo_discount_percent")
    private Double promoDiscountPercent = 20.0;

    @Column(name = "promo_description", length = 300)
    private String promoDescription = "Offre Spéciale Rentrée : -20% de réduction sur l'abonnement annuel EduGest !";

    @Column(name = "payment_instructions", length = 500)
    private String paymentInstructions = "Effectuez votre transfert MTN ou Orange Money avec le nom/code de votre établissement en motif.";

    @Column(name = "support_phone", length = 40)
    private String supportPhone = "+237 600 00 00 00";

    @Column(name = "support_email", length = 120)
    private String supportEmail = "contact@eduguest.com";

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    @PreUpdate
    protected void onSave() {
        updatedAt = LocalDateTime.now();
    }
}
