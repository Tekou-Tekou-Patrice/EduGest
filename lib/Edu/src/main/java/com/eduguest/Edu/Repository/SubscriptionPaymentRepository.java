package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.SubscriptionPayment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SubscriptionPaymentRepository extends JpaRepository<SubscriptionPayment, Long> {
    List<SubscriptionPayment> findBySchoolIdOrderByPaidAtDesc(Long schoolId);
    List<SubscriptionPayment> findAllByOrderByPaidAtDesc();

    @Query(value = "SELECT COALESCE(SUM(amount), 0) FROM subscription_payments", nativeQuery = true)
    Double getTotalSubscriptionRevenue();
}
