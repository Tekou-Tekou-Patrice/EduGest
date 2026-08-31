package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.Payment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {
    
    @Query("SELECT p FROM Payment p WHERE p.studentId = :studentId")
    List<Payment> findByStudentId(@Param("studentId") String studentId);

    @Query(value = "SELECT SUM(amount) FROM payments", nativeQuery = true)
    Double getTotalRevenue();

    @Query(value = "SELECT * FROM payments WHERE date >= DATE_SUB(NOW(), INTERVAL 1 MONTH)", nativeQuery = true)
    List<Payment> findRecentPayments();
}
