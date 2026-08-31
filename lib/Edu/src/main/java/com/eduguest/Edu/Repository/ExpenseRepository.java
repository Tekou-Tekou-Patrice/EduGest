package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.Expense;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ExpenseRepository extends JpaRepository<Expense, Long> {

    @Query("SELECT e FROM Expense e ORDER BY e.date DESC")
    List<Expense> findAllOrdered();

    @Query(value = "SELECT COALESCE(SUM(amount), 0) FROM expenses", nativeQuery = true)
    Double getTotalExpenses();
}
